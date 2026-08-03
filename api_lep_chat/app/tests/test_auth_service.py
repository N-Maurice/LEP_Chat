import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from firebase_admin import auth as firebase_auth

from app.services import auth_service


async def test_get_current_user_rejects_missing_credentials():
    with pytest.raises(HTTPException) as exc_info:
        await auth_service.get_current_user(credentials=None)
    assert exc_info.value.status_code == 401


async def test_get_current_user_returns_user_for_valid_token(mocker):
    mocker.patch(
        "app.services.auth_service.verify_id_token",
        return_value={
            "uid": "abc123",
            "email": "user@example.com",
            "name": "Jane Doe",
            "email_verified": True,
        },
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="a-valid-token")

    user = await auth_service.get_current_user(credentials=creds)

    assert user.uid == "abc123"
    assert user.email == "user@example.com"
    assert user.email_verified is True


async def test_get_current_user_rejects_expired_token(mocker):
    mocker.patch(
        "app.services.auth_service.verify_id_token",
        side_effect=firebase_auth.ExpiredIdTokenError("expired", cause=None),
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="expired-token")

    with pytest.raises(HTTPException) as exc_info:
        await auth_service.get_current_user(credentials=creds)
    assert exc_info.value.status_code == 401


async def test_get_current_user_rejects_invalid_token(mocker):
    mocker.patch(
        "app.services.auth_service.verify_id_token",
        side_effect=firebase_auth.InvalidIdTokenError("bad token"),
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="garbage")

    with pytest.raises(HTTPException) as exc_info:
        await auth_service.get_current_user(credentials=creds)
    assert exc_info.value.status_code == 401
