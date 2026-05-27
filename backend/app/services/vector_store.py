import hashlib

import chromadb

from app.config import CHROMA_DIR, TOP_K
from app.services.ollama_service import embed_text


client = chromadb.PersistentClient(path=str(CHROMA_DIR))
LEGACY_COLLECTION_NAME = "local_documents"
COLLECTION_PREFIX = "local_documents_"


def add_chunk(
    chunk_id: str,
    text: str,
    document_id: int,
    source_id: int,
    label: str,
    file_name: str,
    file_path: str,
    chunk_index: int,
    embedding_model: str | None = None,
) -> None:
    if embedding_model is None:
        raise ValueError("An embedding model is required")

    embedding = embed_text(text, model=embedding_model)
    collection = _get_collection(embedding_model)

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
                "embedding_model": embedding_model or "",
            }
        ],
    )


def delete_document_chunks(document_id: int) -> None:
    for collection in _list_document_collections():
        try:
            collection.delete(where={"document_id": document_id})
        except Exception:
            continue


def search_chunks(
    question: str,
    labels: list[str],
    embedding_model: str | None = None,
) -> list[dict]:
    if embedding_model is None:
        raise ValueError("An embedding model is required")

    query_embedding = embed_text(question, model=embedding_model)
    collection = _get_collection(embedding_model)

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


def _get_collection(embedding_model: str):
    digest = hashlib.sha256(embedding_model.encode("utf-8")).hexdigest()[:16]
    return client.get_or_create_collection(name=f"{COLLECTION_PREFIX}{digest}")


def _list_document_collections():
    collections = client.list_collections()
    result = []
    for collection in collections:
        name = collection.name if hasattr(collection, "name") else str(collection)
        if name == LEGACY_COLLECTION_NAME or name.startswith(COLLECTION_PREFIX):
            result.append(client.get_or_create_collection(name=name))
    return result
