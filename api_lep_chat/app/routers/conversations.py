from fastapi import APIRouter, Depends, status

from app.schemas.conversation import ConversationCreate, ConversationOut, DirectMessageCreate, DirectMessageOut
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.conversation_service import ConversationService, get_conversation_service

router = APIRouter(prefix="/conversations", tags=["conversations"])


@router.post("", response_model=ConversationOut, status_code=status.HTTP_201_CREATED)
async def start_conversation(
    payload: ConversationCreate,
    user: CurrentUser = Depends(get_current_user),
    service: ConversationService = Depends(get_conversation_service),
) -> dict:
    return await service.start_or_get_conversation(user, payload)


@router.get("", response_model=list[ConversationOut])
async def list_conversations(
    user: CurrentUser = Depends(get_current_user),
    service: ConversationService = Depends(get_conversation_service),
) -> list[dict]:
    return await service.list_conversations(user)


@router.get("/{conversation_id}/messages", response_model=list[DirectMessageOut])
async def list_messages(
    conversation_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: ConversationService = Depends(get_conversation_service),
) -> list[dict]:
    return await service.list_messages(user, conversation_id)


@router.post("/{conversation_id}/messages", response_model=DirectMessageOut, status_code=status.HTTP_201_CREATED)
async def send_message(
    conversation_id: str,
    payload: DirectMessageCreate,
    user: CurrentUser = Depends(get_current_user),
    service: ConversationService = Depends(get_conversation_service),
) -> dict:
    return await service.send_message(user, conversation_id, payload)
