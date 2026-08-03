from fastapi import APIRouter, Depends

from app.schemas.auth import MeResponse
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=MeResponse)
async def read_current_user(user: CurrentUser = Depends(get_current_user)) -> MeResponse:
    return MeResponse(user=user)
