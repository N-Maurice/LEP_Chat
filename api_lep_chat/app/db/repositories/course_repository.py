"""Pure async CRUD against the generated_courses collection, keyed by track slug — a
cache in front of CourseGeneratorAgent so a course isn't re-synthesized (embedding +
vector search + Gemini call) on every page load."""

from google.cloud import firestore


class CourseRepository:
    def __init__(self, client: firestore.AsyncClient, collection_name: str):
        self._collection = client.collection(collection_name)

    async def get(self, track: str) -> dict | None:
        snapshot = await self._collection.document(track).get()
        if not snapshot.exists:
            return None
        return snapshot.to_dict()

    async def save(self, track: str, course: dict) -> None:
        await self._collection.document(track).set(
            {**course, "generated_at": firestore.SERVER_TIMESTAMP}
        )
