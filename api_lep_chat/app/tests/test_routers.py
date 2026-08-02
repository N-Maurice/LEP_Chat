import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.course_service import CourseService, get_course_service
from app.services.message_service import MessageService, get_message_service
from app.services.session_service import SessionService, get_session_service
from app.services.user_service import UserProfileService, get_user_profile_service
from app.tests.conftest import (
    FakeAgent,
    FakeCourseAgent,
    FakeCourseRepository,
    FakeMessageRepository,
    FakeSessionRepository,
    FakeUserRepository,
)

USER_ONE = CurrentUser(uid="user-1", email="one@example.com")
USER_TWO = CurrentUser(uid="user-2", email="two@example.com")


@pytest.fixture
def client():
    session_repo = FakeSessionRepository()
    message_repo = FakeMessageRepository()
    session_service = SessionService(session_repo, message_repo)
    message_service = MessageService(message_repo, session_service, FakeAgent())
    user_service = UserProfileService(FakeUserRepository())
    course_service = CourseService(FakeCourseRepository(), FakeCourseAgent())

    app.dependency_overrides[get_current_user] = lambda: USER_ONE
    app.dependency_overrides[get_session_service] = lambda: session_service
    app.dependency_overrides[get_message_service] = lambda: message_service
    app.dependency_overrides[get_user_profile_service] = lambda: user_service
    app.dependency_overrides[get_course_service] = lambda: course_service

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


def test_health_check_is_public(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_and_list_sessions(client):
    create_resp = client.post("/api/v1/sessions", json={"title": "Land dispute"})
    assert create_resp.status_code == 201
    session = create_resp.json()
    assert session["title"] == "Land dispute"
    assert session["user_id"] == USER_ONE.uid

    list_resp = client.get("/api/v1/sessions")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1


def test_send_message_returns_user_and_assistant_turns(client):
    session_id = client.post("/api/v1/sessions", json={"title": "Thread"}).json()["id"]

    response = client.post(
        f"/api/v1/sessions/{session_id}/messages", json={"content": "What is VAT in Rwanda?"}
    )
    assert response.status_code == 201
    body = response.json()
    assert body["user_message"]["role"] == "user"
    assert body["assistant_message"]["role"] == "assistant"
    assert body["assistant_message"]["citations"][0]["source"] == "fake_law.pdf"


def test_update_message_edits_user_question(client):
    session_id = client.post("/api/v1/sessions", json={"title": "Thread"}).json()["id"]
    exchange = client.post(f"/api/v1/sessions/{session_id}/messages", json={"content": "v1"}).json()
    user_message_id = exchange["user_message"]["id"]

    response = client.patch(
        f"/api/v1/sessions/{session_id}/messages/{user_message_id}", json={"content": "v2"}
    )
    assert response.status_code == 200
    assert response.json()["content"] == "v2"


def test_update_message_rejects_editing_assistant_reply(client):
    session_id = client.post("/api/v1/sessions", json={"title": "Thread"}).json()["id"]
    exchange = client.post(f"/api/v1/sessions/{session_id}/messages", json={"content": "v1"}).json()
    assistant_message_id = exchange["assistant_message"]["id"]

    response = client.patch(
        f"/api/v1/sessions/{session_id}/messages/{assistant_message_id}", json={"content": "edited"}
    )
    assert response.status_code == 400


def test_delete_message(client):
    session_id = client.post("/api/v1/sessions", json={"title": "Thread"}).json()["id"]
    exchange = client.post(f"/api/v1/sessions/{session_id}/messages", json={"content": "v1"}).json()
    user_message_id = exchange["user_message"]["id"]

    delete_resp = client.delete(f"/api/v1/sessions/{session_id}/messages/{user_message_id}")
    assert delete_resp.status_code == 204

    remaining = client.get(f"/api/v1/sessions/{session_id}/messages").json()
    assert len(remaining) == 1
    assert remaining[0]["id"] == exchange["assistant_message"]["id"]


def test_delete_session_removes_thread_and_its_messages(client):
    session_id = client.post("/api/v1/sessions", json={"title": "Thread"}).json()["id"]
    client.post(f"/api/v1/sessions/{session_id}/messages", json={"content": "v1"})

    delete_resp = client.delete(f"/api/v1/sessions/{session_id}")
    assert delete_resp.status_code == 204

    assert client.get(f"/api/v1/sessions/{session_id}").status_code == 404


def test_session_owned_by_another_user_is_forbidden(client):
    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    other_session_id = client.post("/api/v1/sessions", json={"title": "Not yours"}).json()["id"]

    app.dependency_overrides[get_current_user] = lambda: USER_ONE
    response = client.get(f"/api/v1/sessions/{other_session_id}")
    assert response.status_code == 403


def test_unknown_session_is_not_found(client):
    response = client.get("/api/v1/sessions/does-not-exist")
    assert response.status_code == 404


def test_auth_required_when_not_overridden():
    app.dependency_overrides.clear()
    with TestClient(app) as unauth_client:
        response = unauth_client.get("/api/v1/sessions")
    assert response.status_code == 401


def test_create_and_read_user_profile(client):
    create_resp = client.post(
        "/api/v1/users/me",
        json={"full_name": "Jean-Luc", "username": "jeanluc", "jurisdiction": "Rwanda"},
    )
    assert create_resp.status_code == 201
    body = create_resp.json()
    assert body["uid"] == USER_ONE.uid
    assert body["full_name"] == "Jean-Luc"

    read_resp = client.get("/api/v1/users/me")
    assert read_resp.status_code == 200
    assert read_resp.json()["username"] == "jeanluc"


def test_read_user_profile_404_before_creation(client):
    response = client.get("/api/v1/users/me")
    assert response.status_code == 404


def test_update_user_profile_partial(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})

    patch_resp = client.patch("/api/v1/users/me", json={"username": "jl"})
    assert patch_resp.status_code == 200
    assert patch_resp.json()["username"] == "jl"
    assert patch_resp.json()["full_name"] == "Jean-Luc"


def test_list_education_tracks(client):
    response = client.get("/api/v1/education/tracks")
    assert response.status_code == 200
    slugs = {t["slug"] for t in response.json()}
    assert slugs == {"labour-law-101", "business-compliance", "family-law", "land-rights"}


def test_get_education_course_returns_five_modules(client):
    response = client.get("/api/v1/education/courses/labour-law-101")
    assert response.status_code == 200
    body = response.json()
    assert body["track"] == "labour-law-101"
    assert len(body["modules"]) == 5


def test_get_education_course_unknown_track_is_not_found(client):
    response = client.get("/api/v1/education/courses/not-a-real-track")
    assert response.status_code == 404
