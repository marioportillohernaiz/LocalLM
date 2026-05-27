import ollama
from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.main import app
from app.models import Source
from app.routes import chat
from app.services import rag_service
from app.services.ollama_service import OllamaModelError


client = TestClient(app)


def test_ask_returns_service_unavailable_for_missing_ollama_model(monkeypatch):
    def raise_missing_model(
        db,
        question: str,
        labels: list[str],
        llm_model: str | None = None,
    ) -> dict:
        raise OllamaModelError(
            "qwen2.5:1.5b",
            "chat",
            ollama.ResponseError("model 'qwen2.5:1.5b' not found", 404),
        )

    monkeypatch.setattr(chat, "ask_question", raise_missing_model)

    response = client.post("/chat/ask", json={"question": "What changed?", "labels": []})

    assert response.status_code == 503
    assert response.json()["detail"] == {
        "message": "Ollama chat model 'qwen2.5:1.5b' is unavailable: model 'qwen2.5:1.5b' not found",
        "model": "qwen2.5:1.5b",
        "operation": "chat",
        "ollama_status_code": 404,
        "hint": "Run `ollama pull qwen2.5:1.5b` or set the matching LOCALLM_*_MODEL environment variable.",
    }


def test_ask_returns_installed_embedding_model_hint(monkeypatch):
    def raise_missing_model(
        db,
        question: str,
        labels: list[str],
        llm_model: str | None = None,
    ) -> dict:
        raise OllamaModelError(
            "qwen3-embedding:0.6b",
            "embedding",
            ollama.ResponseError("model 'qwen3-embedding:0.6b' not found", 404),
        )

    monkeypatch.setattr(chat, "ask_question", raise_missing_model)

    response = client.post("/chat/ask", json={"question": "What changed?", "labels": []})

    assert response.status_code == 503
    assert response.json()["detail"]["model"] == "qwen3-embedding:0.6b"
    assert (
        response.json()["detail"]["hint"]
        == "Run `ollama pull qwen3-embedding:0.6b` or set the matching LOCALLM_*_MODEL environment variable."
    )


def test_ask_uses_source_embedding_model_for_retrieval(monkeypatch):
    db = SessionLocal()
    source = Source(
        label="EmbeddingModelSource",
        path="C:/tmp",
        embedding_model="qwen3-embedding:4b",
    )
    db.add(source)
    db.commit()
    db.close()

    searched_with = {}
    def fake_search_chunks(question, labels, embedding_model=None):
        searched_with["embedding_model"] = embedding_model
        return []

    monkeypatch.setattr(rag_service, "search_chunks", fake_search_chunks)
    monkeypatch.setattr(
        chat,
        "ask_question",
        rag_service.ask_question,
    )

    response = client.post(
        "/chat/ask",
        json={
            "question": "What is indexed?",
            "labels": ["EmbeddingModelSource"],
            "llm_model": "qwen2.5:1.5b",
        },
    )

    assert response.status_code == 200
    assert searched_with["embedding_model"] == "qwen3-embedding:4b"


def test_ask_searches_each_selected_embedding_model(monkeypatch):
    db = SessionLocal()
    db.add(
        Source(
            label="SmallEmbeddingSource",
            path="C:/tmp/small",
            embedding_model="qwen3-embedding:0.6b",
        )
    )
    db.add(
        Source(
            label="LargeEmbeddingSource",
            path="C:/tmp/large",
            embedding_model="qwen3-embedding:4b",
        )
    )
    db.commit()
    db.close()

    searches = []

    def fake_search_chunks(question, labels, embedding_model=None):
        searches.append((labels, embedding_model))
        return []

    monkeypatch.setattr(rag_service, "search_chunks", fake_search_chunks)
    monkeypatch.setattr(chat, "ask_question", rag_service.ask_question)

    response = client.post(
        "/chat/ask",
        json={
            "question": "What is indexed?",
            "labels": ["SmallEmbeddingSource", "LargeEmbeddingSource"],
            "llm_model": "qwen2.5:14b",
        },
    )

    assert response.status_code == 200
    assert (["SmallEmbeddingSource"], "qwen3-embedding:0.6b") in searches
    assert (["LargeEmbeddingSource"], "qwen3-embedding:4b") in searches
