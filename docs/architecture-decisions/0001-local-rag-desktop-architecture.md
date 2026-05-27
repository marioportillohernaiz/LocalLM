# ADR 0001: Local RAG Desktop Architecture

## Status

Accepted for the Windows spike.

## Context

LocalLM is a local-first Windows desktop spike for asking questions over labelled local files and folders. The goal is to prove whether retrieval-augmented generation over personal documents is useful enough to justify further product work.

The spike needs to:

- Add local folders or individual files.
- Assign human-readable labels to sources.
- Index supported files locally.
- Ask questions from a chat UI.
- Generate answers from retrieved local file chunks.
- Show which files were used as sources.
- Keep user documents and derived data on the user's Windows machine.

This decision is scoped to Windows.

## Decision

Use a Flutter Windows desktop app as the client, a local Python FastAPI backend for file processing and RAG orchestration, SQLite for metadata and chat history, ChromaDB for vector storage, and Ollama for local embedding and answer generation models.

The root `README.md` is public new-user documentation only. It should help someone understand what LocalLM is, see screenshots, install the app, run it locally, and understand the high-level architecture. It must not contain private maintainer workflows such as how to build release packages, publish GitHub releases, push tags, upload assets, or otherwise ship code. Those instructions belong in maintainer-only documentation, scripts, or automation notes outside the root README.

```text
Flutter Windows app
  -> calls local FastAPI backend

FastAPI local backend
  -> source management
  -> file scanning
  -> text extraction
  -> chunking
  -> embedding generation
  -> vector search
  -> answer generation
  -> chat history

Local storage
  -> SQLite: sources, files, labels, metadata, history
  -> ChromaDB: text chunks and embeddings

Ollama
  -> answer model
  -> embedding model
```

## Technology Choices

The Windows app is built with Flutter because it gives us a native desktop target, a productive UI framework, and enough platform integration for selecting local folders and files.

The local backend is built with FastAPI because Python has mature libraries for document parsing, embeddings, local AI orchestration, and vector storage. Keeping this logic out of Flutter keeps the UI thin and avoids pushing RAG-specific complexity into the client.

SQLite stores durable relational state: sources, files, labels, indexing status, and chat history. ChromaDB stores chunk text, embeddings, and retrieval metadata. The two stores have different jobs and should not be collapsed during the spike.

Ollama runs the local models. The answer-generating model and embedding model are separate responsibilities:

- Answer model: generates natural-language answers from retrieved context.
- Embedding model: converts file chunks and questions into vectors for semantic search.

The default Windows data location for packaged builds is:

```text
%LOCALAPPDATA%\LocalLM\data
```

## Supported File Types

The spike supports a narrow set of common document formats:

- `.txt`
- `.md`
- `.pdf`
- `.docx`

PDF extraction is handled by PyMuPDF, Word document extraction by `python-docx`, and plain text formats by native text reading.

## Data Flow

Indexing flow:

```text
User selects a folder or file in Flutter
  -> Flutter sends path and label to FastAPI
  -> FastAPI stores the source in SQLite
  -> FastAPI scans supported files
  -> text is extracted
  -> text is split into chunks
  -> chunks are embedded with Ollama
  -> chunks and embeddings are stored in ChromaDB
  -> file metadata and index status are stored in SQLite
```

Question flow:

```text
User asks a question in Flutter
  -> Flutter sends question and selected labels to FastAPI
  -> FastAPI embeds the question with Ollama
  -> ChromaDB retrieves relevant chunks
  -> FastAPI builds the answer context
  -> Ollama generates the answer
  -> FastAPI stores the chat entry
  -> FastAPI returns answer and source references
  -> Flutter displays the answer and source files
```

## API Contract

The Windows app talks to the local backend over HTTP.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Check backend availability |
| `GET` | `/sources` | List indexed sources |
| `POST` | `/sources` | Add a labelled file or folder |
| `POST` | `/sources/{source_id}/index` | Index or re-index a source |
| `POST` | `/chat/ask` | Ask a question against selected labels |
| `GET` | `/history` | List saved chat history |

## Consequences

Benefits:

- User files stay local to the Windows machine.
- The UI remains focused on source selection, chat, history, and settings.
- Python owns parsing, retrieval, model calls, and storage where the ecosystem is strongest.
- The backend API creates a clear boundary between desktop UX and local AI services.
- SQLite and ChromaDB can evolve independently as metadata and retrieval needs change.

Tradeoffs:

- The app depends on a local backend process being available.
- Ollama must be installed and models must be present before useful answers can be generated.
- Local model performance depends heavily on the user's Windows hardware.
- Retrieval quality depends on chunking, embedding model choice, and file extraction quality.

## Non-Goals

This Windows spike does not attempt to solve:

- Cloud sync or multi-device state.
- Remote document storage.
- Background indexing at production scale.
- Fine-grained citation highlighting.
- User authentication.
- Enterprise deployment.
- Non-Windows architecture.

## Later Improvements

Potential follow-up decisions:

- Background indexing and cancellation.
- Better indexing status and failure recovery.
- Richer citation snippets.
- Configurable retrieval settings.
- Model download and validation flows.
- Signed Windows packaging and auto-update strategy.
