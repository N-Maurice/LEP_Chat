# test_connection.py
# Quick sanity check: confirms ADC auth, GCS bucket access, and Vertex AI (Agent Platform) access.
# Run with: python test_connection.py

# ---- EDIT THESE THREE VALUES ----
PROJECT_ID = "lep-chat"           # your GCP project ID
BUCKET_NAME = "lep_chat_case_documents_gcs" 
LOCATION = "us-central1"          # or europe-west1, wherever your Vertex AI resources are
# ----------------------------------


def test_storage():
    print("\n--- Testing Cloud Storage access ---")
    try:
        from google.cloud import storage

        client = storage.Client(project=PROJECT_ID)
        bucket = client.bucket(BUCKET_NAME)

        if not bucket.exists():
            print(f'❌ Bucket "{BUCKET_NAME}" not found or not accessible.')
            return False
        print(f'✅ Bucket "{BUCKET_NAME}" found.')

        blobs = list(client.list_blobs(BUCKET_NAME, max_results=5))
        print(f"✅ Successfully listed files. Found {len(blobs)} (showing up to 5):")
        for blob in blobs:
            print(f"   - {blob.name}")

        return True
    except Exception as e:
        print("❌ Storage access failed:", e)
        return False


def test_vertex_ai():
    print("\n--- Testing Vertex AI (Agent Platform) access ---")
    try:
        import vertexai
        from vertexai.generative_models import GenerativeModel

        vertexai.init(project=PROJECT_ID, location=LOCATION)
        model = GenerativeModel("gemini-2.5-flash")

        response = model.generate_content(
            'Say "connection successful" and nothing else.'
        )
        print("✅ Vertex AI responded:", response.text.strip())
        return True
    except Exception as e:
        print("❌ Vertex AI access failed:", e)
        return False


def main():
    print(f"Testing project: {PROJECT_ID}")
    storage_ok = test_storage()
    vertex_ok = test_vertex_ai()

    print("\n--- Summary ---")
    print("Storage:", "✅ OK" if storage_ok else "❌ FAILED")
    print("Vertex AI:", "✅ OK" if vertex_ok else "❌ FAILED")

    if storage_ok and vertex_ok:
        print("\n🎉 Everything is wired up correctly. Ready to build the real pipeline.")
    else:
        print("\n⚠️  Fix the failures above before building on top of this.")


if __name__ == "__main__":
    main()
