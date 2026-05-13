from pathlib import Path
import os


BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = Path(os.getenv("LOCALLM_DATA_DIR", BASE_DIR / "data"))
SQLITE_PATH = DATA_DIR / "app.db"
CHROMA_DIR = DATA_DIR / "chroma"

LLM_MODEL = os.getenv("LOCALLM_LLM_MODEL", "qwen2.5:1.5b")
EMBEDDING_MODEL = os.getenv("LOCALLM_EMBEDDING_MODEL", "qwen3-embedding:0.6b")

CHUNK_SIZE_CHARS = int(os.getenv("LOCALLM_CHUNK_SIZE_CHARS", "3000"))
CHUNK_OVERLAP_CHARS = int(os.getenv("LOCALLM_CHUNK_OVERLAP_CHARS", "400"))
TOP_K = int(os.getenv("LOCALLM_TOP_K", "8"))

DATA_DIR.mkdir(parents=True, exist_ok=True)
CHROMA_DIR.mkdir(parents=True, exist_ok=True)
