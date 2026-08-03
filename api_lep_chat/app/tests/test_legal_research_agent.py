from unittest.mock import AsyncMock, MagicMock

from google.genai import types as genai_types

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


def _tool_call_response(query: str) -> MagicMock:
    """A generate_content response where the model decides to call the search tool."""
    response = MagicMock()
    part = genai_types.Part.from_function_call(name="search_legal_corpus", args={"query": query})
    response.candidates = [MagicMock(content=genai_types.Content(role="model", parts=[part]))]
    response.text = None
    return response


def _final_text_response(text: str) -> MagicMock:
    """A generate_content response where the model is done calling tools and answers."""
    response = MagicMock()
    part = genai_types.Part(text=text)
    response.candidates = [MagicMock(content=genai_types.Content(role="model", parts=[part]))]
    response.text = text
    return response


def _make_genai_client(*generate_content_responses, embedding=(0.1, 0.2, 0.3)):
    genai_client = MagicMock()
    genai_client.aio = MagicMock()
    genai_client.aio.models.generate_content = AsyncMock(side_effect=list(generate_content_responses))

    embed_response = MagicMock()
    embed_response.embeddings = [MagicMock(values=list(embedding))]
    genai_client.aio.models.embed_content = AsyncMock(return_value=embed_response)

    return genai_client


async def test_answer_calls_the_search_tool_and_returns_grounded_content():
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
        _tool_call_response("VAT rate Rwanda"),
        _final_text_response("VAT is 18% [Source: vat_law.pdf (Law No. 49 of 2023)]."),
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("What is the VAT rate in Rwanda?")

    assert result.content == "VAT is 18% [Source: vat_law.pdf (Law No. 49 of 2023)]."
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


async def test_answer_supports_multiple_tool_calls_for_a_multi_part_question():
    chunks = [{"filename": "labour_law.pdf", "domain": "Labour", "text": "Working hours are 45 per week."}]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client(
        _tool_call_response("working hours"),
        _tool_call_response("overtime pay"),
        _final_text_response("Working hours are capped and overtime is paid [Source: labour_law.pdf]."),
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("What are working hours and overtime rules?")

    assert "overtime" in result.content
    assert genai_client.aio.models.generate_content.await_count == 3


async def test_answer_returns_fallback_when_no_chunks_found():
    firestore_client = _make_firestore_client(chunks=[])
    genai_client = _make_genai_client(
        _tool_call_response("something totally unrelated"),
        _final_text_response("unused"),
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    result = await agent.answer("Something totally unrelated")

    assert "couldn't find any matching content" in result.content
    assert result.citations == []


async def test_search_returns_raw_chunks_for_research_hub():
    chunks = [{"filename": "land_law.pdf", "domain": "Land", "text": "Land titles must be registered."}]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client()
    genai_client.aio.models.generate_content = AsyncMock(
        return_value=_final_text_response('{"category": "Domestic laws", "domain": "Land", "subdomain": null}')
    )
    agent = LegalResearchAgent(firestore_client, genai_client, _make_config())

    results = await agent.search("land title registration")

    assert results == chunks
