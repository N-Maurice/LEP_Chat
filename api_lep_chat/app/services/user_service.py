"""Business logic for the user's own profile document in Firestore. The uid always
comes from the verified token (CurrentUser), never from the request body."""

from fastapi import Depends, HTTPException, status

from app.core.config import Settings, get_settings
from app.db.firestore_client import get_firestore_client
from app.db.repositories.user_repository import UserRepository
from app.schemas.user import CurrentUser, UserProfileUpdate, UserProfileUpsert


class UserProfileService:
    def __init__(self, user_repo: UserRepository):
        self._users = user_repo

    async def upsert_profile(self, user: CurrentUser, payload: UserProfileUpsert | UserProfileUpdate) -> dict:
        fields = payload.model_dump(exclude_unset=True)
        return await self._users.upsert(user.uid, email=user.email, **fields)

    async def get_profile(self, user: CurrentUser) -> dict:
        profile = await self._users.get(user.uid)
        if profile is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found")
        return profile

    async def search_users(self, user: CurrentUser, query: str) -> list[dict]:
        results = await self._users.search_by_username_prefix(query.lower())
        return [r for r in results if r["uid"] != user.uid]


def get_user_profile_service(settings: Settings = Depends(get_settings)) -> UserProfileService:
    client = get_firestore_client()
    return UserProfileService(UserRepository(client, settings.firestore_users_collection))
