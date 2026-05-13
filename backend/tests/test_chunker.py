from app.services.chunker import chunk_text


def test_chunk_text_ignores_empty_input():
    assert chunk_text("\n\n  ") == []


def test_chunk_text_returns_content_chunks():
    chunks = chunk_text("alpha\n\nbeta")
    assert chunks == ["alpha\nbeta"]
