"""Shared test fixtures: in-memory fakes for the repositories/agent so router and service
tests never touch real Firestore or Vertex AI."""

import pytest

from app.agents.legal_research_agent import AgentAnswer
from app.schemas.user import CurrentUser


class FakeSessionRepository:
    def __init__(self):
        self._store: dict[str, dict] = {}
        self._counter = 0

    async def create(self, user_id: str, title: str) -> dict:
        self._counter += 1
        session_id = f"session-{self._counter}"
        doc = {"id": session_id, "user_id": user_id, "title": title, "created_at": None, "updated_at": None}
        self._store[session_id] = doc
        return dict(doc)

    async def get(self, session_id: str) -> dict | None:
        doc = self._store.get(session_id)
        return dict(doc) if doc else None

    async def list_by_user(self, user_id: str) -> list[dict]:
        return [dict(d) for d in self._store.values() if d["user_id"] == user_id]

    async def update(self, session_id: str, **fields) -> dict | None:
        if session_id not in self._store:
            return None
        self._store[session_id].update(fields)
        return dict(self._store[session_id])

    async def touch(self, session_id: str) -> None:
        return None

    async def delete(self, session_id: str) -> None:
        self._store.pop(session_id, None)


class FakeMessageRepository:
    def __init__(self):
        self._store: dict[str, dict[str, dict]] = {}
        self._counter = 0

    async def create(self, session_id: str, role: str, content: str, citations: list[dict] | None = None) -> dict:
        self._counter += 1
        message_id = f"message-{self._counter}"
        doc = {
            "id": message_id,
            "session_id": session_id,
            "role": role,
            "content": content,
            "citations": citations or [],
            "created_at": None,
            "updated_at": None,
        }
        self._store.setdefault(session_id, {})[message_id] = doc
        return dict(doc)

    async def get(self, session_id: str, message_id: str) -> dict | None:
        doc = self._store.get(session_id, {}).get(message_id)
        return dict(doc) if doc else None

    async def list(self, session_id: str) -> list[dict]:
        return [dict(d) for d in self._store.get(session_id, {}).values()]

    async def update(self, session_id: str, message_id: str, content: str) -> dict | None:
        doc = self._store.get(session_id, {}).get(message_id)
        if doc is None:
            return None
        doc["content"] = content
        return dict(doc)

    async def delete(self, session_id: str, message_id: str) -> None:
        self._store.get(session_id, {}).pop(message_id, None)

    async def delete_all(self, session_id: str) -> None:
        self._store.pop(session_id, None)


class FakeAgent:
    def __init__(self):
        self.calls: list[str] = []

    async def answer(self, question: str) -> AgentAnswer:
        self.calls.append(question)
        return AgentAnswer(
            content=f"Answer to: {question} [Source 1]",
            citations=[
                {
                    "source": "fake_law.pdf",
                    "law_number": "1",
                    "law_year": "2020",
                    "gcs_path": "fake/fake_law.pdf",
                    "domain": "Tax",
                }
            ],
        )


@pytest.fixture
def current_user() -> CurrentUser:
    return CurrentUser(uid="user-1", email="user1@example.com", name="User One", email_verified=True)
