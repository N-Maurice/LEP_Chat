"""Business logic for chat session threads: ownership enforcement and cascade deletes
live here, on top of the plain-CRUD SessionRepository/MessageRepository."""

from fastapi import Depends, HTTPException, status

from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.message_repository import MessageRepository
from app.db.repositories.session_repository import SessionRepository
from app.schemas.session import SessionCreate, SessionUpdate
from app.schemas.user import CurrentUser


class SessionService:
    def __init__(self, session_repo: SessionRepository, message_repo: MessageRepository):
        self._sessions = session_repo
        self._messages = message_repo

    async def create_session(self, user: CurrentUser, payload: SessionCreate) -> dict:
        return await self._sessions.create(user_id=user.uid, title=payload.title)

    async def list_sessions(self, user: CurrentUser) -> list[dict]:
        return await self._sessions.list_by_user(user.uid)

    async def get_owned_session(self, user: CurrentUser, session_id: str) -> dict:
        session = await self._sessions.get(session_id)
        if session is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")
        if session["user_id"] != user.uid:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You do not have access to this session")
        return session

    async def rename_session(self, user: CurrentUser, session_id: str, payload: SessionUpdate) -> dict:
        await self.get_owned_session(user, session_id)
        return await self._sessions.update(session_id, title=payload.title)

    async def touch_session(self, session_id: str) -> None:
        await self._sessions.touch(session_id)

    async def delete_session(self, user: CurrentUser, session_id: str) -> None:
        await self.get_owned_session(user, session_id)
        await self._messages.delete_all(session_id)
        await self._sessions.delete(session_id)


def get_session_service(settings: Settings = Depends(get_settings)) -> SessionService:
    client = get_firestore_client()
    session_repo = SessionRepository(client, settings.firestore_sessions_collection)
    message_repo = MessageRepository(
        client, settings.firestore_sessions_collection, settings.firestore_messages_subcollection
    )
    return SessionService(session_repo, message_repo)
