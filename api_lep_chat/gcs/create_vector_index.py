"""
create_vector_index.py

Creates the vector index on the "embedding" field in the "document_chunks" collection.
Run this once, before running ingest.py.

Setup:
    pip install google-cloud-firestore

Run:
    python create_vector_index.py
"""

from google.cloud import firestore_admin_v1

PROJECT_ID = "lep-chat"
DATABASE_ID = "default"
COLLECTION_GROUP = "document_chunks"
VECTOR_FIELD = "embedding"
DIMENSIONS = 768


def main():
    client = firestore_admin_v1.FirestoreAdminClient()

    parent = (
        f"projects/{PROJECT_ID}/databases/{DATABASE_ID}"
        f"/collectionGroups/{COLLECTION_GROUP}"
    )

    index = firestore_admin_v1.Index(
        query_scope=firestore_admin_v1.Index.QueryScope.COLLECTION,
        fields=[
            firestore_admin_v1.Index.IndexField(
                field_path=VECTOR_FIELD,
                vector_config=firestore_admin_v1.Index.IndexField.VectorConfig(
                    dimension=DIMENSIONS,
                    flat=firestore_admin_v1.Index.IndexField.VectorConfig.FlatIndex(),
                ),
            ),
        ],
    )

    print(f"Creating vector index on '{VECTOR_FIELD}' ({DIMENSIONS} dims) "
          f"in collection '{COLLECTION_GROUP}'...")

    operation = client.create_index(parent=parent, index=index)
    print("Index creation started. Waiting for it to complete (this can take a few minutes)...")

    result = operation.result()
    print("✅ Vector index created successfully:")
    print(result)


if __name__ == "__main__":
    main()
