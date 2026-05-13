import hashlib
from datetime import datetime
from pathlib import Path

from sqlalchemy.orm import Session

from app.models import Document, Source
from app.services.chunker import chunk_text
from app.services.file_scanner import scan_files
from app.services.text_extractors import extract_text
from app.services.vector_store import add_chunk, delete_document_chunks


def file_hash(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(65536), b""):
            hasher.update(block)
    return hasher.hexdigest()


def create_source(db: Session, label: str, path: str) -> Source:
    cleaned_label = label.strip()
    cleaned_path = str(Path(path.strip()).expanduser())

    if not cleaned_label:
        raise ValueError("Label is required")

    root = Path(cleaned_path)
    if not root.exists():
        raise ValueError("Source path does not exist")

    source = Source(label=cleaned_label, path=cleaned_path)
    db.add(source)
    db.commit()
    db.refresh(source)
    return source


def index_source(
    db: Session,
    source_id: int,
    embedding_model: str | None = None,
) -> dict[str, int]:
    source = db.query(Source).filter(Source.id == source_id).first()

    if source is None:
        raise ValueError("Source not found")

    files = scan_files(source.path)
    indexed_count = 0
    skipped_count = 0
    failed_count = 0
    empty_count = 0

    for file_path in files:
        current_hash = file_hash(file_path)
        file_path_text = str(file_path)

        existing_indexed = (
            db.query(Document)
            .filter(Document.source_id == source.id)
            .filter(Document.file_path == file_path_text)
            .filter(Document.file_hash == current_hash)
            .filter(Document.status.in_(["indexed", "empty"]))
            .first()
        )

        if existing_indexed and not _clean_model_name(embedding_model):
            skipped_count += 1
            continue

        _delete_previous_documents(db, source.id, file_path_text)

        document = Document(
            source_id=source.id,
            file_path=file_path_text,
            file_name=file_path.name,
            file_hash=current_hash,
            status="indexing",
        )
        db.add(document)
        db.commit()
        db.refresh(document)

        try:
            text = extract_text(file_path_text)
            chunks = chunk_text(text)

            if not chunks:
                document.status = "empty"
                document.indexed_at = datetime.utcnow()
                empty_count += 1
            else:
                for chunk_index, chunk in enumerate(chunks):
                    add_chunk(
                        chunk_id=f"doc-{document.id}-chunk-{chunk_index}",
                        text=chunk,
                        document_id=document.id,
                        source_id=source.id,
                        label=source.label,
                        file_name=file_path.name,
                        file_path=file_path_text,
                        chunk_index=chunk_index,
                        embedding_model=embedding_model,
                    )

                document.status = "indexed"
                document.indexed_at = datetime.utcnow()
                indexed_count += 1

        except Exception as error:  # Keep indexing the rest of the source.
            delete_document_chunks(document.id)
            document.status = "failed"
            document.error_message = str(error)
            failed_count += 1

        db.commit()

    source.last_indexed_at = datetime.utcnow()
    db.commit()

    return {
        "indexed": indexed_count,
        "skipped": skipped_count,
        "failed": failed_count,
        "empty": empty_count,
        "total": len(files),
    }


def _delete_previous_documents(db: Session, source_id: int, file_path: str) -> None:
    previous_documents = (
        db.query(Document)
        .filter(Document.source_id == source_id)
        .filter(Document.file_path == file_path)
        .all()
    )

    for document in previous_documents:
        delete_document_chunks(document.id)
        db.delete(document)

    if previous_documents:
        db.commit()


def _clean_model_name(model: str | None) -> str | None:
    if model is None:
        return None
    cleaned = model.strip()
    return cleaned or None
