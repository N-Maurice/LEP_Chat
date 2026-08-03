"""Business logic for the Research Hub: semantic search over the ingested legal
corpus, and signed URLs so the mobile app can read/download the original source
PDF straight from GCS (Read Original / Download)."""

import hashlib
import re
from typing import Awaitable, Callable

from fastapi import Depends, HTTPException, status

from app.agents.legal_research_agent import LegalResearchAgent, get_legal_research_agent
from app.agents.utils import excerpt
from app.core.config import Settings, get_settings
from app.db.storage_client import signed_read_url
from app.schemas.research import DocumentUrlOut, ResearchResultOut

SignUrlFn = Callable[[str, str], Awaitable[str]]


def _title_from_filename(filename: str) -> str:
    stem = re.sub(r"\.pdf$", "", filename, flags=re.IGNORECASE)
    return stem.replace("_", " ").replace("-", " ").strip()


def _institution_from_breadcrumb(chunk: dict) -> str:
    parts = [p for p in (chunk.get("category"), chunk.get("subdomain")) if p]
    return " · ".join(parts) if parts else "Rwandan Legal Corpus"


class ResearchService:
    def __init__(self, agent: LegalResearchAgent, corpus_bucket: str, sign_url: SignUrlFn = signed_read_url):
        self._agent = agent
        self._corpus_bucket = corpus_bucket
        self._sign_url = sign_url

    async def search(self, query: str, limit: int = 10) -> list[ResearchResultOut]:
        chunks = await self._agent.search(query, limit=limit)
        results = []
        for chunk in chunks:
            gcs_path = chunk.get("gcs_path")
            result_id = hashlib.sha1((gcs_path or chunk.get("filename", "")).encode()).hexdigest()[:16]
            results.append(
                ResearchResultOut(
                    id=result_id,
                    institution=_institution_from_breadcrumb(chunk),
                    tag=chunk.get("domain") or chunk.get("category") or "General",
                    title=_title_from_filename(chunk.get("filename", "Untitled document")),
                    summary=excerpt(chunk.get("text", ""), max_chars=320),
                    source=chunk.get("law_title") or chunk.get("filename", "unknown"),
                    law_number=chunk.get("law_number"),
                    law_year=chunk.get("law_year"),
                    gcs_path=gcs_path,
                    domain=chunk.get("domain"),
                )
            )
        return results

    async def get_document_url(self, gcs_path: str) -> DocumentUrlOut:
        if not gcs_path:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "This result has no linked source document")
        url = await self._sign_url(self._corpus_bucket, gcs_path)
        return DocumentUrlOut(url=url)


def get_research_service(
    settings: Settings = Depends(get_settings),
    agent: LegalResearchAgent = Depends(get_legal_research_agent),
) -> ResearchService:
    return ResearchService(agent, settings.gcs_corpus_bucket)
