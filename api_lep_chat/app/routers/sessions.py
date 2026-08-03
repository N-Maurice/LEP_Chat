from fastapi import APIRouter, Depends, status

from app.schemas.session import SessionCreate, SessionOut, SessionUpdate
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.session_service import SessionService, get_session_service

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("", response_model=SessionOut, status_code=status.HTTP_201_CREATED)
async def create_session(
    payload: SessionCreate,
    user: CurrentUser = Depends(get_current_user),
    service: SessionService = Depends(get_session_service),
) -> dict:
    return await service.create_session(user, payload)


@router.get("", response_model=list[SessionOut])
async def list_sessions(
    user: CurrentUser = Depends(get_current_user),
    service: SessionService = Depends(get_session_service),
) -> list[dict]:
    return await service.list_sessions(user)


@router.get("/{session_id}", response_model=SessionOut)
async def get_session(
    session_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: SessionService = Depends(get_session_service),
) -> dict:
    return await service.get_owned_session(user, session_id)


@router.patch("/{session_id}", response_model=SessionOut)
async def rename_session(
    session_id: str,
    payload: SessionUpdate,
    user: CurrentUser = Depends(get_current_user),
    service: SessionService = Depends(get_session_service),
) -> dict:
    return await service.rename_session(user, session_id, payload)


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: SessionService = Depends(get_session_service),
) -> None:
    await service.delete_session(user, session_id)
