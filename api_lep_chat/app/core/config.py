"""Single source of truth for environment configuration, validated at startup."""

import os
from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# Resolved relative to this file, not the process's CWD — otherwise .env is
# silently skipped (and every field quietly falls back to its class default)
# unless the app happens to be launched from exactly this directory.
_ENV_FILE = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_ENV_FILE, env_file_encoding="utf-8", extra="ignore", populate_by_name=True
    )

    environment: str = Field(default="development", alias="ENVIRONMENT")

    # Google Cloud / Firebase project
    google_cloud_project: str = Field(default="lep-chat", alias="GOOGLE_CLOUD_PROJECT")
    google_cloud_location: str = Field(default="us-central1", alias="GOOGLE_CLOUD_LOCATION")

    # GCS buckets. Corpus bucket holds the ingested law PDFs (gcs/ingest_v2.py);
    # evidence bucket holds citizen-submitted case/report attachments.
    gcs_corpus_bucket: str = Field(default="lep_chat_case_documents_gcs", alias="GCS_CORPUS_BUCKET")
    gcs_evidence_bucket: str = Field(default="lep_chat_case_documents_gcs", alias="GCS_EVIDENCE_BUCKET")

    # Path to a Firebase service account JSON. Leave empty to fall back to
    # Application Default Credentials (gcloud auth application-default login).
    firebase_credentials_path: str | None = Field(default=None, alias="FIREBASE_CREDENTIALS_PATH")

    # Firestore
    firestore_database_id: str = Field(default="default", alias="FIRESTORE_DATABASE_ID")
    firestore_sessions_collection: str = Field(default="chat_sessions", alias="FIRESTORE_SESSIONS_COLLECTION")
    firestore_messages_subcollection: str = Field(default="messages", alias="FIRESTORE_MESSAGES_SUBCOLLECTION")
    firestore_chunks_collection: str = Field(default="document_chunks", alias="FIRESTORE_CHUNKS_COLLECTION")
    firestore_catalog_collection: str = Field(default="law_catalog", alias="FIRESTORE_CATALOG_COLLECTION")
    firestore_users_collection: str = Field(default="users", alias="FIRESTORE_USERS_COLLECTION")
    firestore_courses_collection: str = Field(default="generated_courses", alias="FIRESTORE_COURSES_COLLECTION")
    firestore_cases_collection: str = Field(default="cases", alias="FIRESTORE_CASES_COLLECTION")
    firestore_conversations_collection: str = Field(default="conversations", alias="FIRESTORE_CONVERSATIONS_COLLECTION")

    # Agent / Gen AI models (must match the models used by gcs/ingest_v2.py to embed the corpus)
    embedding_model: str = Field(default="text-embedding-005", alias="EMBEDDING_MODEL")
    generation_model: str = Field(default="gemini-2.5-flash", alias="GENERATION_MODEL")
    top_k_chunks: int = Field(default=8, alias="TOP_K_CHUNKS")
    # More chunks than a single Q&A needs — a 5-module course needs enough source
    # material to partition into 5 distinct, non-overlapping themes.
    # Raised from 30 -> 60 so generated courses draw on more of the ingested corpus per
    # track, producing longer, more thorough modules instead of thin summaries.
    course_chunk_limit: int = Field(default=60, alias="COURSE_CHUNK_LIMIT")

    # API
    api_v1_prefix: str = Field(default="/api/v1", alias="API_V1_PREFIX")
    cors_origins: str = Field(default="*", alias="CORS_ORIGINS")

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    # firebase_admin only reads firebase_credentials_path for its own app. The
    # separate google-cloud-firestore and google-genai (Vertex AI) clients each
    # independently call google.auth.default(), which only ever looks at this
    # env var — so it has to be set here too or those clients silently fall
    # back to (missing) Application Default Credentials.
    if settings.firebase_credentials_path:
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", settings.firebase_credentials_path)
    return settings
