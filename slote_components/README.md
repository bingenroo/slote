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

## Usage

Each package can be used as a path dependency in `pubspec.yaml`:

```yaml
dependencies:
  slote_viewport:
    path: ../slote_components/slote_viewport
  slote_undo_redo:
    path: ../slote_components/slote_undo_redo
  # ... etc
```

## Development

See individual package READMEs for development instructions.

