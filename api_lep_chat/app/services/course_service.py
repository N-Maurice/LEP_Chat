"""Serves generated education courses from the Firestore cache when available,
otherwise generates one via CourseGeneratorAgent (embedding + vector search + Gemini)
and persists the result so it isn't regenerated on every page load."""

from fastapi import Depends, HTTPException, status

from app.agents.course_agent import TRACK_LABELS, CourseGeneratorAgent, GeneratedCourse, get_course_generator_agent
from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.course_repository import CourseRepository


class CourseService:
    def __init__(self, course_repo: CourseRepository, agent: CourseGeneratorAgent):
        self._courses = course_repo
        self._agent = agent

    def list_tracks(self) -> list[dict]:
        return [{"slug": slug, "label": label} for slug, label in TRACK_LABELS.items()]

    async def get_course(self, track: str, force_regenerate: bool = False) -> dict:
        if track not in TRACK_LABELS:
            raise HTTPException(status.HTTP_404_NOT_FOUND, f"Unknown track: {track}")

        if not force_regenerate:
            cached = await self._courses.get(track)
            if cached is not None:
                return cached

        generated = await self._agent.generate(track)
        await self._courses.save(track, _course_to_dict(generated))
        saved = await self._courses.get(track)
        return saved if saved is not None else _course_to_dict(generated)


def _course_to_dict(course: GeneratedCourse) -> dict:
    return {
        "track": course.track,
        "title": course.title,
        "description": course.description,
        "modules": [{"title": m.title, "summary": m.summary, "citations": m.citations} for m in course.modules],
    }


def get_course_service(
    settings: Settings = Depends(get_settings),
    agent: CourseGeneratorAgent = Depends(get_course_generator_agent),
) -> CourseService:
    client = get_firestore_client()
    return CourseService(CourseRepository(client, settings.firestore_courses_collection), agent)
