"""
build_catalog.py

Builds a lightweight structural catalog of every PDF in the bucket, based purely on
folder paths and filenames — no PDF downloads, no embeddings, runs in seconds/minutes
even across the whole bucket.

This catalog is the "map" layer: it lets an AI agent reason about which law/domain/
subdomain is relevant to a query BEFORE doing expensive content-level vector search
on document_chunks. Think of it as the table of contents for the whole legal corpus.

Setup:
    pip install google-cloud-storage google-cloud-firestore

Run:
    python build_catalog.py
"""

import re
from datetime import datetime

from google.cloud import storage
from google.cloud import firestore

# ---- EDIT THESE VALUES ----
PROJECT_ID = "lep-chat"
BUCKET_NAME = "lep_chat_case_documents_gcs"
PREFIX = ""  # "" = whole bucket. Set to a subfolder to scope a test run.
FIRESTORE_CATALOG_COLLECTION = "law_catalog"
FIRESTORE_DATABASE_ID = "default"
# ----------------------------


def humanize_filename(filename: str) -> str:
    """
    Turns a raw filename like:
      '8.2.1._Value_Added_Tax__Law_n___49_of_2023.pdf'
    into a readable title:
      'Value Added Tax'
    Strips the leading numbering code, trailing '.pdf', underscores, and the
    'Law n. X of YYYY' suffix so the AI (and you) get a clean human title to show users.
    """
    name = filename[:-4] if filename.lower().endswith(".pdf") else filename

    # Strip leading numbering code like "8.2.1." or "1.1.9.1_"
    name = re.sub(r"^[\d.]+[_.]*", "", name)

    # Replace underscores with spaces
    name = name.replace("_", " ")

    # Strip common legal-reference suffixes (Law n. X of YYYY, PO n. X of YYYY, MO n. X of YYYY, etc.)
    name = re.sub(
        r"\s*(Law|OL|PO|MO|PMO|REG|Regul|MOD|Reg)\.?\s*(no\.?|n[o°]?)?\s*_*\s*\d+.*$",
        "",
        name,
        flags=re.IGNORECASE,
    )

    # Collapse repeated whitespace
    name = re.sub(r"\s+", " ", name).strip(" .")

    return name if name else filename


def parse_catalog_entry(gcs_path: str) -> dict:
    """Extracts structural + descriptive metadata for the catalog (path-only, no PDF content)."""
    parts = gcs_path.split("/")
    filename = parts[-1]

    entry = {
        "gcs_path": gcs_path,
        "filename": filename,
        "folder_path": "/".join(parts[:-1]),
        "law_title": humanize_filename(filename),
    }

    if gcs_path.startswith("Minijust_Gazettes_2026"):
        entry["category"] = "Minijust_Gazettes_2026"
        if len(parts) >= 2:
            entry["month"] = parts[1]
    elif gcs_path.startswith("Domestic laws"):
        entry["category"] = "Domestic laws"
        if len(parts) > 2:
            entry["domain"] = parts[2]
        if len(parts) > 3:
            entry["subdomain"] = parts[3]
    else:
        entry["category"] = parts[0] if len(parts) > 0 else None
        if len(parts) > 2:
            entry["domain"] = parts[2]
        if len(parts) > 3:
            entry["subdomain"] = parts[3]

    # Law number and year, e.g. "..._n___49_of_2023.pdf" -> number=49, year=2023
    law_match = re.search(r"[Nn]o?[_.]*\s*(\d+)\D+of[_.]*\s*(\d{4})", filename)
    if law_match:
        entry["law_number"] = law_match.group(1)
        entry["law_year"] = law_match.group(2)

    # Flags common instrument types found in this corpus, useful for filtering
    lowered = filename.lower()
    if "amend" in lowered:
        entry["is_amendment"] = True
    if lowered.startswith(tuple(f"{n}." for n in range(10))) and "repeal" in gcs_path.lower():
        entry["is_repealed"] = True

    return entry


def build_domain_summary(entries: list[dict]) -> dict:
    """
    Aggregates entries into a nested domain/subdomain summary — this is the
    "table of contents" the AI can scan quickly to decide where to look next,
    without reading every individual entry.
    """
    summary = {}
    for e in entries:
        category = e.get("category") or "Unknown"
        domain = e.get("domain") or "Unclassified"
        subdomain = e.get("subdomain") or "General"

        summary.setdefault(category, {}).setdefault(domain, {}).setdefault(subdomain, 0)
        summary[category][domain][subdomain] += 1

    return summary


def main():
    print("=" * 60)
    print("LEP Chat — Legal Catalog Builder")
    print("=" * 60)
    print(f"Project: {PROJECT_ID}")
    print(f"Bucket:  {BUCKET_NAME}")
    print(f"Prefix:  '{PREFIX}'")
    print(f"Started: {datetime.now().isoformat(timespec='seconds')}")
    print("=" * 60)

    storage_client = storage.Client(project=PROJECT_ID)
    firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_ID)

    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = list(bucket.list_blobs(prefix=PREFIX))
    pdf_blobs = [b for b in blobs if b.name.lower().endswith(".pdf")]

    print(f"\nFound {len(pdf_blobs)} PDF file(s). Building catalog entries...\n")

    catalog_ref = firestore_client.collection(FIRESTORE_CATALOG_COLLECTION)

    entries = []
    batch = firestore_client.batch()
    batch_count = 0

    for blob in pdf_blobs:
        entry = parse_catalog_entry(blob.name)
        entry["updated"] = blob.updated.isoformat() if blob.updated else None
        entries.append(entry)

        doc_id = re.sub(r"[^a-zA-Z0-9_]", "_", blob.name)[:1500]  # Firestore doc ID safety
        doc_ref = catalog_ref.document(doc_id)
        batch.set(doc_ref, entry)
        batch_count += 1

        # Firestore batches max out at 500 writes
        if batch_count >= 400:
            batch.commit()
            batch = firestore_client.batch()
            batch_count = 0
            print(f"  ...committed a batch of entries ({len(entries)} total so far)")

    if batch_count > 0:
        batch.commit()

    # Build and store the aggregate domain summary as a single doc for fast lookup
    summary = build_domain_summary(entries)
    firestore_client.collection("catalog_meta").document("domain_summary").set(
        {
            "summary": summary,
            "total_files": len(entries),
            "built_at": firestore.SERVER_TIMESTAMP,
        }
    )

    print(f"\n✅ Catalog built: {len(entries)} entries stored in '{FIRESTORE_CATALOG_COLLECTION}'.")
    print("✅ Domain summary stored in 'catalog_meta/domain_summary'.\n")

    print("--- Domain summary preview ---")
    for category, domains in summary.items():
        total_in_category = sum(sum(subs.values()) for subs in domains.values())
        print(f"\n{category} ({total_in_category} files)")
        for domain, subdomains in sorted(domains.items()):
            total_in_domain = sum(subdomains.values())
            print(f"  └─ {domain} ({total_in_domain} files)")


if __name__ == "__main__":
    main()
