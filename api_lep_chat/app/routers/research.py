from fastapi import APIRouter, Depends, Query

from app.schemas.research import DocumentUrlOut, ResearchResultOut
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.research_service import ResearchService, get_research_service

router = APIRouter(prefix="/research", tags=["research"])


@router.get("/search", response_model=list[ResearchResultOut])
async def search(
    q: str = Query(min_length=1),
    _user: CurrentUser = Depends(get_current_user),
    service: ResearchService = Depends(get_research_service),
) -> list[ResearchResultOut]:
    return await service.search(q)


@router.get("/documents/url", response_model=DocumentUrlOut)
async def get_document_url(
    gcs_path: str = Query(min_length=1),
    _user: CurrentUser = Depends(get_current_user),
    service: ResearchService = Depends(get_research_service),
) -> DocumentUrlOut:
    return await service.get_document_url(gcs_path)
