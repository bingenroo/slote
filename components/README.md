# Slote Components

This repository contains reusable component packages for the Slote application.

## Packages

- **viewport**: Viewport/zoom/pan functionality
- **undo_redo**: Generic undo/redo for plain text fields — **root app no longer depends on it**; **`example/`** remains for demos (optional package deletion — see `rich_text/docs/ROADMAP.md`)
- **rich_text**: Rich text (**AppFlowy Editor**, Document JSON); **`lib/`** is the public API; main app note body uses it from `lib/src/views/create_note.dart`; **`example/`** for experiments — see `rich_text/docs/ROADMAP.md`
- **draw**: Custom drawing implementation
- **theme**: Theming system
- **shared**: Shared utilities and resources

## Structure

Each package is independent and can be used separately or together. They are designed to be:

- Self-contained
- Reusable
- Testable
- Independently versioned

## Component example apps

Each component includes a standalone **example app** in its `example/` directory for developing and trying the component without running the full Slote app.

### Available example apps

- **draw/example/** – Drawing tools, colors, stroke width, eraser, highlighter
- **rich_text/example/** – AppFlowy editor spike (JSON, BIUS toolbar); roadmap: `rich_text/docs/ROADMAP.md`
- **viewport/example/** – Zoom, pan, scroll, boundary constraints
- **undo_redo/example/** – Standalone plain-text undo demo (not used by root app)

### Quick start

To run any component’s example app:

```bash
cd components/[component_name]/example
flutter pub get
flutter run
```

### Benefits

- **Faster development**: Try components in isolation
- **Focused debugging**: Only the component you’re working on is active
- **Platform flexibility**: Run each example on any supported platform
- **Convention**: Matches Flutter’s `example/` directory convention
- **Onboarding**: New developers can try components without the full app

For full details, see [COMPONENT_TEST_PLATFORMS.md](COMPONENT_TEST_PLATFORMS.md) (component example apps).

## Usage

Each package can be used as a path dependency in `pubspec.yaml`:

```yaml
dependencies:
  viewport:
    path: components/viewport
  rich_text:
    path: components/rich_text
  # ... etc
```

## Data Storage

**Note**: These components are database-agnostic and do not include data persistence. The main Slote app (at repo root) uses **SQLite** (`sqflite`) for local note storage.

For information about Hive usage in the main application, see `PRD.md` section 6.4 (Local Storage).

## Development

### Individual Package Development

See individual package READMEs for development instructions.

### Integration Testing

Integration testing (e.g., drawing + text overlay, component interactions) should be done in the main app (repo root) where all components are combined. Component example apps focus on individual component functionality only.
