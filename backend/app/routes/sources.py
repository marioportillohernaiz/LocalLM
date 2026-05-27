from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Source
from app.schemas import (
    CreateSourceRequest,
    IndexSourceRequest,
    IndexSourceResponse,
    SourceResponse,
)
from app.services.source_service import create_source, delete_source_index, index_source


router = APIRouter(prefix="/sources", tags=["sources"])


@router.get("", response_model=list[SourceResponse])
def list_sources(db: Session = Depends(get_db)) -> list[Source]:
    return db.query(Source).order_by(Source.created_at.desc()).all()


@router.post("", response_model=SourceResponse)
def add_source(
    payload: CreateSourceRequest,
    db: Session = Depends(get_db),
) -> Source:
    try:
        return create_source(db, label=payload.label, path=payload.path)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.post("/{source_id}/index", response_model=IndexSourceResponse)
def index_source_route(
    source_id: int,
    payload: IndexSourceRequest | None = None,
    db: Session = Depends(get_db),
) -> dict[str, int]:
    try:
        embedding_model = payload.embedding_model if payload is not None else None
        return index_source(db, source_id, embedding_model=embedding_model)
    except ValueError as error:
        status_code = 404 if "not found" in str(error).lower() else 400
        raise HTTPException(status_code=status_code, detail=str(error)) from error


@router.delete("/{source_id}", status_code=204)
def delete_source_route(
    source_id: int,
    db: Session = Depends(get_db),
) -> None:
    try:
        delete_source_index(db, source_id)
    except ValueError as error:
        status_code = 404 if "not found" in str(error).lower() else 400
        raise HTTPException(status_code=status_code, detail=str(error)) from error
