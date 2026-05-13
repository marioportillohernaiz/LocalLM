import json

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ChatHistory
from app.schemas import ChatHistoryResponse, SourceCitation


router = APIRouter(prefix="/history", tags=["history"])


@router.get("", response_model=list[ChatHistoryResponse])
def list_history(db: Session = Depends(get_db)) -> list[ChatHistoryResponse]:
    rows = db.query(ChatHistory).order_by(ChatHistory.created_at.desc()).all()

    return [
        ChatHistoryResponse(
            id=row.id,
            question=row.question,
            answer=row.answer,
            labels=_load_labels(row.labels),
            sources=_load_sources(row.sources),
            created_at=row.created_at,
        )
        for row in rows
    ]


def _load_labels(value: str) -> list[str]:
    data = json.loads(value)
    if not isinstance(data, list):
        return []
    return [item for item in data if isinstance(item, str)]


def _load_sources(value: str) -> list[SourceCitation]:
    data = json.loads(value)
    if not isinstance(data, list):
        return []

    sources: list[SourceCitation] = []
    for item in data:
        if not isinstance(item, dict):
            continue
        sources.append(SourceCitation(**item))
    return sources
