"""
ingest.py

Pipeline: list PDFs in a GCS bucket -> extract text -> chunk -> embed (Vertex AI) -> store in Firestore.

Re-runnable: tracks processed files in a Firestore "processed_files" collection, keyed by the
GCS object path + its "updated" timestamp, so re-running the script only processes new or
changed files instead of re-embedding everything every time.

Setup:
    pip install google-cloud-storage google-cloud-firestore google-genai pypdf

Run:
    python ingest.py
"""

import hashlib
import io
import re
import time
from datetime import datetime

from google.cloud import storage
from google.cloud import firestore
from google.cloud.firestore_v1.vector import Vector
from google import genai
from pypdf import PdfReader

# ---- EDIT THESE VALUES ----
PROJECT_ID = "lep-chat"
BUCKET_NAME = "lep_chat_case_documents_gcs"
LOCATION = "us-central1"  # region for Vertex AI embedding calls (text-embedding-005 isn't available in africa-south1)
PREFIX = "Domestic laws/Laws in force/1. Fundamental/"  # e.g. "Domestic laws/" for the full category, "" for the whole bucket
EMBEDDING_MODEL = "text-embedding-005"
CHUNK_SIZE_CHARS = 3000       # ~700-800 tokens, a reasonable chunk size for legal text
CHUNK_OVERLAP_CHARS = 400     # overlap so context isn't lost at chunk boundaries
FIRESTORE_CHUNKS_COLLECTION = "document_chunks"
FIRESTORE_TRACKING_COLLECTION = "processed_files"
FIRESTORE_DATABASE_ID = "default"  # this project's Firestore database is literally named "default", not the reserved "(default)"
# ----------------------------


def parse_metadata_from_path(gcs_path: str) -> dict:
    """
    Extracts structured metadata from the GCS folder path.
    Handles two known structures in this bucket:
      1. Domestic laws/Laws in force/<domain>/<subdomain>/.../<file>.pdf
      2. Minijust_Gazettes_2026/<month>/<file>.pdf
    Falls back to just folder breadcrumbs for anything else.
    """
    parts = gcs_path.split("/")
    filename = parts[-1]
    metadata = {
        "gcs_path": gcs_path,
        "filename": filename,
        "folder_path": "/".join(parts[:-1]),
    }

    if gcs_path.startswith("Minijust_Gazettes_2026"):
        metadata["category"] = "Minijust_Gazettes_2026"
        if len(parts) >= 2:
            metadata["month"] = parts[1]
    elif gcs_path.startswith("Domestic laws"):
        metadata["category"] = "Domestic laws"
        # parts[0]="Domestic laws", parts[1]="Laws in force", parts[2]=domain, parts[3]=subdomain
        if len(parts) > 2:
            metadata["domain"] = parts[2]
        if len(parts) > 3:
            metadata["subdomain"] = parts[3]
    else:
        # Unknown top-level folder — fall back to generic breadcrumbs so nothing is dropped
        metadata["category"] = parts[0] if len(parts) > 0 else None
        if len(parts) > 2:
            metadata["domain"] = parts[2]
        if len(parts) > 3:
            metadata["subdomain"] = parts[3]

    # Try to pull a law number and year out of the filename, e.g. "..._n___49_of_2023.pdf"
    law_match = re.search(r"[Nn]o?[_.]*\s*(\d+)\D+of[_.]*\s*(\d{4})", filename)
    if law_match:
        metadata["law_number"] = law_match.group(1)
        metadata["law_year"] = law_match.group(2)

    return metadata


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Extracts all text from a PDF's raw bytes."""
    reader = PdfReader(io.BytesIO(pdf_bytes))
    pages_text = []
    for page in reader.pages:
        text = page.extract_text() or ""
        pages_text.append(text)
    return "\n".join(pages_text)


def chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    """Splits text into overlapping chunks by character count."""
    text = text.strip()
    if not text:
        return []

    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks


def file_hash(gcs_path: str, updated_timestamp: str) -> str:
    """A stable ID for tracking whether a file has changed since last processed."""
    return hashlib.sha256(f"{gcs_path}:{updated_timestamp}".encode()).hexdigest()


def format_duration(seconds: float) -> str:
    minutes, secs = divmod(int(seconds), 60)
    if minutes:
        return f"{minutes}m {secs}s"
    return f"{secs}s"


