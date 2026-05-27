# ADR 0002: Windows Spike Code Structure

## Status

Accepted for the Windows spike.

## Context

ADR 0001 defines the desktop architecture: Flutter talks to a local FastAPI backend, and the backend owns local RAG, persistence, and model orchestration.

This ADR defines how the Windows spike code should stay organized so the repo remains easy to change while the product shape is still being proven.

The main risk is not a lack of abstraction. The main risk is mixing UI, filesystem access, database work, retrieval, and model calls across boundaries until simple changes require edits everywhere.

## Decision

Keep the Windows spike split into a thin Flutter client and a backend-centered application core.

Flutter code is organized around user-facing features and shared presentation/client helpers:

```text
app/flutter_windows_app/lib/
  app.dart
  main.dart
  features/
    sources/
    chat/
    history/
    settings/
  models/
  services/
  theme/
  widgets/
```

Backend code is organized around HTTP routes, durable schemas/models, and focused service modules:

```text
backend/app/
  main.py
  config.py
  database.py
  models.py
  schemas.py
  routes/
    sources.py
    chat.py
    history.py
    health.py
    models.py
  services/
    source_service.py
    file_scanner.py
    text_extractors.py
    chunker.py
    vector_store.py
    rag_service.py
    ollama_service.py
```

## Responsibility Boundaries

Flutter owns:

- Windows desktop UI composition.
- User interactions and local UI state.
- Source, chat, history, and settings screens.
- Calling the backend through the shared API client.
- Rendering backend responses in a useful way.

Flutter does not own:

- Direct SQLite access.
- Direct ChromaDB access.
- Direct Ollama calls.
- File parsing or chunking.
- Retrieval decisions.

The backend owns:

- HTTP request handling.
- Source registration and indexing.
- Filesystem scanning.
- Text extraction.
- Chunking.
- Embedding generation.
- Vector search.
- Answer generation.
- Chat history persistence.
- Configuration and data directory resolution.

The backend should expose UI-friendly responses, but it should not contain Flutter-specific presentation rules.

## Route And Service Rules

Routes are the HTTP boundary. They should validate inputs, call services, translate expected errors into HTTP responses, and return schemas.

Services contain application behavior. They should be explicit modules with narrow jobs:

- `source_service.py`: source creation, indexing coordination, source listing.
- `file_scanner.py`: supported file discovery.
- `text_extractors.py`: text extraction per supported format.
- `chunker.py`: chunk creation policy.
- `vector_store.py`: ChromaDB reads and writes.
- `rag_service.py`: retrieval and answer workflow.
- `ollama_service.py`: model availability, embeddings, and generation calls.

Shared models and schemas should stay in `models.py` and `schemas.py` until the files become genuinely hard to navigate. Splitting them too early would add indirection without solving a real spike problem.

## API Client Rules

The Flutter API client is the only Flutter layer that knows backend paths and wire formats.

Feature screens should call typed methods on the API client instead of building URLs or parsing raw JSON themselves. This keeps backend API changes localized and prevents transport details from spreading into UI code.

## State Management

The spike should keep state management simple.

Use local widget state or small providers where it keeps a screen readable. Do not introduce a larger state architecture until there is repeated cross-screen state that cannot be handled cleanly through the existing API client and feature pages.

## Testing Expectations

Backend tests should focus on behavior with business risk:

- source indexing
- supported file discovery
- text extraction fallbacks
- chunking behavior
- retrieval request shaping
- chat history storage

Flutter tests should focus on meaningful UI state and rendering decisions:

- loading and error states
- empty states
- source/history/chat response rendering
- settings interactions that affect backend calls

The spike does not need exhaustive test coverage for every widget or route, but changes to shared service behavior should come with focused tests.

## Consequences

Benefits:

- The UI remains easier to iterate on without touching RAG internals.
- Backend behavior can be tested without launching the desktop app.
- File parsing, retrieval, and model calls stay close to the Python ecosystem.
- API changes have one Flutter integration point.
- The structure leaves room for growth without adding heavy layers now.

Tradeoffs:

- The backend becomes the center of gravity for most product behavior.
- Some UI work requires backend endpoint changes before it can be completed.
- The route/service split requires discipline; route files should not accumulate application logic.
- Keeping shared model files together may eventually become too large and need a later split.

## Non-Goals

This ADR does not define:

- A production plugin architecture.
- A domain-driven module layout.
- A full state management framework for Flutter.
- A multi-process indexing worker model.
- A packaging or installer strategy.

Those should be separate decisions if the Windows spike grows in that direction.
