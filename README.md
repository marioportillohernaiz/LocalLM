<p align="center">
  <img src="docs/screenshots/logo-readme.png" alt="LocalLM logo" width="120" />
</p>

<h1 align="center">LocalLM</h1>

<p align="center">
  A local-first desktop app for asking questions over your own files and folders.
</p>

<p align="center">
  <img alt="Project status" src="https://img.shields.io/badge/status-local%20RAG%20spike-00796B">
  <img alt="Frontend" src="https://img.shields.io/badge/frontend-Flutter-02569B">
  <img alt="Backend" src="https://img.shields.io/badge/backend-FastAPI-009688">
  <img alt="Storage" src="https://img.shields.io/badge/storage-SQLite%20%2B%20ChromaDB-455A64">
  <img alt="Models" src="https://img.shields.io/badge/models-Ollama-111111">
</p>

<p align="center">
  <a href="#screenshots">Screenshots</a> |
  <a href="#features">Features</a> |
  <a href="#install-instructions">Install Instructions</a> |
  <a href="#quick-start">Quick Start</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#api">API</a>
</p>

---

LocalLM indexes labelled local files, retrieves the most relevant chunks, and generates answers with local Ollama models. Your documents stay on your machine: the desktop app talks to a local FastAPI backend, which stores metadata in SQLite and embeddings in ChromaDB. The packaged Windows app stores data under `%LOCALAPPDATA%\LocalLM\data`; the packaged macOS app stores data under `~/Library/Application Support/LocalLM/data`.

## Install Instructions

### Windows

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/marioportillohernaiz/LocalLM/main/install.ps1 | iex
```

### macOS

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/marioportillohernaiz/LocalLM/main/install-macos.sh | bash
```

These install the LocalLM desktop app and local backend for your operating system. Models are not included in the app download; open LocalLM, go to Settings, and download the chat and embedding models you want to use.

## Screenshots

### 1. Add Sources

Add labelled folders or individual files, then index or re-index them locally.

![LocalLM Sources screen](docs/screenshots/01-sources.png)

### 2. Ask Questions

Select one or more source labels and ask questions against the indexed content.

![LocalLM Chat screen](docs/screenshots/02-chat.png)

### 3. Review History

Browse previous questions, answers, labels, and cited source material.

![LocalLM History screen](docs/screenshots/03-history.png)

### 4. Download models

Download your own choice of models, from fast & low memory to high quality and heavier.

![LocalLM Settings screen](docs/screenshots/04-settings.png)

## Features

- Add local folders or individual `.txt`, `.md`, `.pdf`, and `.docx` files.
- Group sources with human-readable labels.
- Index documents locally into SQLite and ChromaDB.
- Ask questions against selected labels.
- Generate answers through a local Ollama model.
- Store and browse chat history.
- Configure the backend URL from the desktop app.

## Architecture

```text
Flutter Windows app
  -> Local FastAPI backend
      -> SQLite metadata and chat history
      -> ChromaDB document chunks and embeddings
      -> Ollama embeddings and answer generation
```

The desktop app handles source selection, labels, questions, and display. The Python backend owns file parsing, chunking, embedding, retrieval, history storage, and LLM calls.

Architecture decisions:

- [ADR 0001: Local RAG Desktop Architecture](docs/architecture-decisions/0001-local-rag-desktop-architecture.md)
- [ADR 0002: Windows Spike Code Structure](docs/architecture-decisions/0002-windows-spike-code-structure.md)
- [ADR 0003: macOS Spike Code Structure](docs/architecture-decisions/0003-macos-spike-code-structure.md)
- [ADR 0004: Flutter Platform Feature Split](docs/architecture-decisions/0004-flutter-platform-feature-split.md)

## Quick Start

### Requirements

- Ollama installed and running: https://ollama.com/download
- Windows 10 or newer, or macOS 12 or newer.

Install models from the LocalLM Settings screen after launching the app.

### Run From Source

These steps are only needed if you want to run the development version from this repository.

Requirements:

- Windows with Flutter desktop support enabled.
- Python 3.11 or newer.
- Ollama installed and running.

### Run The Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe run.py
```

Check the API:

```powershell
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{"status":"ok"}
```

### Run The Desktop App

In a second terminal on Windows:

```powershell
cd app\flutter_windows_app
flutter pub get
flutter run -d windows
```

Or on macOS:

```bash
cd app/flutter_windows_app
flutter pub get
flutter run -d macos
```

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `LOCALLM_DATA_DIR` | Source: `backend/data`; packaged Windows app: `%LOCALAPPDATA%\LocalLM\data`; packaged macOS app: `~/Library/Application Support/LocalLM/data` | SQLite and ChromaDB storage location |
| `LOCALLM_LLM_MODEL` | None | Optional fallback Ollama model used for answers when an API caller does not provide one |
| `LOCALLM_EMBEDDING_MODEL` | None | Optional fallback Ollama model used for embeddings when an API caller does not provide one |
| `LOCALLM_CHUNK_SIZE_CHARS` | `3000` | Maximum chunk size before embedding |
| `LOCALLM_CHUNK_OVERLAP_CHARS` | `400` | Overlap between adjacent chunks |
| `LOCALLM_TOP_K` | `8` | Number of chunks retrieved for each question |

Example:

```powershell
$env:LOCALLM_LLM_MODEL = "qwen3:8b"
$env:LOCALLM_EMBEDDING_MODEL = "mxbai-embed-large"
python run.py
```

To keep source and packaged builds on the same data folder, set `LOCALLM_DATA_DIR` before starting the backend:

Windows:

```powershell
$env:LOCALLM_DATA_DIR = "$env:LOCALAPPDATA\LocalLM\data"
python run.py
```

macOS:

```bash
export LOCALLM_DATA_DIR="$HOME/Library/Application Support/LocalLM/data"
python run.py
```

## API

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Backend health check |
| `GET` | `/sources` | List indexed sources |
| `POST` | `/sources` | Add a labelled file or folder |
| `POST` | `/sources/{source_id}/index` | Index or re-index a source |
| `POST` | `/chat/ask` | Ask a question against selected labels |
| `GET` | `/history` | List saved chat history |

## Repository Layout

```text
backend/                 FastAPI backend and local RAG services
app/flutter_windows_app/ Flutter Windows desktop client
docs/architecture-decisions/
                         Architecture decision records
docs/screenshots/        README logo and screenshots
files/                   Local sample files used during development
```

## Project Status

LocalLM is a working local RAG spike. It is intended to prove the usefulness of answering questions over labelled local folders before adding production packaging, background indexing, richer citations, or advanced retrieval features.
