import chromadb

from app.config import CHROMA_DIR, TOP_K
from app.services.ollama_service import embed_text


client = chromadb.PersistentClient(path=str(CHROMA_DIR))
collection = client.get_or_create_collection(name="local_documents")


def add_chunk(
    chunk_id: str,
    text: str,
    document_id: int,
    source_id: int,
    label: str,
    file_name: str,
    file_path: str,
    chunk_index: int,
) -> None:
    embedding = embed_text(text)

    collection.add(
        ids=[chunk_id],
        embeddings=[embedding],
        documents=[text],
        metadatas=[
            {
                "document_id": document_id,
                "source_id": source_id,
                "label": label,
                "file_name": file_name,
                "file_path": file_path,
                "chunk_index": chunk_index,
            }
        ],
    )


def delete_document_chunks(document_id: int) -> None:
    collection.delete(where={"document_id": document_id})


def search_chunks(question: str, labels: list[str]) -> list[dict]:
    query_embedding = embed_text(question)

    where = None
    if labels:
        where = {"label": {"$in": labels}}

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=TOP_K,
        where=where,
    )

    chunks: list[dict] = []
    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    for text, metadata, distance in zip(documents, metadatas, distances):
        chunks.append(
            {
                "text": text,
                "metadata": metadata,
                "distance": distance,
            }
        )

    return chunks
