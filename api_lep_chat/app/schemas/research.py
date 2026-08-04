from pydantic import BaseModel


class ResearchResultOut(BaseModel):
    id: str
    institution: str
    tag: str
    title: str
    summary: str
    source: str
    law_number: str | None = None
    law_year: str | None = None
    gcs_path: str | None = None
    domain: str | None = None


class DocumentUrlOut(BaseModel):
    url: str
