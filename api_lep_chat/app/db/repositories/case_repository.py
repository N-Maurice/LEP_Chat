"""Pure async CRUD against the cases collection. Report a Violation is stored here too
(case_type="violation_report"), so citizens track both from the same underlying list."""

import uuid

from google.cloud import firestore


class CaseRepository:
    def __init__(self, client: firestore.AsyncClient, collection_name: str):
        self._collection = client.collection(collection_name)

    async def create(self, user_id: str, **fields) -> dict:
        case_id = str(uuid.uuid4())
        ref = f"LEP-{case_id[:8].upper()}"
        doc = {
            **fields,
            "id": case_id,
            "user_id": user_id,
            "ref": ref,
            "status": "submitted",
            "evidence": [],
            "created_at": firestore.SERVER_TIMESTAMP,
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
        await self._collection.document(case_id).set(doc)
        return await self.get(case_id)

    async def get(self, case_id: str) -> dict | None:
        snapshot = await self._collection.document(case_id).get()
        if not snapshot.exists:
            return None
        return {"id": snapshot.id, **snapshot.to_dict()}

    async def list_by_user(self, user_id: str) -> list[dict]:
        query = self._collection.where("user_id", "==", user_id).order_by(
            "created_at", direction=firestore.Query.DESCENDING
        )
        docs = await query.get()
        return [{"id": d.id, **d.to_dict()} for d in docs]

    async def add_evidence(self, case_id: str, evidence_item: dict) -> dict | None:
        doc_ref = self._collection.document(case_id)
        await doc_ref.update(
            {
                "evidence": firestore.ArrayUnion([evidence_item]),
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )
        return await self.get(case_id)

    async def update_status(self, case_id: str, status: str) -> dict | None:
        await self._collection.document(case_id).update(
            {"status": status, "updated_at": firestore.SERVER_TIMESTAMP}
        )
        return await self.get(case_id)
