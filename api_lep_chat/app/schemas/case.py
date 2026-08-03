from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class CaseType(str, Enum):
    case = "case"
    violation_report = "violation_report"


class CaseStatus(str, Enum):
    submitted = "submitted"
    under_review = "under_review"
    in_progress = "in_progress"
    resolved = "resolved"
    closed = "closed"


class CaseCreate(BaseModel):
    case_type: CaseType = CaseType.case
    title: str = Field(min_length=1, max_length=200)
    category: str = Field(min_length=1, max_length=100)
    description: str = Field(default="", max_length=4000)
    location: str | None = Field(default=None, max_length=200)


class EvidenceOut(BaseModel):
    filename: str
    gcs_path: str
    content_type: str | None = None
    uploaded_at: datetime | None = None


class CaseOut(BaseModel):
    id: str
    user_id: str
    ref: str
    case_type: CaseType
    title: str
    category: str
    description: str
    location: str | None = None
    status: CaseStatus
    evidence: list[EvidenceOut] = Field(default_factory=list)
    created_at: datetime | None = None
    updated_at: datetime | None = None
