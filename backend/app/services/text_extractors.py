from pathlib import Path

import fitz
from docx import Document as DocxDocument


SUPPORTED_EXTENSIONS = {".txt", ".md", ".pdf", ".docx"}


def extract_text(file_path: str) -> str:
    path = Path(file_path)
    suffix = path.suffix.lower()

    if suffix in {".txt", ".md"}:
        return path.read_text(encoding="utf-8", errors="ignore")

    if suffix == ".pdf":
        return extract_pdf_text(path)

    if suffix == ".docx":
        return extract_docx_text(path)

    raise ValueError(f"Unsupported file type: {suffix}")


def extract_pdf_text(path: Path) -> str:
    parts: list[str] = []
    with fitz.open(path) as document:
        for page_number, page in enumerate(document, start=1):
            text = page.get_text()
            if text.strip():
                parts.append(f"\n\n[Page {page_number}]\n{text}")
    return "".join(parts)


def extract_docx_text(path: Path) -> str:
    document = DocxDocument(path)
    return "\n".join(paragraph.text for paragraph in document.paragraphs if paragraph.text.strip())
