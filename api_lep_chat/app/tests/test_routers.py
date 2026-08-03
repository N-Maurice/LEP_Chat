import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.case_service import CaseService, get_case_service
from app.services.conversation_service import ConversationService, get_conversation_service
from app.services.course_service import CourseService, get_course_service
from app.services.message_service import MessageService, get_message_service
from app.services.research_service import ResearchService, get_research_service
from app.services.session_service import SessionService, get_session_service
from app.services.user_service import UserProfileService, get_user_profile_service
from app.tests.conftest import (
    FakeAgent,
    FakeCaseRepository,
    FakeConversationRepository,
    FakeCourseAgent,
    FakeCourseRepository,
    FakeMessageRepository,
    FakeSessionRepository,
    FakeUserRepository,
    _fake_upload_bytes,
)


async def _fake_sign_url(bucket: str, gcs_path: str) -> str:
    return f"https://storage.example.com/{bucket}/{gcs_path}?signed=1"

USER_ONE = CurrentUser(uid="user-1", email="one@example.com")
USER_TWO = CurrentUser(uid="user-2", email="two@example.com")


@pytest.fixture
def client():
    session_repo = FakeSessionRepository()
    message_repo = FakeMessageRepository()
    session_service = SessionService(session_repo, message_repo)
    message_service = MessageService(message_repo, session_service, FakeAgent())
    shared_user_repo = FakeUserRepository()
    user_service = UserProfileService(shared_user_repo)
    course_service = CourseService(FakeCourseRepository(), FakeCourseAgent())
    research_service = ResearchService(FakeAgent(), "fake-bucket", sign_url=_fake_sign_url)
    case_service = CaseService(FakeCaseRepository(), "fake-evidence-bucket", upload_fn=_fake_upload_bytes)
    conversation_service = ConversationService(FakeConversationRepository(), shared_user_repo)

    app.dependency_overrides[get_current_user] = lambda: USER_ONE
    app.dependency_overrides[get_session_service] = lambda: session_service
    app.dependency_overrides[get_message_service] = lambda: message_service
    app.dependency_overrides[get_user_profile_service] = lambda: user_service
    app.dependency_overrides[get_course_service] = lambda: course_service
    app.dependency_overrides[get_research_service] = lambda: research_service
    app.dependency_overrides[get_case_service] = lambda: case_service
    app.dependency_overrides[get_conversation_service] = lambda: conversation_service

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


def test_research_search_returns_grounded_results(client):
    response = client.get("/api/v1/research/search", params={"q": "employment dismissal"})
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["tag"] == "Labour Law"
    assert body[0]["title"] == "labour law n 49 of 2023"
    assert body[0]["gcs_path"].endswith("labour_law_n_49_of_2023.pdf")


def test_research_document_url_is_signed(client):
    response = client.get(
        "/api/v1/research/documents/url",
        params={"gcs_path": "Domestic laws/Laws in force/1. Fundamental/labour_law_n_49_of_2023.pdf"},
    )
    assert response.status_code == 200
    assert response.json()["url"].startswith("https://storage.example.com/fake-bucket/")


def test_create_and_list_cases(client):
    create_resp = client.post(
        "/api/v1/cases",
        json={"title": "Unpaid overtime", "category": "Labour", "description": "My employer refuses to pay overtime."},
    )
    assert create_resp.status_code == 201
    case = create_resp.json()
    assert case["status"] == "submitted"
    assert case["case_type"] == "case"
    assert case["ref"].startswith("LEP-")

    list_resp = client.get("/api/v1/cases")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1


def test_create_violation_report_defaults_case_type(client):
    response = client.post(
        "/api/v1/cases",
        json={
            "case_type": "violation_report",
            "title": "Bribery at district office",
            "category": "Corruption",
            "description": "Details of the incident.",
        },
    )
    assert response.status_code == 201
    assert response.json()["case_type"] == "violation_report"


def test_upload_evidence_attaches_file_to_case(client):
    case_id = client.post(
        "/api/v1/cases", json={"title": "Land dispute", "category": "Land", "description": "Boundary dispute."}
    ).json()["id"]

    response = client.post(
        f"/api/v1/cases/{case_id}/evidence",
        files={"file": ("photo.jpg", b"fake-image-bytes", "image/jpeg")},
    )
    assert response.status_code == 201
    body = response.json()
    assert len(body["evidence"]) == 1
    assert body["evidence"][0]["filename"] == "photo.jpg"
    assert body["evidence"][0]["gcs_path"].endswith("photo.jpg")


def test_case_owned_by_another_user_is_forbidden(client):
    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    other_case_id = client.post(
        "/api/v1/cases", json={"title": "Not yours", "category": "Other", "description": "..."}
    ).json()["id"]

    app.dependency_overrides[get_current_user] = lambda: USER_ONE
    response = client.get(f"/api/v1/cases/{other_case_id}")
    assert response.status_code == 403


def test_unknown_case_is_not_found(client):
    response = client.get("/api/v1/cases/does-not-exist")
    assert response.status_code == 404


def test_search_users_by_username_prefix(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})

    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    client.post("/api/v1/users/me", json={"full_name": "Marie", "username": "marie123"})

    response = client.get("/api/v1/users/search", params={"q": "jean"})
    assert response.status_code == 200
    results = response.json()
    assert len(results) == 1
    assert results[0]["username"] == "jeanluc"


def test_search_users_excludes_self(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})

    response = client.get("/api/v1/users/search", params={"q": "jean"})
    assert response.json() == []


def test_start_conversation_and_send_messages(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})
    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    client.post("/api/v1/users/me", json={"full_name": "Marie", "username": "marie123"})

    conversation = client.post("/api/v1/conversations", json={"recipient_uid": USER_ONE.uid}).json()
    assert conversation["other_participant"]["username"] == "jeanluc"

    send_resp = client.post(f"/api/v1/conversations/{conversation['id']}/messages", json={"content": "Hi Jean-Luc"})
    assert send_resp.status_code == 201
    assert send_resp.json()["sender_id"] == USER_TWO.uid

    app.dependency_overrides[get_current_user] = lambda: USER_ONE
    messages = client.get(f"/api/v1/conversations/{conversation['id']}/messages").json()
    assert len(messages) == 1
    assert messages[0]["content"] == "Hi Jean-Luc"


def test_starting_conversation_twice_reuses_the_same_thread(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})
    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    client.post("/api/v1/users/me", json={"full_name": "Marie", "username": "marie123"})
    app.dependency_overrides[get_current_user] = lambda: USER_ONE

    first = client.post("/api/v1/conversations", json={"recipient_uid": USER_TWO.uid})
    second = client.post("/api/v1/conversations", json={"recipient_uid": USER_TWO.uid})
    assert first.json()["id"] == second.json()["id"]


def test_cannot_message_a_conversation_you_are_not_part_of(client):
    client.post("/api/v1/users/me", json={"full_name": "Jean-Luc", "username": "jeanluc"})
    app.dependency_overrides[get_current_user] = lambda: USER_TWO
    client.post("/api/v1/users/me", json={"full_name": "Marie", "username": "marie123"})
    app.dependency_overrides[get_current_user] = lambda: USER_ONE

    conversation_id = client.post("/api/v1/conversations", json={"recipient_uid": USER_TWO.uid}).json()["id"]

    app.dependency_overrides[get_current_user] = lambda: CurrentUser(uid="user-3", email="three@example.com")
    response = client.post(f"/api/v1/conversations/{conversation_id}/messages", json={"content": "hi"})
    assert response.status_code == 403
