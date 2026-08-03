"""Pure async CRUD for direct-message conversations and their messages subcollection.
No auth/ownership logic here — that belongs in services/conversation_service.py."""

from google.cloud import firestore

MESSAGES_SUBCOLLECTION = "messages"


class ConversationRepository:
    def __init__(self, client: firestore.AsyncClient, collection_name: str):
        self._client = client
        self._collection = client.collection(collection_name)

    async def find_between(self, uid_a: str, uid_b: str) -> dict | None:
        """Conversations store participants sorted so a lookup never has to try both
        orderings — the pair (a, b) and (b, a) are the same document."""
        pair = sorted([uid_a, uid_b])
        query = self._collection.where("participant_uids", "==", pair).limit(1)
        docs = await query.get()
        if not docs:
            return None
        return {"id": docs[0].id, **docs[0].to_dict()}

    async def create(self, uid_a: str, uid_b: str) -> dict:
        doc_ref = self._collection.document()
        payload = {
            "participant_uids": sorted([uid_a, uid_b]),
            "last_message": None,
            "created_at": firestore.SERVER_TIMESTAMP,
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
        await doc_ref.set(payload)
        return await self.get(doc_ref.id)

    async def get(self, conversation_id: str) -> dict | None:
        snapshot = await self._collection.document(conversation_id).get()
        if not snapshot.exists:
            return None
        return {"id": snapshot.id, **snapshot.to_dict()}

    async def list_for_user(self, uid: str) -> list[dict]:
        query = (
            self._collection.where("participant_uids", "array_contains", uid)
            .order_by("updated_at", direction=firestore.Query.DESCENDING)
        )
        docs = await query.get()
        return [{"id": d.id, **d.to_dict()} for d in docs]

    def _messages_ref(self, conversation_id: str):
        return self._collection.document(conversation_id).collection(MESSAGES_SUBCOLLECTION)

    async def add_message(self, conversation_id: str, sender_id: str, content: str) -> dict:
        doc_ref = self._messages_ref(conversation_id).document()
        payload = {"sender_id": sender_id, "content": content, "created_at": firestore.SERVER_TIMESTAMP}
        await doc_ref.set(payload)
        await self._collection.document(conversation_id).update(
            {"last_message": content, "updated_at": firestore.SERVER_TIMESTAMP}
        )
        snapshot = await doc_ref.get()
        return {"id": snapshot.id, "conversation_id": conversation_id, **snapshot.to_dict()}

    async def list_messages(self, conversation_id: str) -> list[dict]:
        query = self._messages_ref(conversation_id).order_by("created_at", direction=firestore.Query.ASCENDING)
        return [{"id": doc.id, "conversation_id": conversation_id, **doc.to_dict()} async for doc in query.stream()]
