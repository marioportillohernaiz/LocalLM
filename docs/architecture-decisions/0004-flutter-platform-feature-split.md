# ADR 0004: Flutter Platform Feature Split

## Status

Accepted.

## Context

LocalLM now targets both Windows and macOS from the same Flutter application. The backend, API client, models, and local RAG behavior should stay shared, but the desktop UI should follow platform conventions:

- Windows uses Material widgets.
- macOS uses Cupertino widgets.

Keeping one generic feature page per workflow makes that distinction unclear. A file such as `features/settings/settings_page.dart` does not say whether it is Material, Cupertino, or shared. As more platform-specific UI is added, that ambiguity will make imports harder to reason about and increase the chance of mixing Material and Cupertino concerns inside the same page.

## Decision

Split Flutter app composition by platform at the app-shell level, then split feature pages by platform inside each feature folder.

`main.dart` remains the single Flutter entrypoint. It creates the shared `ProviderScope` and runs `LocalLMApp`.

`app.dart` decides which platform app shell to run:

```text
main.dart
  -> LocalLMApp
      -> LocalLMWindowsApp on Windows
      -> LocalLMMacosApp on macOS
```

The platform app shells live at the top of `lib/`:

```text
lib/
  app.dart
  main.dart
  windows_app.dart
  macos_app.dart
```

`windows_app.dart` owns the Material app shell:

- `MaterialApp`
- Windows theme
- Windows navigation shell
- imports `*_windows_page.dart` feature pages

`macos_app.dart` owns the Cupertino app shell:

- `CupertinoApp`
- macOS theme
- macOS navigation shell
- imports `*_macos_page.dart` feature pages

Platform-specific widgets do not mean platform-specific product behavior. The
Windows and macOS screens should expose the same release workflows unless there
is an explicit product decision to diverge. For example, Settings must show the
same curated LocalLM model catalog on both platforms, even though Windows renders
it with Material widgets and macOS renders it with Cupertino widgets.

Each feature folder contains platform-specific pages side by side:

```text
lib/features/
  sources/
    sources_windows_page.dart
    sources_macos_page.dart
  chat/
    chat_windows_page.dart
    chat_macos_page.dart
  history/
    history_windows_page.dart
    history_macos_page.dart
  settings/
    settings_windows_page.dart
    settings_macos_page.dart
```

Shared non-UI code remains outside the platform page files:

```text
lib/
  models/
  services/
  widgets/
  theme/
```

## Import Rules

`app.dart` may import only the platform app shells and framework primitives needed to choose the platform.

`windows_app.dart` may import Material and Windows feature pages. It should not import Cupertino feature pages.

`macos_app.dart` may import Cupertino and macOS feature pages. It should not import Material feature pages.

Feature pages may import shared models, services, and genuinely platform-neutral widgets. A widget is platform-neutral only if it does not depend on Material or Cupertino presentation APIs.

## Naming Rules

Platform-specific pages must include the platform in the filename:

- Windows: `*_windows_page.dart`
- macOS: `*_macos_page.dart`

Avoid generic names such as `settings_page.dart` for platform-specific UI. Generic names are reserved for genuinely shared abstractions, and those should be rare for visible desktop UI.

## Responsibility Boundaries

Windows feature pages own Material presentation for the workflow. They may use `Scaffold`, Material buttons, Material dialogs, Material text fields, and the Windows visual theme.

macOS feature pages own Cupertino presentation for the workflow. They may use `CupertinoPageScaffold`, `CupertinoButton`, `CupertinoTextField`, `CupertinoAlertDialog`, and the macOS visual theme.

Neither platform feature page should own backend behavior. Both should call shared API client methods and consume shared model classes.

## Visual Consistency Rules

The app should look like LocalLM on every desktop platform, not like a default
framework demo. Platform widgets provide interaction conventions, but the product
palette and information hierarchy stay shared:

- Windows uses Material widgets with `AppPalette`.
- macOS uses Cupertino widgets with `AppPalette`.
- Avoid default Cupertino blue for app chrome, navigation selection, primary
  actions, and repeated feature controls unless a specific control requires the
  native accent color.
- Icons must be real platform icons, not missing-font placeholders. Any
  `CupertinoIcons` usage requires the `cupertino_icons` dependency in
  `pubspec.yaml`.
- Empty states should use feature-specific icons: folders for Sources, chat for
  Chat, and clock/history for History.
- The macOS layout may use Cupertino spacing and controls, but it should preserve
  the same workflow structure as Windows: sidebar navigation, page header,
  primary action area, list/detail content, and empty/error/loading states.

## Release Workflow Parity

Release-only or platform-only controls should be treated as product changes, not
UI implementation details.

- Settings must use the shared model catalog endpoint and show the preset Small,
  Medium, and Large model tiers.
- Settings must not expose a backend URL editor in release UI. The packaged app
  is responsible for launching the local backend.
- Model download and installed-state behavior belongs in shared API/client
  methods; platform pages only choose the visual controls.
- If one platform adds or removes a user-facing workflow, review the matching
  platform page before release.

## Shared Code Rules

Keep these shared:

- `ApiClient`
- Riverpod providers for API configuration
- JSON model classes
- backend endpoint paths and response parsing
- local logo/image primitives if they are framework-neutral

Do not duplicate backend calls just because the UI differs. If Windows and macOS need the same operation, the operation belongs in shared services and the visual interaction belongs in the platform page.

## Migration Path

The intended cleanup is:

1. Rename existing Material feature pages to `*_windows_page.dart`.
2. Move Cupertino feature page implementations from `macos_app.dart` into matching `*_macos_page.dart` files.
3. Update `windows_app.dart` and `macos_app.dart` imports.
4. Keep `app.dart` as the only platform selector.
5. Run `flutter analyze` and `flutter test` after each step.

This can be done incrementally, one feature at a time, as long as `main.dart -> app.dart -> platform app shell -> platform feature pages` remains true.

## Consequences

Benefits:

- The active platform UI is obvious from filenames and imports.
- Material and Cupertino concerns stay separated.
- Shared API/model code remains reusable across desktop platforms.
- Platform-specific UI can evolve without forcing awkward generic widgets.
- `main.dart` and `app.dart` stay small and stable.

Tradeoffs:

- Some feature workflow code will be duplicated between Windows and macOS pages.
- Changes to a shared user flow may require touching both platform pages.
- The app has more files than a single cross-platform Material implementation.
- Reviewers need to check that backend behavior remains in shared services, not platform pages.

## Non-Goals

This ADR does not require:

- Separate Flutter projects per platform.
- Separate backend implementations.
- A complete UI abstraction layer over Material and Cupertino.
- Renaming `app/flutter_windows_app/` immediately.
- Replacing all shared widgets if they are genuinely framework-neutral.
