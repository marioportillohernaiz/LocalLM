import ollama

from app.config import EMBEDDING_MODEL, LLM_MODEL

_EMBEDDING_MODEL_HINTS = (
    "embed",
    "embedding",
    "nomic-embed",
    "mxbai-embed",
    "bge",
    "e5",
    "minilm",
    "snowflake-arctic-embed",
)

MODEL_CATALOG = (
    {
        "name": "qwen2.5:1.5b",
        "display_name": "Qwen2.5 1.5B",
        "kind": "chat",
        "size_label": "Small",
        "approximate_size": "986MB",
        "description": "Fast local answers for low-memory machines.",
    },
    {
        "name": "qwen3-embedding:0.6b",
        "display_name": "Qwen3 Embedding 0.6B",
        "kind": "embedding",
        "size_label": "Small",
        "approximate_size": "639MB",
        "description": "Compact retrieval model for indexing local files.",
    },
    {
        "name": "qwen2.5:7b",
        "display_name": "Qwen2.5 7B",
        "kind": "chat",
        "size_label": "Medium",
        "approximate_size": "4.7GB",
        "description": "Balanced answer quality for everyday desktop use.",
    },
    {
        "name": "qwen3-embedding:4b",
        "display_name": "Qwen3 Embedding 4B",
        "kind": "embedding",
        "size_label": "Medium",
        "approximate_size": "2.5GB",
        "description": "Stronger retrieval quality with a larger local footprint.",
    },
    {
        "name": "qwen2.5:14b",
        "display_name": "Qwen2.5 14B",
        "kind": "chat",
        "size_label": "Large",
        "approximate_size": "9.0GB",
        "description": "Higher-quality answers for machines with more memory.",
    },
    {
        "name": "qwen3-embedding:8b",
        "display_name": "Qwen3 Embedding 8B",
        "kind": "embedding",
        "size_label": "Large",
        "approximate_size": "4.7GB",
        "description": "Best retrieval tier in this preset catalog.",
    },
)


class OllamaModelError(RuntimeError):
    def __init__(self, model: str, operation: str, original_error: ollama.ResponseError):
        self.model = model
        self.operation = operation
        self.status_code = original_error.status_code
        self.original_error = original_error.error
        super().__init__(
            f"Ollama {operation} model '{model}' is unavailable: {original_error.error}"
        )


def list_available_models() -> list[str]:
    response = ollama.list()
    models = response.get("models", []) if isinstance(response, dict) else response.models

    names: list[str] = []
    for model in models:
        if isinstance(model, dict):
            name = model.get("model") or model.get("name")
        else:
            name = getattr(model, "model", None) or getattr(model, "name", None)
        if isinstance(name, str) and name:
            names.append(name)

    return sorted(set(names), key=str.lower)


def list_available_models_by_capability() -> dict[str, list[str]]:
    names = list_available_models()
    chat_models: list[str] = []
    embedding_models: list[str] = []

    for name in names:
        capabilities = _get_model_capabilities(name)
        if capabilities:
            if "embedding" in capabilities:
                embedding_models.append(name)
            if {"completion", "chat", "generate"} & capabilities:
                chat_models.append(name)
            continue

        if _looks_like_embedding_model(name):
            embedding_models.append(name)
        else:
            chat_models.append(name)

    return {
        "models": names,
        "chat_models": sorted(set(chat_models), key=str.lower),
        "embedding_models": sorted(set(embedding_models), key=str.lower),
    }


def list_model_catalog() -> list[dict[str, object]]:
    installed_models = set(list_available_models())
    return [
        {
            **model,
            "installed": model["name"] in installed_models,
        }
        for model in MODEL_CATALOG
    ]


def pull_catalog_model(model: str) -> str:
    selected_model = _clean_model_name(model)
    catalog_names = {item["name"] for item in MODEL_CATALOG}
    if selected_model not in catalog_names:
        raise ValueError("Model is not in the LocalLM catalog")

    try:
        ollama.pull(selected_model)
    except ollama.ResponseError as exc:
        raise OllamaModelError(selected_model, "download", exc) from exc

    return selected_model


def embed_text(text: str, model: str | None = None) -> list[float]:
    selected_model = _clean_model_name(model) or EMBEDDING_MODEL
    if selected_model is None:
        raise ValueError("An embedding model is required")
    try:
        response = ollama.embeddings(model=selected_model, prompt=text)
    except ollama.ResponseError as exc:
        raise OllamaModelError(selected_model, "embedding", exc) from exc
    return response["embedding"]


def generate_answer(prompt: str, model: str | None = None) -> str:
    selected_model = _clean_model_name(model) or LLM_MODEL
    if selected_model is None:
        raise ValueError("A chat model is required")
    try:
        response = ollama.chat(
            model=selected_model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a local research assistant. Answer only from the provided context.",
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
        )
    except ollama.ResponseError as exc:
        raise OllamaModelError(selected_model, "chat", exc) from exc
    return response["message"]["content"]


def _clean_model_name(model: str | None) -> str | None:
    if model is None:
        return None
    cleaned = model.strip()
    return cleaned or None


def _get_model_capabilities(model: str) -> set[str]:
    try:
        response = ollama.show(model)
    except Exception:
        return set()

    raw_capabilities = _read_field(response, "capabilities")
    if not isinstance(raw_capabilities, list):
        details = _read_field(response, "details")
        raw_capabilities = _read_field(details, "capabilities")

    if not isinstance(raw_capabilities, list):
        return set()

    return {
        capability.lower()
        for capability in raw_capabilities
        if isinstance(capability, str) and capability
    }


def _read_field(value: object, field: str) -> object:
    if isinstance(value, dict):
        return value.get(field)
    return getattr(value, field, None)


def _looks_like_embedding_model(model: str) -> bool:
    normalized = model.lower()
    return any(hint in normalized for hint in _EMBEDDING_MODEL_HINTS)
