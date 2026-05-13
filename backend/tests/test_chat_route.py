import ollama
from fastapi.testclient import TestClient

from app.main import app
from app.routes import chat
from app.services.ollama_service import OllamaModelError


client = TestClient(app)


def test_ask_returns_service_unavailable_for_missing_ollama_model(monkeypatch):
    def raise_missing_model(
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
