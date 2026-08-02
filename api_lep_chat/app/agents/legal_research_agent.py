"""The chatbot's "agent": an async port of gcs/query_cli.py's RAG flow (domain-catalog
lookup -> Firestore vector search -> Gemini grounded answer with citations), reused here
instead of duplicated so both the CLI and the API stay backed by the same retrieval logic.

Flow per question:
  1. Load the domain summary (the "table of contents" built by build_catalog.py).
  2. Ask Gemini to guess which domain/subdomain is most relevant.
  3. Embed the question and run a vector search over document_chunks.
  4. Soft-boost chunks whose domain matches the guessed domain.
  5. Send the top chunks + question to Gemini, ask for a grounded answer with citations.
"""

import json
from dataclasses import dataclass, field
from functools import lru_cache

from google import genai
from google.cloud import firestore
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector

from app.agents.config import AgentConfig
from app.agents.prompts import DOMAIN_GUESS_PROMPT, GROUNDED_ANSWER_PROMPT
from app.agents.utils import excerpt, parse_json_response
from app.core.config import get_settings
from app.db.firestore_client import get_firestore_client


@dataclass
class AgentAnswer:
    content: str
    citations: list[dict] = field(default_factory=list)


class LegalResearchAgent:
    def __init__(self, firestore_client: firestore.AsyncClient, genai_client: genai.Client, config: AgentConfig):
        self._firestore = firestore_client
        self._genai = genai_client
        self._config = config

    async def answer(self, question: str) -> AgentAnswer:
        domain_summary = await self._load_domain_summary()
        guess = await self._guess_relevant_domain(question, domain_summary) if domain_summary else {}

        query_vector = await self._embed_question(question)
        chunks = await self._vector_search_chunks(query_vector, guess.get("domain"))

        if not chunks:
            return AgentAnswer(
                content="I couldn't find any matching content in the ingested legal documents "
                "for this question. Try rephrasing it or asking about a different topic.",
                citations=[],
            )

        content = await self._build_grounded_answer(question, chunks)
        return AgentAnswer(content=content, citations=self._citations_from_chunks(chunks))

    async def _load_domain_summary(self) -> dict:
        doc = await self._firestore.collection("catalog_meta").document("domain_summary").get()
        if not doc.exists:
            return {}
        return doc.to_dict().get("summary", {})

    async def _guess_relevant_domain(self, question: str, domain_summary: dict) -> dict:
        toc_text = json.dumps(domain_summary, indent=2, ensure_ascii=False)
        prompt = DOMAIN_GUESS_PROMPT.format(toc_text=toc_text, question=question)

        response = await self._genai.aio.models.generate_content(
            model=self._config.generation_model,
            contents=prompt,
        )
        parsed = parse_json_response(response.text or "")
        return parsed or {"category": None, "domain": None, "subdomain": None}

    async def _embed_question(self, question: str) -> list[float]:
        response = await self._genai.aio.models.embed_content(
            model=self._config.embedding_model,
            contents=question,
        )
        return response.embeddings[0].values

    async def _vector_search_chunks(self, query_vector: list[float], guessed_domain: str | None) -> list[dict]:
        collection = self._firestore.collection(self._config.chunks_collection)
        results = await collection.find_nearest(
            vector_field="embedding",
            query_vector=Vector(query_vector),
            distance_measure=DistanceMeasure.COSINE,
            limit=self._config.top_k_chunks * 2,
        ).get()

        chunks = [doc.to_dict() for doc in results]
        if guessed_domain:
            chunks.sort(key=lambda c: 0 if c.get("domain") == guessed_domain else 1)

        return chunks[: self._config.top_k_chunks]

    async def _build_grounded_answer(self, question: str, chunks: list[dict]) -> str:
        context_blocks = []
        for i, c in enumerate(chunks):
            law_ref = c.get("filename", "unknown file")
            if c.get("law_number") and c.get("law_year"):
                law_ref += f" (Law No. {c['law_number']} of {c['law_year']})"
            context_blocks.append(f"[Source {i + 1}: {law_ref}]\n{c.get('text', '')}")
        context = "\n\n---\n\n".join(context_blocks)

        prompt = GROUNDED_ANSWER_PROMPT.format(context=context, question=question)
        response = await self._genai.aio.models.generate_content(
            model=self._config.generation_model,
            contents=prompt,
        )
        return response.text or ""

    @classmethod
    def _citations_from_chunks(cls, chunks: list[dict]) -> list[dict]:
        seen: set[str] = set()
        citations = []
        for c in chunks:
            ref = c.get("filename", "unknown")
            if ref in seen:
                continue
            seen.add(ref)
            citations.append(
                {
                    "source": c.get("law_title") or ref,
                    "quote": excerpt(c.get("text", "")),
                    "law_number": c.get("law_number"),
                    "law_year": c.get("law_year"),
                    "gcs_path": c.get("gcs_path"),
                    "domain": c.get("domain"),
                }
            )
        return citations


@lru_cache
def get_genai_client() -> genai.Client:
    settings = get_settings()
    return genai.Client(vertexai=True, project=settings.google_cloud_project, location=settings.google_cloud_location)


@lru_cache
def get_legal_research_agent() -> LegalResearchAgent:
    settings = get_settings()
    return LegalResearchAgent(
        firestore_client=get_firestore_client(),
        genai_client=get_genai_client(),
        config=AgentConfig.from_settings(settings),
    )
