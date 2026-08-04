from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.user import PublicUserOut


class ConversationCreate(BaseModel):
    recipient_uid: str


class ConversationOut(BaseModel):
    id: str
    participant_uids: list[str]
    other_participant: PublicUserOut | None = None
    last_message: str | None = None
    updated_at: datetime | None = None
    created_at: datetime | None = None


class DirectMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class DirectMessageOut(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    created_at: datetime | None = None
