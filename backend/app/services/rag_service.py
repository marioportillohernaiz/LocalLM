from app.schemas import SourceCitation
from app.models import Source
from app.services.ollama_service import generate_answer
from app.services.vector_store import search_chunks
from sqlalchemy.orm import Session


def ask_question(
    db: Session,
    question: str,
    labels: list[str],
    llm_model: str | None = None,
) -> dict:
    cleaned_question = question.strip()
    cleaned_labels = [label.strip() for label in labels if label.strip()]
    chunks = _search_chunks_by_embedding_model(db, cleaned_question, cleaned_labels)

    if not chunks:
        return {
            "question": cleaned_question,
            "answer": "I could not find relevant information in the indexed files.",
            "sources": [],
        }

    context_parts: list[str] = []
    sources: list[SourceCitation] = []

    for index, chunk in enumerate(chunks, start=1):
        metadata = chunk["metadata"]
        text = chunk["text"]

        context_parts.append(
            f"[Source {index}]\n"
            f"File: {metadata['file_name']}\n"
            f"Path: {metadata['file_path']}\n"
            f"Content:\n{text}"
        )

        sources.append(
            SourceCitation(
                file_name=metadata["file_name"],
                file_path=metadata["file_path"],
                chunk_text=text[:500],
            )
        )

    prompt = f"""
Use only the context below to answer the question.

If the context does not contain the answer, say:
"I could not find this in the indexed files."

Cite source numbers in the answer where relevant.

Context:
{chr(10).join(context_parts)}

Question:
{cleaned_question}
""".strip()

    answer = generate_answer(prompt, model=llm_model)

    return {
        "question": cleaned_question,
        "answer": answer,
        "sources": sources,
    }


def _search_chunks_by_embedding_model(
    db: Session,
    question: str,
    labels: list[str],
) -> list[dict]:
    query = db.query(Source).filter(Source.embedding_model.isnot(None))
    if labels:
        query = query.filter(Source.label.in_(labels))
    else:
        query = query.filter(Source.last_indexed_at.isnot(None))

    grouped_labels: dict[str, set[str]] = {}
    for source in query.all():
        if not isinstance(source.embedding_model, str):
            continue
        embedding_model = source.embedding_model.strip()
        if not embedding_model:
            continue
        grouped_labels.setdefault(embedding_model, set()).add(source.label)

    if not grouped_labels:
        raise ValueError("Selected sources have not been indexed with an embedding model")

    chunks: list[dict] = []
    for embedding_model, source_labels in grouped_labels.items():
        chunks.extend(search_chunks(question, sorted(source_labels), embedding_model))

    return sorted(chunks, key=lambda chunk: chunk["distance"])
