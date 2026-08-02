"""Single source of truth for environment configuration, validated at startup."""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    environment: str = Field(default="development", alias="ENVIRONMENT")

    # Google Cloud / Firebase project
    google_cloud_project: str = Field(default="lep-chat", alias="GOOGLE_CLOUD_PROJECT")
    google_cloud_location: str = Field(default="us-central1", alias="GOOGLE_CLOUD_LOCATION")

    # Path to a Firebase service account JSON. Leave empty to fall back to
    # Application Default Credentials (gcloud auth application-default login).
    firebase_credentials_path: str | None = Field(default=None, alias="FIREBASE_CREDENTIALS_PATH")

    # Firestore
    firestore_database_id: str = Field(default="default", alias="FIRESTORE_DATABASE_ID")
    firestore_sessions_collection: str = Field(default="chat_sessions", alias="FIRESTORE_SESSIONS_COLLECTION")
    firestore_messages_subcollection: str = Field(default="messages", alias="FIRESTORE_MESSAGES_SUBCOLLECTION")
    firestore_chunks_collection: str = Field(default="document_chunks", alias="FIRESTORE_CHUNKS_COLLECTION")
    firestore_catalog_collection: str = Field(default="law_catalog", alias="FIRESTORE_CATALOG_COLLECTION")

    # Agent / Gen AI models (must match the models used by gcs/ingest_v2.py to embed the corpus)
    embedding_model: str = Field(default="text-embedding-005", alias="EMBEDDING_MODEL")
    generation_model: str = Field(default="gemini-2.5-flash", alias="GENERATION_MODEL")
    top_k_chunks: int = Field(default=8, alias="TOP_K_CHUNKS")

    # API
    api_v1_prefix: str = Field(default="/api/v1", alias="API_V1_PREFIX")
    cors_origins: str = Field(default="*", alias="CORS_ORIGINS")

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
