from fastapi import APIRouter, Depends, status

from app.schemas.message import ChatExchangeOut, MessageCreate, MessageOut, MessageUpdate
from app.schemas.user import CurrentUser
from app.services.auth_service import get_current_user
from app.services.message_service import MessageService, get_message_service

router = APIRouter(prefix="/sessions/{session_id}/messages", tags=["messages"])


@router.post("", response_model=ChatExchangeOut, status_code=status.HTTP_201_CREATED)
async def send_message(
    session_id: str,
    payload: MessageCreate,
    user: CurrentUser = Depends(get_current_user),
    service: MessageService = Depends(get_message_service),
) -> ChatExchangeOut:
    user_message, assistant_message = await service.send_message(user, session_id, payload)
    return ChatExchangeOut(user_message=user_message, assistant_message=assistant_message)


@router.get("", response_model=list[MessageOut])
async def list_messages(
    session_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: MessageService = Depends(get_message_service),
) -> list[dict]:
    return await service.list_messages(user, session_id)


@router.get("/{message_id}", response_model=MessageOut)
async def get_message(
    session_id: str,
    message_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: MessageService = Depends(get_message_service),
) -> dict:
    return await service.get_message(user, session_id, message_id)


@router.patch("/{message_id}", response_model=MessageOut)
async def update_message(
    session_id: str,
    message_id: str,
    payload: MessageUpdate,
    user: CurrentUser = Depends(get_current_user),
    service: MessageService = Depends(get_message_service),
) -> dict:
    return await service.update_message(user, session_id, message_id, payload)


@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    session_id: str,
    message_id: str,
    user: CurrentUser = Depends(get_current_user),
    service: MessageService = Depends(get_message_service),
) -> None:
    await service.delete_message(user, session_id, message_id)
