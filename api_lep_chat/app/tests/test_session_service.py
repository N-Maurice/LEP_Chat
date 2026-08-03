import pytest
from fastapi import HTTPException

from app.schemas.session import SessionCreate, SessionUpdate
from app.services.session_service import SessionService
from app.tests.conftest import FakeMessageRepository, FakeSessionRepository


@pytest.fixture
def service() -> SessionService:
    return SessionService(FakeSessionRepository(), FakeMessageRepository())


async def test_create_session_stores_owner(service, current_user):
    session = await service.create_session(current_user, SessionCreate(title="Land dispute"))
    assert session["user_id"] == current_user.uid
    assert session["title"] == "Land dispute"


async def test_get_owned_session_raises_404_when_missing(service, current_user):
    with pytest.raises(HTTPException) as exc_info:
        await service.get_owned_session(current_user, "does-not-exist")
    assert exc_info.value.status_code == 404


async def test_get_owned_session_raises_403_for_other_users_session(service, current_user):
    session = await service.create_session(current_user, SessionCreate(title="Mine"))
    other_user_uid = "someone-else"

    class Other:
        uid = other_user_uid

    with pytest.raises(HTTPException) as exc_info:
        await service.get_owned_session(Other(), session["id"])
    assert exc_info.value.status_code == 403


async def test_rename_session_updates_title(service, current_user):
    session = await service.create_session(current_user, SessionCreate(title="Old title"))
    updated = await service.rename_session(current_user, session["id"], SessionUpdate(title="New title"))
    assert updated["title"] == "New title"


async def test_delete_session_cascades_to_messages(service, current_user):
    session = await service.create_session(current_user, SessionCreate(title="To delete"))
    await service._messages.create(session["id"], role="user", content="hello")
    assert await service._messages.list(session["id"])

    await service.delete_session(current_user, session["id"])

    assert await service._sessions.get(session["id"]) is None
    assert await service._messages.list(session["id"]) == []
