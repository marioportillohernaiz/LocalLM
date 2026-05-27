from collections.abc import Generator

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.config import SQLITE_PATH


engine = create_engine(
    f"sqlite:///{SQLITE_PATH}",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema() -> None:
    inspector = inspect(engine)
    if "sources" not in inspector.get_table_names():
        return

    source_columns = {column["name"] for column in inspector.get_columns("sources")}
    if "embedding_model" not in source_columns:
        with engine.begin() as connection:
            connection.execute(text("ALTER TABLE sources ADD COLUMN embedding_model VARCHAR"))
