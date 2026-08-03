from fastapi import APIRouter, Depends, File, UploadFile, status

from app.schemas.case import CaseCreate, CaseOut
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.case_service import CaseService, get_case_service

router = APIRouter(prefix="/cases", tags=["cases"])


@router.post("", response_model=CaseOut, status_code=status.HTTP_201_CREATED)
async def create_case(
    payload: CaseCreate,
    user: CurrentUser = Depends(get_current_user),
    service: CaseService = Depends(get_case_service),
) -> dict:
    return await service.create_case(user, payload)


@router.get("", response_model=list[CaseOut])
async def list_cases(
    user: CurrentUser = Depends(get_current_user),
    service: CaseService = Depends(get_case_service),
) -> list[dict]:
    return await service.list_cases(user)


@router.get("/{case_id}", response_model=CaseOut)
async def get_case(
    case_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: CaseService = Depends(get_case_service),
) -> dict:
    return await service.get_owned_case(user, case_id)


@router.post("/{case_id}/evidence", response_model=CaseOut, status_code=status.HTTP_201_CREATED)
async def upload_evidence(
    case_id: str,
    file: UploadFile = File(...),
    user: CurrentUser = Depends(get_current_user),
    service: CaseService = Depends(get_case_service),
) -> dict:
    return await service.add_evidence(user, case_id, file)
