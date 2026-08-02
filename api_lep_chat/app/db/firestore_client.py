"""Async Firestore client factory, kept separate from firebase_admin since repositories and
the agent need the raw google-cloud-firestore client (vector search lives only in that library)."""

from functools import lru_cache

from google.cloud import firestore

from app.core.config import Settings, get_settings


def build_firestore_client(settings: Settings) -> firestore.AsyncClient:
    return firestore.AsyncClient(project=settings.google_cloud_project, database=settings.firestore_database_id)


@lru_cache
def get_firestore_client() -> firestore.AsyncClient:
    return build_firestore_client(get_settings())
