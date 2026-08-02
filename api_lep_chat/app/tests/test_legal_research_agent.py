from unittest.mock import AsyncMock, MagicMock

import pytest

from app.agents.config import AgentConfig
from app.agents.legal_research_agent import LegalResearchAgent


def _make_config() -> AgentConfig:
    return AgentConfig(
        project_id="lep-chat",
        location="us-central1",
        embedding_model="text-embedding-005",
        generation_model="gemini-2.5-flash",
        top_k_chunks=2,
        course_chunk_limit=10,
        catalog_collection="law_catalog",
        chunks_collection="document_chunks",
    )


def _make_firestore_client(chunks: list[dict], domain_summary: dict | None = None):
    domain_summary = domain_summary if domain_summary is not None else {"Domestic laws": {"Tax": {"VAT": 3}}}

    domain_doc = MagicMock()
    domain_doc.exists = True
    domain_doc.to_dict.return_value = {"summary": domain_summary}

    catalog_meta_collection = MagicMock()
    catalog_meta_collection.document.return_value.get = AsyncMock(return_value=domain_doc)

    chunk_docs = []
    for chunk in chunks:
        doc = MagicMock()
        doc.to_dict.return_value = chunk
        chunk_docs.append(doc)

    find_nearest_query = MagicMock()
    find_nearest_query.get = AsyncMock(return_value=chunk_docs)

    chunks_collection = MagicMock()
    chunks_collection.find_nearest.return_value = find_nearest_query

    client = MagicMock()

    def collection_side_effect(name):
        return catalog_meta_collection if name == "catalog_meta" else chunks_collection

    client.collection.side_effect = collection_side_effect
    return client


def _make_genai_client(domain_guess_text: str, answer_text: str):
    genai_client = MagicMock()
    genai_client.aio = MagicMock()

    generate_response = MagicMock()
    generate_response.text = domain_guess_text
    answer_response = MagicMock()
    answer_response.text = answer_text
    genai_client.aio.models.generate_content = AsyncMock(side_effect=[generate_response, answer_response])

    embed_response = MagicMock()
    embed_response.embeddings = [MagicMock(values=[0.1, 0.2, 0.3])]
    genai_client.aio.models.embed_content = AsyncMock(return_value=embed_response)

    return genai_client


async def test_answer_returns_grounded_content_with_citations():
    chunks = [
        {
            "filename": "vat_law.pdf",
            "law_number": "49",
            "law_year": "2023",
            "domain": "Tax",
            "gcs_path": "Domestic laws/Tax/vat_law.pdf",
            "text": "VAT is charged at 18 percent.",
        }
    ]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client(
        domain_guess_text='{"category": "Domestic laws", "domain": "Tax", "subdomain": "VAT"}',
        answer_text="VAT is 18% [Source 1].",
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("What is the VAT rate in Rwanda?")

    assert result.content == "VAT is 18% [Source 1]."
    assert result.citations == [
        {
            "source": "vat_law.pdf",
            "quote": "VAT is charged at 18 percent.",
            "law_number": "49",
            "law_year": "2023",
            "gcs_path": "Domestic laws/Tax/vat_law.pdf",
            "domain": "Tax",
        }
    ]


async def test_answer_handles_domain_guess_wrapped_in_markdown_fence():
    chunks = [{"filename": "labour_law.pdf", "domain": "Labour", "text": "..."}]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client(
        domain_guess_text='```json\n{"category": "Domestic laws", "domain": "Labour", "subdomain": null}\n```',
        answer_text="Answer about labour law [Source 1].",
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("What are working hours?")

    assert "labour law" in result.content


async def test_answer_returns_fallback_when_no_chunks_found():
    firestore_client = _make_firestore_client(chunks=[])
    genai_client = _make_genai_client(domain_guess_text="{}", answer_text="unused")
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("Something totally unrelated")

    assert "couldn't find any matching content" in result.content
    assert result.citations == []
