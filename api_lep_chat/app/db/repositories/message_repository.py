"""Pure async CRUD against the messages subcollection of a chat session. No auth/ownership
logic here — that belongs in services/message_service.py."""

from google.cloud import firestore


class MessageRepository:
    def __init__(self, client: firestore.AsyncClient, sessions_collection: str, messages_subcollection: str):
        self._client = client
        self._sessions_collection = sessions_collection
        self._messages_subcollection = messages_subcollection

    def _messages_ref(self, session_id: str):
        return (
            self._client.collection(self._sessions_collection)
            .document(session_id)
            .collection(self._messages_subcollection)
        )

    async def create(self, session_id: str, role: str, content: str, citations: list[dict] | None = None) -> dict:
        doc_ref = self._messages_ref(session_id).document()
        payload = {
            "role": role,
            "content": content,
            "citations": citations or [],
            "created_at": firestore.SERVER_TIMESTAMP,
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
        await doc_ref.set(payload)
        return await self.get(session_id, doc_ref.id)

    async def get(self, session_id: str, message_id: str) -> dict | None:
        snapshot = await self._messages_ref(session_id).document(message_id).get()
        if not snapshot.exists:
            return None
        return {"id": snapshot.id, "session_id": session_id, **snapshot.to_dict()}

    async def list(self, session_id: str) -> list[dict]:
        query = self._messages_ref(session_id).order_by("created_at", direction=firestore.Query.ASCENDING)
        return [{"id": doc.id, "session_id": session_id, **doc.to_dict()} async for doc in query.stream()]

    async def update(self, session_id: str, message_id: str, content: str) -> dict | None:
        doc_ref = self._messages_ref(session_id).document(message_id)
        snapshot = await doc_ref.get()
        if not snapshot.exists:
            return None
        await doc_ref.update({"content": content, "updated_at": firestore.SERVER_TIMESTAMP})
        return await self.get(session_id, message_id)

    async def delete(self, session_id: str, message_id: str) -> None:
        await self._messages_ref(session_id).document(message_id).delete()

    async def delete_all(self, session_id: str) -> None:
        """Firestore doesn't cascade-delete subcollections, so this batches through
        every message under the session — used when the whole thread is deleted."""
        docs = [doc async for doc in self._messages_ref(session_id).stream()]
        for start in range(0, len(docs), 400):
            batch = self._client.batch()
            for doc in docs[start : start + 400]:
                batch.delete(doc.reference)
            await batch.commit()
