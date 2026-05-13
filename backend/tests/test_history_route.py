import json

from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.main import app
from app.models import ChatHistory


client = TestClient(app)


def test_delete_history_item_removes_row():
    db = SessionLocal()
    row = ChatHistory(
        question="Delete test question",
        answer="Delete test answer",
        labels=json.dumps(["Test"]),
        sources=json.dumps([]),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    history_id = row.id
    db.close()

    response = client.delete(f"/history/{history_id}")

    assert response.status_code == 204

    db = SessionLocal()
    try:
        assert db.query(ChatHistory).filter(ChatHistory.id == history_id).first() is None
    finally:
        db.close()


def test_delete_history_item_returns_not_found_for_missing_row():
    response = client.delete("/history/999999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "History item not found"
