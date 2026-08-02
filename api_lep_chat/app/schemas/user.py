from pydantic import BaseModel


class CurrentUser(BaseModel):
    """Identity extracted from a verified Firebase ID token."""

    uid: str
    email: str | None = None
    name: str | None = None
    email_verified: bool = False
