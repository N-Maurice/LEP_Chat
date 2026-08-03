from datetime import datetime

from pydantic import BaseModel


class CurrentUser(BaseModel):
    """Identity extracted from a verified Firebase ID token."""

    uid: str
    email: str | None = None
    name: str | None = None
    email_verified: bool = False


class UserProfileUpsert(BaseModel):
    """Profile fields collected at signup (email/password or Google), stored in
    Firestore's users collection. Everything but full_name/username is optional
    since Google sign-in supplies far less than the KYC-style signup form does."""

    full_name: str
    username: str
    phone_number: str | None = None
    jurisdiction: str | None = None
    national_id: str | None = None


class UserProfileUpdate(BaseModel):
    full_name: str | None = None
    username: str | None = None
    phone_number: str | None = None
    jurisdiction: str | None = None
    national_id: str | None = None


class PublicUserOut(BaseModel):
    """Minimal public profile shown to other citizens when starting a direct message —
    deliberately excludes phone_number/national_id/jurisdiction."""

    uid: str
    full_name: str
    username: str


class UserProfileOut(BaseModel):
    uid: str
    email: str | None = None
    full_name: str
    username: str
    phone_number: str | None = None
    jurisdiction: str | None = None
    national_id: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
