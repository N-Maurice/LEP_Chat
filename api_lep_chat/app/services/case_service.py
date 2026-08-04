"""Business logic for case/report submission, evidence upload, and status tracking.
Report a Violation and Track a Case are the same underlying feature — they differ only
in `case_type` — so a citizen sees both in one list and one set of endpoints."""

from typing import Awaitable, Callable

from fastapi import Depends, HTTPException, UploadFile, status

from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.case_repository import CaseRepository
from app.db.storage_client import upload_bytes
from app.schemas.case import CaseCreate
from app.schemas.user import CurrentUser

MAX_EVIDENCE_BYTES = 20 * 1024 * 1024  # 20 MB per file

UploadFn = Callable[[str, str, str, bytes, str | None], Awaitable[str]]


class CaseService:
    def __init__(self, repo: CaseRepository, evidence_bucket: str, upload_fn: UploadFn = upload_bytes):
        self._repo = repo
        self._evidence_bucket = evidence_bucket
        self._upload_fn = upload_fn

    async def create_case(self, user: CurrentUser, payload: CaseCreate) -> dict:
        return await self._repo.create(
            user.uid,
            case_type=payload.case_type.value,
            title=payload.title,
            category=payload.category,
            description=payload.description,
            location=payload.location,
        )

    async def list_cases(self, user: CurrentUser) -> list[dict]:
        return await self._repo.list_by_user(user.uid)

    async def get_owned_case(self, user: CurrentUser, case_id: str) -> dict:
        case = await self._repo.get(case_id)
        if case is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Case not found")
        if case["user_id"] != user.uid:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You do not have access to this case")
        return case

    async def add_evidence(self, user: CurrentUser, case_id: str, file: UploadFile) -> dict:
        await self.get_owned_case(user, case_id)

        content = await file.read()
        if len(content) > MAX_EVIDENCE_BYTES:
            raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "File exceeds the 20MB limit")

        blob_path = await self._upload_fn(
            self._evidence_bucket, f"case_evidence/{case_id}", file.filename or "evidence", content, file.content_type
        )
        evidence_item = {
            "filename": file.filename or "evidence",
            "gcs_path": blob_path,
            "content_type": file.content_type,
            "uploaded_at": None,
        }
        return await self._repo.add_evidence(case_id, evidence_item)


def get_case_service(settings: Settings = Depends(get_settings)) -> CaseService:
    client = get_firestore_client()
    repo = CaseRepository(client, settings.firestore_cases_collection)
    return CaseService(repo, settings.gcs_evidence_bucket)
