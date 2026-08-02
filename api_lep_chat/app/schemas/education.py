from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.message import Citation


class TrackOut(BaseModel):
    slug: str
    label: str


class CourseModuleOut(BaseModel):
    title: str
    summary: str
    citations: list[Citation] = Field(default_factory=list)


class CourseOut(BaseModel):
    track: str
    title: str
    description: str
    modules: list[CourseModuleOut] = Field(default_factory=list)
    generated_at: datetime | None = None
