# Component Example Apps

## Overview

This document describes the standalone **example apps** for each component in `components/`. Each example app is a runnable Flutter application that demonstrates and exercises the component in isolation, without running the full Slote app.

## Purpose

Running the full app (at repo root) for component work can mean:

- Unnecessary code and dependencies
- Slower startup times
- More complex debugging
- Harder isolation of component-specific issues

Example apps provide:

- **Faster development**: Work on one component at a time
- **Focused debugging**: Only the component under development is active
- **Platform flexibility**: Run each example on any supported platform
- **Convention**: Matches Flutter/pub convention (`example/` for runnable demos)
- **Onboarding**: New developers can try components without learning the full app

## Architecture

Each component has an **`example/`** directory containing:

- `lib/main.dart` - Entry point and demo screen (single file)
- `pubspec.yaml` - Minimal dependencies (Flutter SDK + parent component)
- `test/widget_test.dart` - Optional widget test for the example app
- `README.md` - How to run the example

### File structure

```
components/
  draw/
    example/
      lib/
        main.dart
      test/
        widget_test.dart
      pubspec.yaml
      README.md
    lib/                    # Component code

  rich_text/
    example/
      lib/main.dart
      test/widget_test.dart
      pubspec.yaml
      README.md
    lib/

  viewport/
    example/
      lib/main.dart
      test/widget_test.dart
      pubspec.yaml
      README.md
      android/   # (viewport example has full platform folders)
      ios/
      ...
    lib/

  undo_redo/
    example/
      lib/main.dart
      test/widget_test.dart
      pubspec.yaml
      README.md
    lib/
```

## Example apps

### 1. Draw example

**Location**: `components/draw/example/`

**Demonstrates**:

- Drawing with pen tool
- Color selection (8 predefined colors)
- Stroke width (1px–20px)
- Eraser and highlighter
- Clear canvas
- Drawing vs view mode
- Stroke rendering

**Run**:

```bash
cd components/draw/example
flutter pub get
flutter run
```

### 2. Rich text example

**Location**: `components/rich_text/example/`

**Demonstrates** (AppFlowy spike):

- `EditorState` + Document JSON load
- `AppFlowyEditor` with BIUS toolbar (`toggleAttribute`)
- Caret-aware format toggle state

**Roadmap**: `components/rich_text/docs/ROADMAP.md`

**Run**:

```bash
cd components/rich_text/example
flutter pub get
flutter run
```

### 3. Viewport example

**Location**: `components/viewport/example/`

**Demonstrates**:

- Zoom (pinch, scale limits)
- Pan/drag and scroll
- Scrollbar
- Boundary behavior
- Content height and viewport stats

**Run**:

```bash
cd components/viewport/example
flutter pub get
flutter run
```

### 4. Undo/redo example

**Location**: `components/undo_redo/example/`

**Note:** Intended for **plain `TextEditingController`** undo. **Planned removal** after the note body uses AppFlowy (`EditorState` history) — see `components/rich_text/docs/ROADMAP.md`.

**Demonstrates**:

- Undo/redo with text editing
- Can undo/redo state
- History clear
- State indicators

**Run**:

```bash
cd components/undo_redo/example
flutter pub get
flutter run
```

## Development workflow

### Running an example

1. Go to the component’s example directory:

   ```bash
   cd components/[component_name]/example
   ```

2. Get dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

4. Edit component code under `../lib/`; the example uses it via the path dependency. Use hot reload/restart to see changes.

### Adding or changing example behavior

- Edit `example/lib/main.dart` (single file: app setup + demo screen).
- Keep the example focused on demonstrating the component’s API and behavior.

## Integration testing

Example apps are for **per-component demos and debugging**. For integration (e.g. drawing + text, multiple components together), use the main app at repo root.

## Dependencies

Each example has minimal dependencies:

- Flutter SDK
- Parent component (`path: ../`)
- `flutter_test` and `flutter_lints` as dev dependencies

### Example pubspec.yaml

```yaml
name: [component]_example
description: Example app for [component] component
publish_to: "none"

version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter
  [component]:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

## Related docs

- Per-component READMEs in each `example/` directory
- Main repo README: `/README.md`
- Component development: `docs/CONCURRENT_DEVELOPMENT_GUIDE.md`
