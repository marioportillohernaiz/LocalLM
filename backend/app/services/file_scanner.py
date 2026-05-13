from pathlib import Path

from app.services.text_extractors import SUPPORTED_EXTENSIONS


def scan_files(source_path: str) -> list[Path]:
    root = Path(source_path).expanduser()

    if not root.exists():
        raise ValueError("Source path does not exist")

    if root.is_file():
        if root.suffix.lower() not in SUPPORTED_EXTENSIONS:
            raise ValueError(f"Unsupported file type: {root.suffix}")
        return [root]

    if not root.is_dir():
        raise ValueError("Source path must be a file or folder")

    files: list[Path] = []
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
            files.append(path)

    return sorted(files, key=lambda item: str(item).lower())
