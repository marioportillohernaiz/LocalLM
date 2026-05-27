# ADR 0003: macOS Spike Code Structure

## Status

Accepted for macOS spike.

## Context

ADR 0001 and ADR 0002 define the spike architecture and code structure. The macOS spike should keep the same local-first product boundary: a Flutter desktop client talks to a local FastAPI backend, while the backend owns file processing, retrieval, persistence, and Ollama integration.

The macOS spike should not fork the backend architecture. The main difference is the desktop client presentation layer. On macOS, the app should feel native to the platform, so the Flutter UI should use Cupertino widgets and macOS-appropriate interaction patterns wherever practical.

## Decision

Keep the macOS spike split into a Cupertino-first Flutter client and the same backend-centered application core.

The Flutter client should keep the same feature-oriented structure:

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

The app directory name currently reflects the original Windows spike. For the macOS spike, avoid a broad rename until there is a dedicated platform split or packaging reason. Renaming the app folder would create churn without improving the architecture.

Backend code remains shared:

```text
backend/app/
  main.py
  config.py
  database.py
  models.py
  schemas.py
  routes/
  services/
```

## Cupertino UI Direction

macOS Flutter screens should prefer Cupertino widgets for visible controls and navigation:

- `CupertinoApp` or a platform-aware app shell where the macOS path is Cupertino-first.
- `CupertinoPageScaffold` for screen structure.
- `CupertinoNavigationBar` or a Mac-appropriate top-level navigation pattern.
- `CupertinoButton` for primary and secondary actions.
- `CupertinoTextField` for question input, settings fields, and lightweight forms.
- `CupertinoSwitch` for binary settings.
- `CupertinoActivityIndicator` for loading states.
- `CupertinoAlertDialog` for confirmation and error dialogs.

Use Material widgets only when Flutter does not provide a reasonable Cupertino equivalent or when an existing shared widget would become materially worse from a forced rewrite. Those exceptions should stay local and visible.

## Responsibility Boundaries

The macOS Flutter client owns:

- macOS desktop UI composition.
- Cupertino-first user interactions and presentation.
- Source, chat, history, and settings screens.
- Calling the backend through the shared API client.
- Rendering backend responses in a platform-appropriate way.

The macOS Flutter client does not own:

- Direct SQLite access.
- Direct ChromaDB access.
- Direct Ollama calls.
- File parsing or chunking.
- Retrieval decisions.

The backend owns the same responsibilities as the Windows spike:

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

## Shared Code Rules

Keep backend behavior shared between Windows and macOS unless there is a concrete platform-specific requirement.

Keep Flutter models and API client methods shared where the backend contract is identical. Platform-specific UI should sit at the screen/widget layer, not inside the API client or model classes.

If platform branching becomes necessary, prefer small platform-aware composition points over duplicating entire features. For example, a shared `ChatResponse` model and API method can feed different Windows and macOS chat views.

## macOS Data And Packaging Assumptions

The packaged macOS app stores local data under:

```text
~/Library/Application Support/LocalLM/data
```

The macOS package should continue to include a launcher flow that starts the local backend before opening the desktop app. The UI should treat backend startup as a recoverable state and show a clear loading or error state instead of assuming the API is already available.

## State Management

Use the same state-management discipline as the Windows spike.

Keep state local to screens unless it is genuinely shared. Use small providers only where they simplify API client access or repeated UI state. Do not introduce a larger state architecture solely because the macOS UI uses Cupertino widgets.

## Testing Expectations

Backend tests should remain platform-neutral wherever possible.

macOS Flutter tests should focus on:

- Cupertino loading, empty, and error states.
- Source selection and indexing interactions.
- Chat answer and citation rendering.
- History rendering.
- Settings interactions that affect backend calls.

The goal is confidence in platform behavior, not snapshot coverage of every Cupertino control.

## Consequences

Benefits:

- The macOS app can feel native without forking the RAG architecture.
- Backend behavior remains shared and testable.
- API and model code stay stable across desktop platforms.
- Cupertino-specific work stays close to the UI where it belongs.

Tradeoffs:

- Some shared Flutter widgets may need platform-aware variants.
- The existing app directory name remains Windows-oriented until a later restructure.
- Keeping one Flutter app for both platforms requires discipline around platform-specific UI branches.
- Cupertino-first UI may not map perfectly to every existing Material-based interaction.

## Non-Goals

This ADR does not define:

- A full visual redesign.
- A separate macOS-only backend.
- A new repository layout.
- A native Swift or AppKit implementation.
- App signing, notarization, or auto-update strategy.

Those should be separate decisions if the macOS spike moves beyond presentation and packaging work.
