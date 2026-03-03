# Slote Components

This repository contains reusable component packages for the Slote application.

## Packages

- **slote_viewport**: Viewport/zoom/pan functionality
- **slote_undo_redo**: Generic undo/redo system
- **slote_rich_text**: Rich text editing (Word-style)
- **slote_draw**: Custom drawing implementation
- **slote_theme**: Theming system
- **slote_shared**: Shared utilities and resources

## Structure

Each package is independent and can be used separately or together. They are designed to be:

- Self-contained
- Reusable
- Testable
- Independently versioned

## Component Test Platforms

Each component now includes a standalone test application in its `test/` directory, enabling independent development and debugging without running the full Slote app.

### Available Test Platforms

- **draw/test/** - Test drawing tools, colors, stroke width, eraser, highlighter
- **rich_text/test/** - Test text editing, formatting toolbar, bold/italic/underline
- **viewport/test/** - Test zoom, pan, scroll, boundary constraints
- **undo_redo/test/** - Test undo/redo operations, state management, history

### Quick Start

To run any component's test app:

```bash
cd components/[component_name]/test
flutter pub get
flutter run
```

### Benefits

- **Faster Development**: Test components in isolation without loading the full app
- **Focused Debugging**: Only the component being developed is active
- **Independent Testing**: Each component can be tested on any platform independently
- **Standard Pattern**: Follows Flutter package conventions (test/ directories)
- **Easy Onboarding**: New developers can test components without understanding the full app

For detailed documentation, see [COMPONENT_TEST_PLATFORMS.md](COMPONENT_TEST_PLATFORMS.md).

## Usage

Each package can be used as a path dependency in `pubspec.yaml`:

```yaml
dependencies:
  slote_viewport:
    path: components/viewport
  slote_undo_redo:
    path: components/undo_redo
  # ... etc
```

## Data Storage

**Note**: These components are database-agnostic and do not include data persistence. The main Slote app (at repo root) uses **Hive** (a lightweight key-value database for Flutter) for local storage of notes and application data.

For information about Hive usage in the main application, see `PRD.md` section 6.4 (Local Storage).

## Development

### Individual Package Development

See individual package READMEs for development instructions.

### Integration Testing

Integration testing (e.g., drawing + text overlay, component interactions) should be done in the main app (repo root) where all components are combined. Component test platforms focus on individual component functionality only.
