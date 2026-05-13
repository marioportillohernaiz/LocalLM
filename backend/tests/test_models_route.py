from fastapi.testclient import TestClient

from app.main import app
from app.routes import models
from app.services import ollama_service


client = TestClient(app)


def test_models_route_returns_capability_groups(monkeypatch):
    monkeypatch.setattr(
        models,
        "list_available_models_by_capability",
        lambda: {
            "models": ["qwen2.5:1.5b", "qwen3-embedding:0.6b"],
            "chat_models": ["qwen2.5:1.5b"],
            "embedding_models": ["qwen3-embedding:0.6b"],
        },
    )

    response = client.get("/models")

    assert response.status_code == 200
    assert response.json() == {
        "models": ["qwen2.5:1.5b", "qwen3-embedding:0.6b"],
        "chat_models": ["qwen2.5:1.5b"],
        "embedding_models": ["qwen3-embedding:0.6b"],
    }


def test_model_capabilities_are_split_by_ollama_metadata(monkeypatch):
    monkeypatch.setattr(
        ollama_service.ollama,
        "list",
        lambda: {
            "models": [
                {"model": "qwen2.5:1.5b"},
                {"model": "qwen3-embedding:0.6b"},
            ],
        },
    )

    def show(model: str) -> dict:
        if model == "qwen3-embedding:0.6b":
            return {"capabilities": ["embedding"]}
        return {"capabilities": ["completion"]}

    monkeypatch.setattr(ollama_service.ollama, "show", show)

    result = ollama_service.list_available_models_by_capability()

    assert result["models"] == ["qwen2.5:1.5b", "qwen3-embedding:0.6b"]
    assert result["chat_models"] == ["qwen2.5:1.5b"]
    assert result["embedding_models"] == ["qwen3-embedding:0.6b"]


def test_model_capabilities_fall_back_to_name_hints(monkeypatch):
    monkeypatch.setattr(
        ollama_service.ollama,
        "list",
        lambda: {
            "models": [
                {"model": "llama3.2:latest"},
                {"model": "nomic-embed-text:latest"},
            ],
        },
    )
    monkeypatch.setattr(ollama_service.ollama, "show", lambda model: {})

    result = ollama_service.list_available_models_by_capability()

    assert result["chat_models"] == ["llama3.2:latest"]
    assert result["embedding_models"] == ["nomic-embed-text:latest"]


def test_model_catalog_marks_installed_models(monkeypatch):
    monkeypatch.setattr(
        ollama_service,
        "list_available_models",
        lambda: ["qwen2.5:1.5b", "qwen3-embedding:0.6b"],
    )

    response = client.get("/models/catalog")

    assert response.status_code == 200
    catalog = response.json()
    installed = {item["name"]: item["installed"] for item in catalog}
    assert installed["qwen2.5:1.5b"] is True
    assert installed["qwen3-embedding:0.6b"] is True
    assert installed["qwen2.5:7b"] is False


def test_pull_model_rejects_models_outside_catalog():
    response = client.post("/models/pull", json={"model": "not-a-real-preset"})

    assert response.status_code == 400
    assert response.json()["detail"] == "Model is not in the LocalLM catalog"


def test_pull_model_downloads_catalog_model(monkeypatch):
    pulled_models = []
    monkeypatch.setattr(
        ollama_service.ollama,
        "pull",
        lambda model: pulled_models.append(model),
    )

    response = client.post("/models/pull", json={"model": "qwen2.5:1.5b"})

    assert response.status_code == 200
    assert response.json() == {"model": "qwen2.5:1.5b", "installed": True}
    assert pulled_models == ["qwen2.5:1.5b"]
