"""The chatbot's "agent". Two retrieval strategies live here, both backed by the same
Firestore vector search over document_chunks (populated by gcs/ingest_v2.py):

  - `search()` — a single raw semantic search, used by the Research Hub's search box.
  - `answer()` — an agentic tool-calling loop: Gemini is given a `search_legal_corpus`
    tool and decides for itself when and what to search (possibly multiple times for a
    multi-part question) before writing a grounded, cited answer. This replaces a fixed
    "one search, one generation" pipeline with one the model can extend on its own.
"""

import json
from dataclasses import dataclass, field
from functools import lru_cache

from google import genai
from google.genai import types as genai_types
from google.cloud import firestore
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector

from app.agents.config import AgentConfig
from app.agents.prompts import AGENT_SYSTEM_INSTRUCTION, DOMAIN_GUESS_PROMPT
from app.agents.utils import excerpt, parse_json_response
from app.core.config import get_settings
from app.db.firestore_client import get_firestore_client

MAX_TOOL_CALL_ROUNDS = 4

_SEARCH_TOOL = genai_types.Tool(
    function_declarations=[
        genai_types.FunctionDeclaration(
            name="search_legal_corpus",
            description=(
                "Searches the ingested Rwandan legal corpus (constitution, laws, regulations) "
                "for passages relevant to a specific legal question or topic."
            ),
            parameters=genai_types.Schema(
                type="OBJECT",
                properties={
                    "query": genai_types.Schema(
                        type="STRING",
                        description=(
                            "A focused legal search phrase, e.g. 'employer termination notice "
                            "period' or 'land title dispute registration process' — not the "
                            "user's whole message verbatim."
                        ),
                    )
                },
                required=["query"],
            ),
        )
    ]
)


@dataclass
class AgentAnswer:
    content: str
    citations: list[dict] = field(default_factory=list)


class LegalResearchAgent:
    def __init__(self, firestore_client: firestore.AsyncClient, genai_client: genai.Client, config: AgentConfig):
        self._firestore = firestore_client
        self._genai = genai_client
        self._config = config

    async def search(self, query: str, limit: int = 10) -> list[dict]:
        """Raw semantic search over document_chunks for the Research Hub — no
        Gemini grounded-answer generation, just the ranked source chunks
        themselves (each result IS a citation, ready for `Read Original`)."""
        domain_summary = await self._load_domain_summary()
        guess = await self._guess_relevant_domain(query, domain_summary) if domain_summary else {}

        query_vector = await self._embed_question(query)
        chunks = await self._vector_search_chunks(query_vector, guess.get("domain"), limit=limit)
        return chunks

    async def answer(self, question: str) -> AgentAnswer:
        collected_chunks: dict[str, dict] = {}
        contents: list[genai_types.Content] = [
            genai_types.Content(role="user", parts=[genai_types.Part(text=question)])
        ]
        config = genai_types.GenerateContentConfig(
            system_instruction=AGENT_SYSTEM_INSTRUCTION,
            tools=[_SEARCH_TOOL],
        )

        final_text = ""
        for _ in range(MAX_TOOL_CALL_ROUNDS):
            response = await self._genai.aio.models.generate_content(
                model=self._config.generation_model,
                contents=contents,
                config=config,
            )
            candidate_content = response.candidates[0].content
            contents.append(candidate_content)

            function_calls = [part.function_call for part in (candidate_content.parts or []) if part.function_call]
            if not function_calls:
                final_text = response.text or ""
                break

            response_parts = []
            for call in function_calls:
                query = (call.args or {}).get("query") or question
                chunks = await self._search_chunks(query)
                for chunk in chunks:
                    key = chunk.get("gcs_path") or chunk.get("filename", "")
                    collected_chunks.setdefault(key, chunk)
                response_parts.append(
                    genai_types.Part.from_function_response(
                        name=call.name,
                        response={"result": self._format_search_results(chunks)},
                    )
                )
            contents.append(genai_types.Content(role="user", parts=response_parts))
        else:
            final_text = response.text or ""

        if not collected_chunks:
            return AgentAnswer(
                content="I couldn't find any matching content in the ingested legal documents "
                "for this question. Try rephrasing it or asking about a different topic.",
                citations=[],
            )

        return AgentAnswer(content=final_text, citations=self._citations_from_chunks(list(collected_chunks.values())))

    async def _search_chunks(self, query: str) -> list[dict]:
        query_vector = await self._embed_question(query)
        return await self._vector_search_chunks(query_vector, None, limit=self._config.top_k_chunks)

    def _format_search_results(self, chunks: list[dict]) -> str:
        if not chunks:
            return "No matching passages found for this query."
        blocks = [f"[Source: {self._source_label(c)}]\n{c.get('text', '')}" for c in chunks]
        return "\n\n---\n\n".join(blocks)

    @classmethod
    def _source_label(cls, chunk: dict) -> str:
        ref = chunk.get("law_title") or chunk.get("filename", "unknown source")
        if chunk.get("law_number") and chunk.get("law_year"):
            ref += f" (Law No. {chunk['law_number']} of {chunk['law_year']})"
        return ref

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

    async def _vector_search_chunks(
        self, query_vector: list[float], guessed_domain: str | None, limit: int | None = None
    ) -> list[dict]:
        top_k = limit or self._config.top_k_chunks
        collection = self._firestore.collection(self._config.chunks_collection)
        results = await collection.find_nearest(
            vector_field="embedding",
            query_vector=Vector(query_vector),
            distance_measure=DistanceMeasure.COSINE,
            limit=top_k * 2,
        ).get()

        chunks = [doc.to_dict() for doc in results]
        if guessed_domain:
            chunks.sort(key=lambda c: 0 if c.get("domain") == guessed_domain else 1)

        return chunks[:top_k]

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
