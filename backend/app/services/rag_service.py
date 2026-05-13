from app.schemas import SourceCitation
from app.services.ollama_service import generate_answer
from app.services.vector_store import search_chunks


def ask_question(
    question: str,
    labels: list[str],
    llm_model: str | None = None,
) -> dict:
    cleaned_question = question.strip()
    cleaned_labels = [label.strip() for label in labels if label.strip()]
    chunks = search_chunks(cleaned_question, cleaned_labels)

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
