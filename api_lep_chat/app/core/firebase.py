"""Firebase Admin SDK bootstrap, used only for verifying client ID tokens (authentication)."""

import asyncio
from functools import lru_cache

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials

from app.core.config import Settings, get_settings


def init_firebase_app(settings: Settings) -> firebase_admin.App:
    """Idempotent: returns the existing app if one was already initialized."""
    if firebase_admin._apps:
        return firebase_admin.get_app()

    if settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.firebase_credentials_path)
    else:
        cred = credentials.ApplicationDefault()

    return firebase_admin.initialize_app(cred, {"projectId": settings.google_cloud_project})


@lru_cache
def get_firebase_app() -> firebase_admin.App:
    return init_firebase_app(get_settings())


async def verify_id_token(token: str) -> dict:
    """Raises firebase_admin.auth.InvalidIdTokenError / ExpiredIdTokenError on failure.
    firebase_admin's auth module has no native async API, so the blocking call is offloaded
    to a worker thread to avoid stalling the event loop."""
    get_firebase_app()
    return await asyncio.to_thread(firebase_auth.verify_id_token, token)
