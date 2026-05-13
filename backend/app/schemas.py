from datetime import datetime

from pydantic import BaseModel, Field


class CreateSourceRequest(BaseModel):
    label: str = Field(min_length=1)
    path: str = Field(min_length=1)


class SourceResponse(BaseModel):
    id: int
    label: str
    path: str
    created_at: datetime
    last_indexed_at: datetime | None = None

    class Config:
        orm_mode = True
        from_attributes = True


class IndexSourceResponse(BaseModel):
    indexed: int
    skipped: int
    failed: int
    empty: int
    total: int


class AskRequest(BaseModel):
    question: str = Field(min_length=1)
    labels: list[str] = Field(default_factory=list)


class SourceCitation(BaseModel):
    file_name: str
    file_path: str
    chunk_text: str


class AskResponse(BaseModel):
    question: str
    answer: str
    sources: list[SourceCitation]


class ChatHistoryResponse(BaseModel):
    id: int
    question: str
    answer: str
    labels: list[str]
    sources: list[SourceCitation]
    created_at: datetime
