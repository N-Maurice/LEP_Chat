import pytest
from fastapi import HTTPException

from app.services.course_service import CourseService
from app.tests.conftest import FakeCourseAgent, FakeCourseRepository


@pytest.fixture
def wiring():
    repo = FakeCourseRepository()
    agent = FakeCourseAgent()
    return CourseService(repo, agent), repo, agent


async def test_list_tracks_returns_the_four_fixed_tracks(wiring):
    service, _, _ = wiring
    tracks = service.list_tracks()
    assert {t["slug"] for t in tracks} == {"labour-law-101", "business-compliance", "family-law", "land-rights"}


async def test_get_course_generates_on_first_call(wiring):
    service, _, agent = wiring
    course = await service.get_course("labour-law-101")
    assert course["track"] == "labour-law-101"
    assert len(course["modules"]) == 5
    assert agent.calls == ["labour-law-101"]


async def test_get_course_serves_from_cache_on_second_call(wiring):
    service, _, agent = wiring
    await service.get_course("labour-law-101")
    await service.get_course("labour-law-101")
    assert agent.calls == ["labour-law-101"]  # generated only once


async def test_get_course_force_regenerate_bypasses_cache(wiring):
    service, _, agent = wiring
    await service.get_course("labour-law-101")
    await service.get_course("labour-law-101", force_regenerate=True)
    assert agent.calls == ["labour-law-101", "labour-law-101"]


async def test_get_course_rejects_unknown_track(wiring):
    service, _, _ = wiring
    with pytest.raises(HTTPException) as exc_info:
        await service.get_course("not-a-real-track")
    assert exc_info.value.status_code == 404
