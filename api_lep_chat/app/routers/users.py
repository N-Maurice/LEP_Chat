from fastapi import APIRouter, Depends, status

from app.schemas.user import CurrentUser, UserProfileOut, UserProfileUpdate, UserProfileUpsert
from app.services.auth_service import get_current_user
from app.services.user_service import UserProfileService, get_user_profile_service

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/me", response_model=UserProfileOut, status_code=status.HTTP_201_CREATED)
async def upsert_my_profile(
    payload: UserProfileUpsert,
    user: CurrentUser = Depends(get_current_user),
    service: UserProfileService = Depends(get_user_profile_service),
) -> dict:
    """Called right after Firebase account creation (email/password or Google) to
    store the profile fields collected at signup in Firestore."""
    return await service.upsert_profile(user, payload)


@router.get("/me", response_model=UserProfileOut)
async def read_my_profile(
    user: CurrentUser = Depends(get_current_user),
    service: UserProfileService = Depends(get_user_profile_service),
) -> dict:
    return await service.get_profile(user)


@router.patch("/me", response_model=UserProfileOut)
async def update_my_profile(
    payload: UserProfileUpdate,
    user: CurrentUser = Depends(get_current_user),
    service: UserProfileService = Depends(get_user_profile_service),
) -> dict:
    return await service.upsert_profile(user, payload)
