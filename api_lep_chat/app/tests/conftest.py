"""Shared test fixtures: in-memory fakes for the repositories/agent so router and service
tests never touch real Firestore or Vertex AI."""

import pytest

from app.agents.course_agent import CourseModule, GeneratedCourse
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
        self.search_calls: list[str] = []

    async def answer(self, question: str) -> AgentAnswer:
        self.calls.append(question)
        return AgentAnswer(
            content=f"Answer to: {question} [Source 1]",
            citations=[
                {
                    "source": "fake_law.pdf",
                    "quote": "This is a fake excerpt of the law text used for testing.",
                    "law_number": "1",
                    "law_year": "2020",
                    "gcs_path": "fake/fake_law.pdf",
                    "domain": "Tax",
                }
            ],
        )

    async def search(self, query: str, limit: int = 10) -> list[dict]:
        self.search_calls.append(query)
        return [
            {
                "gcs_path": "Domestic laws/Laws in force/1. Fundamental/labour_law_n_49_of_2023.pdf",
                "filename": "labour_law_n_49_of_2023.pdf",
                "category": "Domestic laws",
                "domain": "Labour Law",
                "subdomain": "Employment",
                "law_number": "49",
                "law_year": "2023",
                "law_title": None,
                "text": "Article 24: Every employer shall provide written notice before terminating an employment contract.",
            }
        ]


class FakeUserRepository:
    def __init__(self):
        self._store: dict[str, dict] = {}

    async def upsert(self, uid: str, **fields) -> dict:
        existing = self._store.get(uid, {"uid": uid, "created_at": None})
        existing.update(fields)
        existing["uid"] = uid
        existing["updated_at"] = None
        self._store[uid] = existing
        return dict(existing)

    async def get(self, uid: str) -> dict | None:
        doc = self._store.get(uid)
        return dict(doc) if doc else None

    async def search_by_username_prefix(self, prefix: str, limit: int = 20) -> list[dict]:
        return [dict(d) for d in self._store.values() if d.get("username", "").startswith(prefix)][:limit]


class FakeConversationRepository:
    def __init__(self):
        self._conversations: dict[str, dict] = {}
        self._messages: dict[str, dict[str, dict]] = {}
        self._counter = 0

    async def find_between(self, uid_a: str, uid_b: str) -> dict | None:
        pair = sorted([uid_a, uid_b])
        for doc in self._conversations.values():
            if doc["participant_uids"] == pair:
                return dict(doc)
        return None

    async def create(self, uid_a: str, uid_b: str) -> dict:
        self._counter += 1
        conversation_id = f"conversation-{self._counter}"
        doc = {
            "id": conversation_id,
            "participant_uids": sorted([uid_a, uid_b]),
            "last_message": None,
            "created_at": None,
            "updated_at": None,
        }
        self._conversations[conversation_id] = doc
        self._messages[conversation_id] = {}
        return dict(doc)

    async def get(self, conversation_id: str) -> dict | None:
        doc = self._conversations.get(conversation_id)
        return dict(doc) if doc else None

    async def list_for_user(self, uid: str) -> list[dict]:
        return [dict(d) for d in self._conversations.values() if uid in d["participant_uids"]]

    async def add_message(self, conversation_id: str, sender_id: str, content: str) -> dict:
        message_id = f"message-{len(self._messages[conversation_id]) + 1}"
        doc = {"id": message_id, "conversation_id": conversation_id, "sender_id": sender_id, "content": content, "created_at": None}
        self._messages[conversation_id][message_id] = doc
        self._conversations[conversation_id]["last_message"] = content
        return dict(doc)

    async def list_messages(self, conversation_id: str) -> list[dict]:
        return [dict(d) for d in self._messages.get(conversation_id, {}).values()]


class FakeCourseRepository:
    def __init__(self):
        self._store: dict[str, dict] = {}

    async def get(self, track: str) -> dict | None:
        doc = self._store.get(track)
        return dict(doc) if doc else None

    async def save(self, track: str, course: dict) -> None:
        self._store[track] = {**course, "generated_at": None}


class FakeCourseAgent:
    def __init__(self):
        self.calls: list[str] = []

    async def generate(self, track: str) -> GeneratedCourse:
        self.calls.append(track)
        return GeneratedCourse(
            track=track,
            title=f"Generated course for {track}",
            description="A fake generated description.",
            modules=[
                CourseModule(title=f"Module {i}", summary=f"Summary {i}", citations=[])
                for i in range(1, 6)
            ],
        )


class FakeCaseRepository:
    def __init__(self):
        self._store: dict[str, dict] = {}
        self._counter = 0

    async def create(self, user_id: str, **fields) -> dict:
        self._counter += 1
        case_id = f"case-{self._counter}"
        doc = {
            **fields,
            "id": case_id,
            "user_id": user_id,
            "ref": f"LEP-TEST{self._counter}",
            "status": "submitted",
            "evidence": [],
            "created_at": None,
            "updated_at": None,
        }
        self._store[case_id] = doc
        return dict(doc)

    async def get(self, case_id: str) -> dict | None:
        doc = self._store.get(case_id)
        return dict(doc) if doc else None

    async def list_by_user(self, user_id: str) -> list[dict]:
        return [dict(d) for d in self._store.values() if d["user_id"] == user_id]

    async def add_evidence(self, case_id: str, evidence_item: dict) -> dict | None:
        doc = self._store.get(case_id)
        if doc is None:
            return None
        doc["evidence"] = [*doc["evidence"], evidence_item]
        return dict(doc)

    async def update_status(self, case_id: str, status: str) -> dict | None:
        doc = self._store.get(case_id)
        if doc is None:
            return None
        doc["status"] = status
        return dict(doc)


async def _fake_upload_bytes(bucket: str, folder: str, filename: str, content: bytes, content_type: str | None) -> str:
    return f"{folder}/fake-uuid_{filename}"


@pytest.fixture
def current_user() -> CurrentUser:
    return CurrentUser(uid="user-1", email="user1@example.com", name="User One", email_verified=True)
