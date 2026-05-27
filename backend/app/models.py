from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.database import Base


class Source(Base):
    __tablename__ = "sources"

    id = Column(Integer, primary_key=True, index=True)
    label = Column(String, nullable=False, index=True)
    path = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_indexed_at = Column(DateTime, nullable=True)
    embedding_model = Column(String, nullable=True)

    documents = relationship(
        "Document",
        back_populates="source",
        cascade="all, delete-orphan",
    )


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    source_id = Column(Integer, ForeignKey("sources.id"), nullable=False, index=True)
    file_path = Column(Text, nullable=False, index=True)
    file_name = Column(String, nullable=False)
    file_hash = Column(String, nullable=False, index=True)
    status = Column(String, default="pending", nullable=False, index=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    indexed_at = Column(DateTime, nullable=True)

    source = relationship("Source", back_populates="documents")


class ChatHistory(Base):
    __tablename__ = "chat_history"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    labels = Column(Text, nullable=False, default="[]")
    sources = Column(Text, nullable=False, default="[]")
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
