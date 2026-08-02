"""Generates a structured 5-module course per learning track, grounded in the same
Firestore document_chunks the chat agent retrieves from. Track names are fixed UI tabs;
the corpus's real taxonomy (see catalog_meta/domain_summary) uses a different numbered
scheme, so retrieval is semantic (vector search against a seed query), not exact-match —
and course/module content only ever comes from what's actually retrieved, never invented.
"""

import json
from dataclasses import dataclass, field
from functools import lru_cache

from google import genai
from google.cloud import firestore
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector

from app.agents.config import AgentConfig
from app.agents.legal_research_agent import get_genai_client
from app.agents.prompts import COURSE_GENERATION_PROMPT, DOMAIN_GUESS_PROMPT
from app.agents.utils import excerpt, parse_json_response
from app.core.config import get_settings
from app.db.firestore_client import get_firestore_client

# Seed queries used for semantic retrieval per track — not exact domain-name matches,
# since the corpus's own taxonomy (numbered codes like "9.7. Labour") doesn't line up
# with these UI-facing track names.
TRACK_SEED_QUERIES: dict[str, str] = {
    "labour-law-101": "Labour law, employment contracts, workers' rights, and termination of employment in Rwanda",
    "business-compliance": "Business registration, commercial activities, banking, investment, and tax compliance in Rwanda",
    "family-law": "Family law, marriage, civil status, and rights of persons in Rwanda",
    "land-rights": "Land ownership, property rights, and natural resources law in Rwanda",
}

TRACK_LABELS: dict[str, str] = {
    "labour-law-101": "Labour Law 101",
    "business-compliance": "Business Compliance",
    "family-law": "Family Law",
    "land-rights": "Land Rights",
}

MODULE_COUNT = 5


@dataclass
class CourseModule:
    title: str
    summary: str
    citations: list[dict] = field(default_factory=list)


@dataclass
class GeneratedCourse:
    track: str
    title: str
    description: str
    modules: list[CourseModule] = field(default_factory=list)


class CourseGeneratorAgent:
    def __init__(self, firestore_client: firestore.AsyncClient, genai_client: genai.Client, config: AgentConfig):
        self._firestore = firestore_client
        self._genai = genai_client
        self._config = config

    async def generate(self, track: str) -> GeneratedCourse:
        seed_query = TRACK_SEED_QUERIES.get(track)
        if seed_query is None:
            raise ValueError(f"Unknown track: {track!r}. Known tracks: {sorted(TRACK_SEED_QUERIES)}")

        domain_summary = await self._load_domain_summary()
        guess = await self._guess_relevant_domain(seed_query, domain_summary) if domain_summary else {}

        query_vector = await self._embed(seed_query)
        chunks = await self._vector_search_chunks(query_vector, guess.get("domain"))

        if not chunks:
            return GeneratedCourse(
                track=track,
                title=TRACK_LABELS.get(track, track),
                description="No ingested content is available for this track yet.",
                modules=[],
            )

        return await self._build_course(track, chunks)

    async def _load_domain_summary(self) -> dict:
        doc = await self._firestore.collection("catalog_meta").document("domain_summary").get()
        if not doc.exists:
            return {}
        return doc.to_dict().get("summary", {})

    async def _guess_relevant_domain(self, seed_query: str, domain_summary: dict) -> dict:
        toc_text = json.dumps(domain_summary, indent=2, ensure_ascii=False)
        prompt = DOMAIN_GUESS_PROMPT.format(toc_text=toc_text, question=seed_query)
        response = await self._genai.aio.models.generate_content(
            model=self._config.generation_model,
            contents=prompt,
        )
        return parse_json_response(response.text or "")

    async def _embed(self, text: str) -> list[float]:
        response = await self._genai.aio.models.embed_content(model=self._config.embedding_model, contents=text)
        return response.embeddings[0].values

    async def _vector_search_chunks(self, query_vector: list[float], guessed_domain: str | None) -> list[dict]:
        collection = self._firestore.collection(self._config.chunks_collection)
        results = await collection.find_nearest(
            vector_field="embedding",
            query_vector=Vector(query_vector),
            distance_measure=DistanceMeasure.COSINE,
            limit=self._config.course_chunk_limit * 2,
        ).get()

        chunks = [doc.to_dict() for doc in results]
        if guessed_domain:
            chunks.sort(key=lambda c: 0 if c.get("domain") == guessed_domain else 1)

        return chunks[: self._config.course_chunk_limit]

    async def _build_course(self, track: str, chunks: list[dict]) -> GeneratedCourse:
        context_blocks = []
        for i, c in enumerate(chunks):
            law_ref = c.get("filename", "unknown file")
            if c.get("law_number") and c.get("law_year"):
                law_ref += f" (Law No. {c['law_number']} of {c['law_year']})"
            context_blocks.append(f"[Source {i + 1}: {law_ref}]\n{c.get('text', '')}")
        context = "\n\n---\n\n".join(context_blocks)

        prompt = COURSE_GENERATION_PROMPT.format(track_label=TRACK_LABELS.get(track, track), context=context)
        response = await self._genai.aio.models.generate_content(
            model=self._config.generation_model,
            contents=prompt,
        )
        parsed = parse_json_response(response.text or "")

        source_lookup = {i + 1: c for i, c in enumerate(chunks)}
        modules = [
            CourseModule(
                title=m.get("title") or "Untitled module",
                summary=m.get("summary") or "",
                citations=self._resolve_citations(m.get("source_numbers") or [], source_lookup),
            )
            for m in (parsed.get("modules") or [])[:MODULE_COUNT]
        ]

        return GeneratedCourse(
            track=track,
            title=parsed.get("course_title") or TRACK_LABELS.get(track, track),
            description=parsed.get("course_description") or "",
            modules=modules,
        )

    @staticmethod
    def _resolve_citations(source_numbers: list, lookup: dict[int, dict]) -> list[dict]:
        seen: set[str] = set()
        citations = []
        for n in source_numbers:
            try:
                chunk = lookup[int(n)]
            except (TypeError, ValueError, KeyError):
                continue
            ref = chunk.get("filename", "unknown")
            if ref in seen:
                continue
            seen.add(ref)
            citations.append(
                {
                    "source": chunk.get("law_title") or ref,
                    "quote": excerpt(chunk.get("text", "")),
                    "law_number": chunk.get("law_number"),
                    "law_year": chunk.get("law_year"),
                    "gcs_path": chunk.get("gcs_path"),
                    "domain": chunk.get("domain"),
                }
            )
        return citations


@lru_cache
def get_course_generator_agent() -> CourseGeneratorAgent:
    settings = get_settings()
    return CourseGeneratorAgent(
        firestore_client=get_firestore_client(),
        genai_client=get_genai_client(),
        config=AgentConfig.from_settings(settings),
    )
