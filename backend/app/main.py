from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine, ensure_schema
from app.routes import chat, health, history, models, sources


Base.metadata.create_all(bind=engine)
ensure_schema()

app = FastAPI(title="LocalLM")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(sources.router)
app.include_router(chat.router)
app.include_router(history.router)
app.include_router(models.router)
