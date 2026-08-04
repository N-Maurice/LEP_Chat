"""Business logic for direct messages between citizens: starting/reusing a
conversation, listing threads with the other participant's public info attached,
and sending/reading messages within a conversation the caller is part of."""

from fastapi import Depends, HTTPException, status

from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.conversation_repository import ConversationRepository
from app.db.repositories.user_repository import UserRepository
from app.schemas.conversation import ConversationCreate, DirectMessageCreate
from app.schemas.user import CurrentUser


class ConversationService:
    def __init__(self, conversations: ConversationRepository, users: UserRepository):
        self._conversations = conversations
        self._users = users

    async def start_or_get_conversation(self, user: CurrentUser, payload: ConversationCreate) -> dict:
        if payload.recipient_uid == user.uid:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "You cannot start a conversation with yourself")

        recipient = await self._users.get(payload.recipient_uid)
        if recipient is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "That user could not be found")

        existing = await self._conversations.find_between(user.uid, payload.recipient_uid)
        conversation = existing or await self._conversations.create(user.uid, payload.recipient_uid)
        return await self._with_other_participant(conversation, user.uid)

    async def list_conversations(self, user: CurrentUser) -> list[dict]:
        conversations = await self._conversations.list_for_user(user.uid)
        return [await self._with_other_participant(c, user.uid) for c in conversations]

    async def get_owned_conversation(self, user: CurrentUser, conversation_id: str) -> dict:
        conversation = await self._conversations.get(conversation_id)
        if conversation is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Conversation not found")
        if user.uid not in conversation["participant_uids"]:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You are not part of this conversation")
        return conversation

    async def list_messages(self, user: CurrentUser, conversation_id: str) -> list[dict]:
        await self.get_owned_conversation(user, conversation_id)
        return await self._conversations.list_messages(conversation_id)

    async def send_message(self, user: CurrentUser, conversation_id: str, payload: DirectMessageCreate) -> dict:
        await self.get_owned_conversation(user, conversation_id)
        return await self._conversations.add_message(conversation_id, user.uid, payload.content)

    async def _with_other_participant(self, conversation: dict, uid: str) -> dict:
        other_uid = next((p for p in conversation["participant_uids"] if p != uid), None)
        other = await self._users.get(other_uid) if other_uid else None
        return {**conversation, "other_participant": other}


def get_conversation_service(settings: Settings = Depends(get_settings)) -> ConversationService:
    client = get_firestore_client()
    conversations = ConversationRepository(client, settings.firestore_conversations_collection)
    users = UserRepository(client, settings.firestore_users_collection)
    return ConversationService(conversations, users)
