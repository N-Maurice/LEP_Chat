"""Pure async CRUD against the users collection, keyed by Firebase uid. No auth logic
here — that belongs in services/user_service.py."""

from google.cloud import firestore


class UserRepository:
    def __init__(self, client: firestore.AsyncClient, collection_name: str):
        self._collection = client.collection(collection_name)

    async def upsert(self, uid: str, **fields) -> dict:
        doc_ref = self._collection.document(uid)
        snapshot = await doc_ref.get()
        payload = {**fields, "updated_at": firestore.SERVER_TIMESTAMP}
        if not snapshot.exists:
            payload["created_at"] = firestore.SERVER_TIMESTAMP
        await doc_ref.set(payload, merge=True)
        return await self.get(uid)

    async def get(self, uid: str) -> dict | None:
        snapshot = await self._collection.document(uid).get()
        if not snapshot.exists:
            return None
        return {"uid": snapshot.id, **snapshot.to_dict()}

    async def search_by_username_prefix(self, prefix: str, limit: int = 20) -> list[dict]:
        """Prefix search on `username` — Firestore has no full-text search, so this
        is a `[prefix, prefix + \\uf8ff)` range query, the standard workaround."""
        query = (
            self._collection.where("username", ">=", prefix)
            .where("username", "<", prefix + "")
            .limit(limit)
        )
        docs = await query.get()
        return [{"uid": d.id, **d.to_dict()} for d in docs]
