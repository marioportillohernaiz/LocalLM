from fastapi import APIRouter, HTTPException

from app.schemas import (
    ModelCatalogItem,
    ModelListResponse,
    PullModelRequest,
    PullModelResponse,
)
from app.services.ollama_service import (
    OllamaModelError,
    list_available_models_by_capability,
    list_model_catalog,
    pull_catalog_model,
)


router = APIRouter(prefix="/models", tags=["models"])


@router.get("", response_model=ModelListResponse)
def list_models() -> ModelListResponse:
    try:
        return ModelListResponse(**list_available_models_by_capability())
    except Exception as error:
        raise HTTPException(
            status_code=503,
            detail=f"Failed to load Ollama models: {error}",
        ) from error


@router.get("/catalog", response_model=list[ModelCatalogItem])
def get_model_catalog() -> list[dict[str, object]]:
    try:
        return list_model_catalog()
    except Exception as error:
        raise HTTPException(
            status_code=503,
            detail=f"Failed to load Ollama model catalog: {error}",
        ) from error


@router.post("/pull", response_model=PullModelResponse)
def pull_model(payload: PullModelRequest) -> PullModelResponse:
    try:
        model = pull_catalog_model(payload.model)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except OllamaModelError as error:
        raise HTTPException(
            status_code=503,
            detail={
                "message": str(error),
                "model": error.model,
                "operation": error.operation,
                "ollama_status_code": error.status_code,
            },
        ) from error

    return PullModelResponse(model=model, installed=True)
