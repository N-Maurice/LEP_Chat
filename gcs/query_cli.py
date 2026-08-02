"""
query_cli.py

Interactive CLI: ask a legal question, get an answer grounded in your ingested documents,
with real citations (law number, year, filename, folder path) traced back to the bucket.

Flow:
  1. Load the domain summary (the "table of contents" built by build_catalog.py).
  2. Ask Gemini to guess which domain/subdomain is most relevant to the question.
  3. Look up matching law_catalog entries for that domain (structural match).
  4. Embed the question and run a vector search over document_chunks (content match).
  5. Soft-boost chunks whose domain matches the guessed domain.
  6. Send the top chunks + question to Gemini, ask for a grounded answer with citations.
  7. Print the answer and the sources it came from. Repeat.

Setup:
    pip install google-cloud-firestore google-genai

Run:
    python query_cli.py
"""

import json

from google.cloud import firestore
from google.cloud.firestore_v1.vector import Vector
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google import genai

# ---- EDIT THESE VALUES ----
PROJECT_ID = "lep-chat"
LOCATION = "us-central1"  # must match where embeddings were generated
EMBEDDING_MODEL = "text-embedding-005"
GENERATION_MODEL = "gemini-2.5-flash"
FIRESTORE_DATABASE_ID = "default"
FIRESTORE_CHUNKS_COLLECTION = "document_chunks"
FIRESTORE_CATALOG_COLLECTION = "law_catalog"
TOP_K_CHUNKS = 8
# ----------------------------


def load_domain_summary(firestore_client) -> dict:
    doc = firestore_client.collection("catalog_meta").document("domain_summary").get()
    if not doc.exists:
        return {}
    return doc.to_dict().get("summary", {})


def guess_relevant_domain(genai_client, question: str, domain_summary: dict) -> dict:
    """Asks Gemini to pick the most relevant category/domain/subdomain from the catalog's table of contents."""
    toc_text = json.dumps(domain_summary, indent=2, ensure_ascii=False)

    prompt = f"""You are a legal research assistant for Rwandan law. Below is the table of
contents of a legal document repository, structured as category -> domain -> subdomain -> file count.

TABLE OF CONTENTS:
{toc_text}

USER QUESTION:
{question}

Based on the table of contents above, identify the single most relevant "domain" and, if
applicable, "subdomain" for this question. Respond with ONLY a JSON object, no other text,
in this exact format:
{{"category": "...", "domain": "...", "subdomain": "..." or null}}
"""

    response = genai_client.models.generate_content(
        model=GENERATION_MODEL,
        contents=prompt,
    )
    text = response.text.strip()
    # Strip markdown code fences if the model added them despite instructions
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        return {"category": None, "domain": None, "subdomain": None}


def find_matching_laws(firestore_client, domain: str, subdomain: str | None, limit: int = 15) -> list[dict]:
    """Structural lookup: which specific laws exist under this domain/subdomain, from the catalog."""
    query = firestore_client.collection(FIRESTORE_CATALOG_COLLECTION)
    if domain:
        query = query.where("domain", "==", domain)
    if subdomain:
        query = query.where("subdomain", "==", subdomain)
    docs = query.limit(limit).stream()
    return [d.to_dict() for d in docs]


def embed_question(genai_client, question: str) -> list[float]:
    response = genai_client.models.embed_content(model=EMBEDDING_MODEL, contents=question)
    return response.embeddings[0].values


def vector_search_chunks(firestore_client, query_vector: list[float], guessed_domain: str | None) -> list[dict]:
    """
    Runs a vector similarity search across all document_chunks, then soft-boosts
    results whose domain matches the guessed domain (rather than requiring a
    composite filter+vector Firestore index, which needs separate manual setup).
    """
    collection = firestore_client.collection(FIRESTORE_CHUNKS_COLLECTION)
    results = collection.find_nearest(
        vector_field="embedding",
        query_vector=Vector(query_vector),
        distance_measure=DistanceMeasure.COSINE,
        limit=TOP_K_CHUNKS * 2,  # pull extra so boosting has something to work with
    ).get()

    chunks = [doc.to_dict() for doc in results]

    if guessed_domain:
        chunks.sort(key=lambda c: 0 if c.get("domain") == guessed_domain else 1)

    return chunks[:TOP_K_CHUNKS]


def build_grounded_answer(genai_client, question: str, chunks: list[dict]) -> str:
    context_blocks = []
    for i, c in enumerate(chunks):
        law_ref = f"{c.get('filename', 'unknown file')}"
        if c.get("law_number") and c.get("law_year"):
            law_ref += f" (Law No. {c['law_number']} of {c['law_year']})"
        context_blocks.append(f"[Source {i+1}: {law_ref}]\n{c.get('text', '')}")

    context = "\n\n---\n\n".join(context_blocks)

    prompt = f"""You are a legal research assistant for Rwandan law. Answer the question using
ONLY the sources provided below. Cite the specific source number(s) for every claim, like [Source 2].
If the sources don't contain enough information to answer, say so clearly rather than guessing.

SOURCES:
{context}

QUESTION:
{question}

ANSWER (with inline [Source N] citations):
"""

    response = genai_client.models.generate_content(
        model=GENERATION_MODEL,
        contents=prompt,
    )
    return response.text


def main():
    print("=" * 60)
    print("LEP Chat — Legal Research Assistant (CLI)")
    print("=" * 60)
    print("Type a question, or 'quit' to exit.\n")

    firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)
    genai_client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)

    domain_summary = load_domain_summary(firestore_client)
    if not domain_summary:
        print("⚠️  No catalog found. Run build_catalog.py first.")
        return

    while True:
        question = input("Your question: ").strip()
        if question.lower() in ("quit", "exit", "q"):
            print("Goodbye.")
            break
        if not question:
            continue

        print("\n🔍 Identifying relevant legal domain...")
        guess = guess_relevant_domain(genai_client, question, domain_summary)
        print(f"   -> Category: {guess.get('category')} | Domain: {guess.get('domain')} | Subdomain: {guess.get('subdomain')}")

        matching_laws = find_matching_laws(
            firestore_client, guess.get("domain"), guess.get("subdomain")
        )
        if matching_laws:
            print(f"\n📚 Found {len(matching_laws)} law(s) in this area:")
            for law in matching_laws[:10]:
                title = law.get("law_title", law.get("filename"))
                num = law.get("law_number")
                year = law.get("law_year")
                ref = f" (No. {num} of {year})" if num and year else ""
                print(f"   • {title}{ref}")

        print("\n🔎 Searching document content...")
        query_vector = embed_question(genai_client, question)
        chunks = vector_search_chunks(firestore_client, query_vector, guess.get("domain"))

        if not chunks:
            print("\n⚠️  No matching content found in the ingested documents.\n")
            continue

        print("💬 Generating answer...\n")
        answer = build_grounded_answer(genai_client, question, chunks)

        print("=" * 60)
        print("ANSWER")
        print("=" * 60)
        print(answer)

        print("\n--- Sources used ---")
        seen = set()
        for c in chunks:
            ref = c.get("filename", "unknown")
            if ref not in seen:
                seen.add(ref)
                print(f"  • {c.get('gcs_path', ref)}")
        print()


if __name__ == "__main__":
    main()
