"""Agent-specific configuration, derived from the app-wide Settings so the agent stays
decoupled from the pydantic-settings machinery."""

from dataclasses import dataclass

from app.core.config import Settings


@dataclass(frozen=True)
class AgentConfig:
    project_id: str
    location: str
    embedding_model: str
    generation_model: str
    top_k_chunks: int
    course_chunk_limit: int
    catalog_collection: str
    chunks_collection: str

    @classmethod
    def from_settings(cls, settings: Settings) -> "AgentConfig":
        return cls(
            project_id=settings.google_cloud_project,
            location=settings.google_cloud_location,
            embedding_model=settings.embedding_model,
            generation_model=settings.generation_model,
            top_k_chunks=settings.top_k_chunks,
            course_chunk_limit=settings.course_chunk_limit,
            catalog_collection=settings.firestore_catalog_collection,
            chunks_collection=settings.firestore_chunks_collection,
        )
