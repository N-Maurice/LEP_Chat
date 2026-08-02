import pytest
from fastapi import HTTPException

from app.schemas.user import UserProfileUpdate, UserProfileUpsert
from app.services.user_service import UserProfileService
from app.tests.conftest import FakeUserRepository


@pytest.fixture
def service() -> UserProfileService:
    return UserProfileService(FakeUserRepository())


async def test_upsert_profile_creates_new_profile(service, current_user):
    profile = await service.upsert_profile(
        current_user,
        UserProfileUpsert(full_name="Jane Doe", username="jdoe", jurisdiction="Rwanda"),
    )
    assert profile["uid"] == current_user.uid
    assert profile["email"] == current_user.email
    assert profile["full_name"] == "Jane Doe"
    assert profile["username"] == "jdoe"
    assert profile["jurisdiction"] == "Rwanda"


async def test_get_profile_raises_404_when_missing(service, current_user):
    with pytest.raises(HTTPException) as exc_info:
        await service.get_profile(current_user)
    assert exc_info.value.status_code == 404


async def test_update_profile_only_touches_provided_fields(service, current_user):
    await service.upsert_profile(
        current_user, UserProfileUpsert(full_name="Jane Doe", username="jdoe", phone_number="+250700000000")
    )

    updated = await service.upsert_profile(current_user, UserProfileUpdate(username="jane_d"))

    assert updated["username"] == "jane_d"
    assert updated["full_name"] == "Jane Doe"
    assert updated["phone_number"] == "+250700000000"