def main():
    run_start = time.time()

    print("=" * 60)
    print("LEP Chat — Document Ingestion Pipeline")
    print("=" * 60)
    print(f"Project:     {PROJECT_ID}")
    print(f"Bucket:      {BUCKET_NAME}")
    print(f"Prefix:      '{PREFIX}'")
    print(f"Model:       {EMBEDDING_MODEL} ({LOCATION})")
    print(f"Started:     {datetime.now().isoformat(timespec='seconds')}")
    print("=" * 60)

    storage_client = storage.Client(project=PROJECT_ID)
    firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)
    genai_client = genai.Client(vertexai=True, project=PROJECT_ID, location=LOCATION)

    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = list(bucket.list_blobs(prefix=PREFIX))
    pdf_blobs = [b for b in blobs if b.name.lower().endswith(".pdf")]

    print(f"\nFound {len(pdf_blobs)} PDF file(s) under this prefix.\n")

    tracking_ref = firestore_client.collection(FIRESTORE_TRACKING_COLLECTION)
    chunks_ref = firestore_client.collection(FIRESTORE_CHUNKS_COLLECTION)

    processed_count = 0
    skipped_count = 0
    failed_count = 0
    no_text_count = 0
    total_chunks_stored = 0

    failed_files = []       # (filename, reason)
    no_text_files = []      # filename
    processed_files = []    # (filename, chunk_count)

    for blob in pdf_blobs:
        updated_str = blob.updated.isoformat() if blob.updated else "unknown"
        doc_hash = file_hash(blob.name, updated_str)
        tracking_doc = tracking_ref.document(doc_hash)

        if tracking_doc.get().exists:
            skipped_count += 1
            continue

        print(f"Processing: {blob.name}")
        try:
            pdf_bytes = blob.download_as_bytes()
            text = extract_text_from_pdf(pdf_bytes)

            if not text.strip():
                print("  ⚠️  No extractable text (likely a scanned/image PDF) — skipping.")
                no_text_count += 1
                no_text_files.append(blob.name)
                continue

            metadata = parse_metadata_from_path(blob.name)
            chunks = chunk_text(text, CHUNK_SIZE_CHARS, CHUNK_OVERLAP_CHARS)
            print(f"  Extracted {len(text):,} chars -> {len(chunks)} chunks")

            for i, chunk in enumerate(chunks):
                embedding_response = genai_client.models.embed_content(
                    model=EMBEDDING_MODEL,
                    contents=chunk,
                )
                embedding_vector = embedding_response.embeddings[0].values

                chunk_doc_id = f"{doc_hash}_chunk_{i}"
                chunks_ref.document(chunk_doc_id).set(
                    {
                        "text": chunk,
                        "chunk_index": i,
                        "embedding": Vector(embedding_vector),
                        **metadata,
                    }
                )

                # Small delay to stay comfortably under embedding API rate limits
                time.sleep(0.05)

            tracking_doc.set(
                {
                    "gcs_path": blob.name,
                    "updated": updated_str,
                    "chunk_count": len(chunks),
                    "processed_at": firestore.SERVER_TIMESTAMP,
                }
            )
            processed_count += 1
            total_chunks_stored += len(chunks)
            processed_files.append((blob.name, len(chunks)))
            print(f"  ✅ Stored {len(chunks)} chunks.\n")

        except Exception as e:
            print(f"  ❌ Failed: {e}\n")
            failed_count += 1
            failed_files.append((blob.name, str(e)))

    elapsed = time.time() - run_start

    # ---------------- Professional summary report ----------------
    print("\n" + "=" * 60)
    print("INGESTION SUMMARY")
    print("=" * 60)
    print(f"Run finished:        {datetime.now().isoformat(timespec='seconds')}")
    print(f"Total duration:      {format_duration(elapsed)}")
    print(f"Files found:         {len(pdf_blobs)}")
    print(f"Files processed:     {processed_count}")
    print(f"Files skipped:       {skipped_count}  (already ingested)")
    print(f"Files w/o text:      {no_text_count}  (likely scanned images — needs OCR)")
    print(f"Files failed:        {failed_count}")
    print(f"Total chunks stored: {total_chunks_stored}")

    if processed_count:
        avg_chunks = total_chunks_stored / processed_count
        print(f"Avg chunks/file:     {avg_chunks:.1f}")

    if no_text_files:
        print("\n--- Files needing OCR (no extractable text) ---")
        for f in no_text_files:
            print(f"  • {f}")

    if failed_files:
        print("\n--- Failed files ---")
        for f, reason in failed_files:
            short_reason = reason if len(reason) < 120 else reason[:117] + "..."
            print(f"  • {f}\n      → {short_reason}")

    print("\n" + "=" * 60)
    if failed_count == 0 and no_text_count == 0:
        print("✅ All files processed successfully.")
    elif failed_count == 0:
        print(f"✅ All extractable files processed. {no_text_count} file(s) need OCR before they can be ingested.")
    else:
        print(f"⚠️  Completed with {failed_count} failure(s) — review the list above.")
    print("=" * 60)


if __name__ == "__main__":
    main()
