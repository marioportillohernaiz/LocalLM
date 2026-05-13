import ollama

from app.config import EMBEDDING_MODEL, LLM_MODEL


class OllamaModelError(RuntimeError):
    def __init__(self, model: str, operation: str, original_error: ollama.ResponseError):
        self.model = model
        self.operation = operation
        self.status_code = original_error.status_code
        self.original_error = original_error.error
        super().__init__(
            f"Ollama {operation} model '{model}' is unavailable: {original_error.error}"
        )


def embed_text(text: str) -> list[float]:
    try:
        response = ollama.embeddings(model=EMBEDDING_MODEL, prompt=text)
    except ollama.ResponseError as exc:
        raise OllamaModelError(EMBEDDING_MODEL, "embedding", exc) from exc
    return response["embedding"]


def generate_answer(prompt: str) -> str:
    try:
        response = ollama.chat(
            model=LLM_MODEL,
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
        raise OllamaModelError(LLM_MODEL, "chat", exc) from exc
    return response["message"]["content"]
