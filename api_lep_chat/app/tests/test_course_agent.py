import json
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.agents.config import AgentConfig
from app.agents.course_agent import CourseGeneratorAgent


def _make_config() -> AgentConfig:
    return AgentConfig(
        project_id="lep-chat",
        location="us-central1",
        embedding_model="text-embedding-005",
        generation_model="gemini-2.5-flash",
        top_k_chunks=8,
        course_chunk_limit=10,
        catalog_collection="law_catalog",
        chunks_collection="document_chunks",
    )


def _make_firestore_client(chunks: list[dict], domain_summary: dict | None = None):
    domain_summary = domain_summary if domain_summary is not None else {"Domestic laws": {"9. Civil": {"9.7. Labour": 15}}}

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


def _make_genai_client(course_json: dict, domain_guess_text: str = "{}"):
    genai_client = MagicMock()
    genai_client.aio = MagicMock()

    domain_response = MagicMock()
    domain_response.text = domain_guess_text
    course_response = MagicMock()
    course_response.text = json.dumps(course_json)
    genai_client.aio.models.generate_content = AsyncMock(side_effect=[domain_response, course_response])

    embed_response = MagicMock()
    embed_response.embeddings = [MagicMock(values=[0.1, 0.2, 0.3])]
    genai_client.aio.models.embed_content = AsyncMock(return_value=embed_response)

    return genai_client


def _five_module_response(source_numbers_per_module: list[list[int]] | None = None) -> dict:
    source_numbers_per_module = source_numbers_per_module or [[1]] * 5
    return {
        "course_title": "Labour Law Essentials",
        "course_description": "A grounded overview of Rwandan labour law.",
        "modules": [
            {
                "title": f"Module {i + 1}",
                "summary": f"Summary for module {i + 1}",
                "source_numbers": nums,
            }
            for i, nums in enumerate(source_numbers_per_module)
        ],
    }


async def test_generate_returns_five_grounded_modules():
    chunks = [
        {
            "filename": "labour_code.pdf",
            "law_number": "66",
            "law_year": "2018",
            "domain": "9.7. Labour",
            "gcs_path": "Domestic laws/9. Civil/9.7. Labour/labour_code.pdf",
            "text": "An employer must give written notice before terminating an employment contract.",
        }
    ]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client(
        _five_module_response(), domain_guess_text='{"category": "Domestic laws", "domain": "9.7. Labour"}'
    )
    agent = CourseGeneratorAgent(firestore_client, genai_client, _make_config())

    course = await agent.generate("labour-law-101")

    assert course.track == "labour-law-101"
    assert course.title == "Labour Law Essentials"
    assert course.description == "A grounded overview of Rwandan labour law."
    assert len(course.modules) == 5
    assert course.modules[0].title == "Module 1"
    assert course.modules[0].citations == [
        {
            "source": "labour_code.pdf",
            "quote": "An employer must give written notice before terminating an employment contract.",
            "law_number": "66",
            "law_year": "2018",
            "gcs_path": "Domestic laws/9. Civil/9.7. Labour/labour_code.pdf",
            "domain": "9.7. Labour",
        }
    ]


async def test_generate_rejects_unknown_track():
    agent = CourseGeneratorAgent(MagicMock(), MagicMock(), _make_config())

    with pytest.raises(ValueError, match="Unknown track"):
        await agent.generate("not-a-real-track")


async def test_generate_returns_fallback_when_no_chunks_found():
    firestore_client = _make_firestore_client(chunks=[])
    genai_client = _make_genai_client(_five_module_response())
    agent = CourseGeneratorAgent(firestore_client, genai_client, _make_config())

    course = await agent.generate("family-law")

    assert course.title == "Family Law"
    assert course.modules == []
    assert "No ingested content" in course.description


async def test_generate_truncates_to_five_modules_even_if_model_returns_more():
    chunks = [{"filename": "a.pdf", "text": "some text"}]
    firestore_client = _make_firestore_client(chunks)
    response_json = _five_module_response()
    response_json["modules"].append({"title": "Module 6", "summary": "extra", "source_numbers": [1]})
    genai_client = _make_genai_client(response_json)
    agent = CourseGeneratorAgent(firestore_client, genai_client, _make_config())

    course = await agent.generate("business-compliance")

    assert len(course.modules) == 5


async def test_generate_handles_malformed_json_gracefully():
    chunks = [{"filename": "a.pdf", "text": "some text"}]
    firestore_client = _make_firestore_client(chunks)
    genai_client = MagicMock()
    genai_client.aio = MagicMock()
    genai_client.aio.models.generate_content = AsyncMock(
        side_effect=[MagicMock(text="{}"), MagicMock(text="not json at all")]
    )
    embed_response = MagicMock()
    embed_response.embeddings = [MagicMock(values=[0.1])]
    genai_client.aio.models.embed_content = AsyncMock(return_value=embed_response)

    agent = CourseGeneratorAgent(firestore_client, genai_client, _make_config())
    course = await agent.generate("land-rights")

    assert course.title == "Land Rights"
    assert course.modules == []


async def test_generate_boosts_chunks_matching_the_guessed_domain():
    chunks = [
        {"filename": "constitution.pdf", "domain": "1. Fundamental", "text": "General constitutional text."},
        {"filename": "labour_code.pdf", "domain": "9.7. Labour", "text": "Specific labour code text."},
    ]
    firestore_client = _make_firestore_client(chunks)
    genai_client = _make_genai_client(
        _five_module_response(source_numbers_per_module=[[1]] * 5),
        domain_guess_text='{"category": "Domestic laws", "domain": "9.7. Labour"}',
    )
    agent = CourseGeneratorAgent(firestore_client, genai_client, _make_config())

    course = await agent.generate("labour-law-101")

    # After boosting, the labour_code chunk should sort first, so source [1] in the
    # model's response resolves to it, not the constitution chunk.
    assert course.modules[0].citations[0]["source"] == "labour_code.pdf"
