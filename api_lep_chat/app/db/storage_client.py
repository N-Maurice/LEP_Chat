"""Google Cloud Storage client factory + helpers shared by the research (read the
original source PDF) and cases (evidence upload) features. Signing is done locally
against the service account key already loaded via GOOGLE_APPLICATION_CREDENTIALS,
so no extra IAM role is needed beyond read/write access to the bucket."""

import asyncio
import uuid
from datetime import timedelta
from functools import lru_cache

from google.cloud import storage

from app.core.config import get_settings


@lru_cache
def get_storage_client() -> storage.Client:
    settings = get_settings()
    return storage.Client(project=settings.google_cloud_project)


async def signed_read_url(bucket_name: str, blob_path: str, *, expires_minutes: int = 30) -> str:
    """Generates a time-limited signed URL so the mobile app can read/download a
    private GCS object directly, without proxying the bytes through the API."""

    def _sign() -> str:
        bucket = get_storage_client().bucket(bucket_name)
        blob = bucket.blob(blob_path)
        return blob.generate_signed_url(version="v4", expiration=timedelta(minutes=expires_minutes), method="GET")

    return await asyncio.to_thread(_sign)


async def upload_bytes(bucket_name: str, folder: str, filename: str, content: bytes, content_type: str | None) -> str:
    """Uploads evidence bytes under a UUID-prefixed path so citizen uploads never
    collide, and returns the resulting blob path (stored, not the signed URL —
    signed URLs are generated fresh on read since they expire)."""

    safe_name = filename.replace("/", "_")
    blob_path = f"{folder}/{uuid.uuid4().hex}_{safe_name}"

    def _upload() -> None:
        bucket = get_storage_client().bucket(bucket_name)
        blob = bucket.blob(blob_path)
        blob.upload_from_string(content, content_type=content_type)

    await asyncio.to_thread(_upload)
    return blob_path
