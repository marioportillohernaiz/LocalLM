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
    embedding_model: str | None = None

    class Config:
        orm_mode = True
        from_attributes = True


class IndexSourceResponse(BaseModel):
    indexed: int
    skipped: int
    failed: int
    empty: int
    total: int


class IndexSourceRequest(BaseModel):
    embedding_model: str | None = None


class AskRequest(BaseModel):
    question: str = Field(min_length=1)
    labels: list[str] = Field(default_factory=list)
    llm_model: str | None = None


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


class ModelListResponse(BaseModel):
    models: list[str]
    chat_models: list[str] = Field(default_factory=list)
    embedding_models: list[str] = Field(default_factory=list)


class ModelCatalogItem(BaseModel):
    name: str
    display_name: str
    kind: str
    size_label: str
    approximate_size: str
    description: str
    installed: bool


class PullModelRequest(BaseModel):
    model: str = Field(min_length=1)


class PullModelResponse(BaseModel):
    model: str
    installed: bool
