from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class MessageRole(str, Enum):
    user = "user"
    assistant = "assistant"


class Citation(BaseModel):
    source: str
    law_number: str | None = None
    law_year: str | None = None
    gcs_path: str | None = None
    domain: str | None = None


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class MessageUpdate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class MessageOut(BaseModel):
    id: str
    session_id: str
    role: MessageRole
    content: str
    citations: list[Citation] = Field(default_factory=list)
    created_at: datetime | None = None
    updated_at: datetime | None = None


class ChatExchangeOut(BaseModel):
    """What POSTing a new user message returns: the stored user message plus the
    assistant's generated reply, so a chat client can render both in one round trip."""

    user_message: MessageOut
    assistant_message: MessageOut
