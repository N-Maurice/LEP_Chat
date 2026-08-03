from pydantic import BaseModel

from app.schemas.user import CurrentUser


class MeResponse(BaseModel):
    user: CurrentUser
