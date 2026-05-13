from app.config import CHUNK_OVERLAP_CHARS, CHUNK_SIZE_CHARS


def chunk_text(text: str) -> list[str]:
    cleaned = "\n".join(line.strip() for line in text.splitlines() if line.strip())

    if not cleaned:
        return []

    chunks: list[str] = []
    start = 0

    while start < len(cleaned):
        end = min(start + CHUNK_SIZE_CHARS, len(cleaned))
        chunk = cleaned[start:end].strip()

        if chunk:
            chunks.append(chunk)

        if end >= len(cleaned):
            break

        next_start = end - CHUNK_OVERLAP_CHARS
        if next_start <= start:
            next_start = end
        start = next_start

    return chunks
