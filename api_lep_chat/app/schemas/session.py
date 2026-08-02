from datetime import datetime

from pydantic import BaseModel, Field


class SessionCreate(BaseModel):
    title: str = Field(default="New conversation", min_length=1, max_length=200)


class SessionUpdate(BaseModel):
    title: str = Field(min_length=1, max_length=200)


class SessionOut(BaseModel):
    id: str
    user_id: str
    title: str
    created_at: datetime | None = None
    updated_at: datetime | None = None
