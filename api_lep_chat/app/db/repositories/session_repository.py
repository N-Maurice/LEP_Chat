"""Pure async CRUD against the chat_sessions collection. No auth/ownership logic here —
that belongs in services/session_service.py."""

from google.cloud import firestore


class SessionRepository:
    def __init__(self, client: firestore.AsyncClient, collection_name: str):
        self._collection = client.collection(collection_name)

    async def create(self, user_id: str, title: str) -> dict:
        doc_ref = self._collection.document()
        payload = {
            "user_id": user_id,
            "title": title,
            "created_at": firestore.SERVER_TIMESTAMP,
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
        await doc_ref.set(payload)
        return await self.get(doc_ref.id)

    async def get(self, session_id: str) -> dict | None:
        snapshot = await self._collection.document(session_id).get()
        if not snapshot.exists:
            return None
        return {"id": snapshot.id, **snapshot.to_dict()}

    async def list_by_user(self, user_id: str) -> list[dict]:
        query = self._collection.where("user_id", "==", user_id).order_by(
            "updated_at", direction=firestore.Query.DESCENDING
        )
        return [{"id": doc.id, **doc.to_dict()} async for doc in query.stream()]

    async def update(self, session_id: str, **fields) -> dict | None:
        doc_ref = self._collection.document(session_id)
        snapshot = await doc_ref.get()
        if not snapshot.exists:
            return None
        await doc_ref.update({**fields, "updated_at": firestore.SERVER_TIMESTAMP})
        return await self.get(session_id)

    async def touch(self, session_id: str) -> None:
        await self._collection.document(session_id).update({"updated_at": firestore.SERVER_TIMESTAMP})

    async def delete(self, session_id: str) -> None:
        await self._collection.document(session_id).delete()
