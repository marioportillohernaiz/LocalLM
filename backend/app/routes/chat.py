import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ChatHistory
from app.schemas import AskRequest, AskResponse, SourceCitation
from app.services.ollama_service import OllamaModelError
from app.services.rag_service import ask_question


router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/ask", response_model=AskResponse)
def ask(payload: AskRequest, db: Session = Depends(get_db)) -> dict:
    try:
        response = ask_question(payload.question, payload.labels)
    except OllamaModelError as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "message": str(exc),
                "model": exc.model,
                "operation": exc.operation,
                "ollama_status_code": exc.status_code,
                "hint": f"Run `ollama pull {exc.model}` or set the matching LOCALLM_*_MODEL environment variable.",
            },
        ) from exc

    history_item = ChatHistory(
        question=response["question"],
        answer=response["answer"],
        labels=json.dumps([label.strip() for label in payload.labels if label.strip()]),
        sources=json.dumps([_source_to_dict(source) for source in response["sources"]]),
    )
    db.add(history_item)
    db.commit()

    return response


def _source_to_dict(source: SourceCitation) -> dict[str, str]:
    return {
        "file_name": source.file_name,
        "file_path": source.file_path,
        "chunk_text": source.chunk_text,
    }
