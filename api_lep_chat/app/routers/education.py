from fastapi import APIRouter, Depends, Query

from app.schemas.education import CourseOut, TrackOut
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.course_service import CourseService, get_course_service

router = APIRouter(prefix="/education", tags=["education"])


@router.get("/tracks", response_model=list[TrackOut])
async def list_tracks(
    user: CurrentUser = Depends(get_current_user),
    service: CourseService = Depends(get_course_service),
) -> list[dict]:
    return service.list_tracks()


@router.get("/courses/{track}", response_model=CourseOut)
async def get_course(
    track: str,
    regenerate: bool = Query(False, description="Force regenerating the course instead of using the cache"),
    user: CurrentUser = Depends(get_current_user),
    service: CourseService = Depends(get_course_service),
) -> dict:
    return await service.get_course(track, force_regenerate=regenerate)
