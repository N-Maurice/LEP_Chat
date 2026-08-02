import pytest
from fastapi import HTTPException

from app.schemas.message import MessageCreate, MessageUpdate
from app.schemas.session import SessionCreate
from app.services.message_service import MessageService
from app.services.session_service import SessionService
from app.tests.conftest import FakeAgent, FakeMessageRepository, FakeSessionRepository


@pytest.fixture
def wiring(current_user):
    session_repo = FakeSessionRepository()
    message_repo = FakeMessageRepository()
    session_service = SessionService(session_repo, message_repo)
    agent = FakeAgent()
    message_service = MessageService(message_repo, session_service, agent)
    return session_service, message_service, agent


async def _create_session(session_service, current_user):
    return await session_service.create_session(current_user, SessionCreate(title="Thread"))


async def test_send_message_persists_both_turns_and_calls_agent(wiring, current_user):
    session_service, message_service, agent = wiring
    session = await _create_session(session_service, current_user)

    user_msg, assistant_msg = await message_service.send_message(
        current_user, session["id"], MessageCreate(content="What is VAT in Rwanda?")
    )

    assert user_msg["role"] == "user"
    assert user_msg["content"] == "What is VAT in Rwanda?"
    assert assistant_msg["role"] == "assistant"
    assert "Answer to: What is VAT in Rwanda?" in assistant_msg["content"]
    assert assistant_msg["citations"][0]["source"] == "fake_law.pdf"
    assert agent.calls == ["What is VAT in Rwanda?"]


async def test_send_message_rejects_unowned_session(wiring, current_user):
    session_service, message_service, _ = wiring
    session = await _create_session(session_service, current_user)

    class Other:
        uid = "someone-else"

    with pytest.raises(HTTPException) as exc_info:
        await message_service.send_message(Other(), session["id"], MessageCreate(content="hi"))
    assert exc_info.value.status_code == 403


async def test_update_message_allows_editing_user_message(wiring, current_user):
    session_service, message_service, _ = wiring
    session = await _create_session(session_service, current_user)
    user_msg, _ = await message_service.send_message(current_user, session["id"], MessageCreate(content="v1"))

    updated = await message_service.update_message(
        current_user, session["id"], user_msg["id"], MessageUpdate(content="v2")
    )
    assert updated["content"] == "v2"


async def test_update_message_rejects_editing_assistant_message(wiring, current_user):
    session_service, message_service, _ = wiring
    session = await _create_session(session_service, current_user)
    _, assistant_msg = await message_service.send_message(current_user, session["id"], MessageCreate(content="v1"))

    with pytest.raises(HTTPException) as exc_info:
        await message_service.update_message(
            current_user, session["id"], assistant_msg["id"], MessageUpdate(content="edited")
        )
    assert exc_info.value.status_code == 400


async def test_delete_message_removes_only_that_message(wiring, current_user):
    session_service, message_service, _ = wiring
    session = await _create_session(session_service, current_user)
    user_msg, assistant_msg = await message_service.send_message(
        current_user, session["id"], MessageCreate(content="v1")
    )

    await message_service.delete_message(current_user, session["id"], user_msg["id"])

    remaining = await message_service.list_messages(current_user, session["id"])
    assert [m["id"] for m in remaining] == [assistant_msg["id"]]


async def test_get_message_raises_404_when_missing(wiring, current_user):
    session_service, message_service, _ = wiring
    session = await _create_session(session_service, current_user)

    with pytest.raises(HTTPException) as exc_info:
        await message_service.get_message(current_user, session["id"], "no-such-message")
    assert exc_info.value.status_code == 404
