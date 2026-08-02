"""Business logic for messages within a session: ownership enforcement (via SessionService),
edit rules, and driving the RAG agent to produce the assistant's reply."""

from fastapi import Depends, HTTPException, status

from app.agents.legal_research_agent import LegalResearchAgent, get_legal_research_agent
from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.message_repository import MessageRepository
from app.schemas.message import MessageCreate, MessageUpdate
from app.schemas.user import CurrentUser
from app.services.session_service import SessionService, get_session_service


class MessageService:
    def __init__(self, message_repo: MessageRepository, session_service: SessionService, agent: LegalResearchAgent):
        self._messages = message_repo
        self._sessions = session_service
        self._agent = agent

    async def send_message(self, user: CurrentUser, session_id: str, payload: MessageCreate) -> tuple[dict, dict]:
        await self._sessions.get_owned_session(user, session_id)

        user_message = await self._messages.create(session_id, role="user", content=payload.content)

        agent_answer = await self._agent.answer(payload.content)
        assistant_message = await self._messages.create(
            session_id,
            role="assistant",
            content=agent_answer.content,
            citations=agent_answer.citations,
        )

        await self._sessions.touch_session(session_id)
        return user_message, assistant_message

    async def list_messages(self, user: CurrentUser, session_id: str) -> list[dict]:
        await self._sessions.get_owned_session(user, session_id)
        return await self._messages.list(session_id)

    async def get_message(self, user: CurrentUser, session_id: str, message_id: str) -> dict:
        await self._sessions.get_owned_session(user, session_id)
        message = await self._messages.get(session_id, message_id)
        if message is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
        return message

    async def update_message(
        self, user: CurrentUser, session_id: str, message_id: str, payload: MessageUpdate
    ) -> dict:
        message = await self.get_message(user, session_id, message_id)
        if message["role"] != "user":
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Only user messages can be edited")
        return await self._messages.update(session_id, message_id, payload.content)

    async def delete_message(self, user: CurrentUser, session_id: str, message_id: str) -> None:
        await self.get_message(user, session_id, message_id)
        await self._messages.delete(session_id, message_id)


def get_message_service(
    settings: Settings = Depends(get_settings),
    session_service: SessionService = Depends(get_session_service),
    agent: LegalResearchAgent = Depends(get_legal_research_agent),
) -> MessageService:
    client = get_firestore_client()
    message_repo = MessageRepository(
        client, settings.firestore_sessions_collection, settings.firestore_messages_subcollection
    )
    return MessageService(message_repo, session_service, agent)
