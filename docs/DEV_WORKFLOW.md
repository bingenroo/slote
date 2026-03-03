# Development Workflow

This document is the single entry point for day-to-day development: setup, running the app or a component, and what to do before merging.

## Setup once

1. **Clone the repo**
   ```bash
   git clone https://github.com/bingenroo/slote.git
   cd slote
   ```

2. **Flutter**  
   Use Flutter SDK 3.7.2+ (see root [README](../README.md) for details).

3. **Bootstrap dependencies**  
   From the repo root:
   ```bash
   python3 cmd.py bootstrap
   ```
   This runs `flutter pub upgrade` at the repo root (main app) and in each component test app, so dependencies are resolved and upgraded to the latest versions allowed by each `pubspec.yaml`.  
   Alternatively, run `flutter pub upgrade` at root and in any `components/<name>/test` you care about.

## Working on the main app

- **Run the app** (from repo root):
  ```bash
  python3 cmd.py run
  ```
  Or: `flutter run` (same as above; root is the Flutter project).

- **Run tests** (from repo root):
  ```bash
  flutter test
  ```

- **Edit code** in `lib/`, use hot reload as usual.

## Working on a component

- **Run the component’s test app** (from repo root):
  ```bash
  python3 cmd.py component run viewport   # or rich_text, draw, undo_redo
  ```
  Or: `cd components/viewport/test` then `flutter run`.

- **Edit code** in `components/<name>/lib/`; the test app uses it via path dependency. Use hot reload.

- **Run that component’s tests** (from repo root):
  ```bash
  cd components/<name>/test
  flutter test
  ```

## Before merging

1. **Run all tests**
   ```bash
   python3 cmd.py test
   ```
   This runs `flutter test` at repo root and in each component test app (viewport, rich_text, draw, undo_redo). Fix any failures.

2. **Smoke-test in the main app**  
   Run the main app (`python3 cmd.py run`) and use the feature that uses your component (e.g. viewport in a note, drawing, rich text) to confirm nothing is broken.

## Optional: component ownership

To reduce “who do I ask?” and avoid two people changing the same component without coordination, you can maintain a small ownership table (e.g. here or in the README):

| Component      | Primary owner |
|----------------|---------------|
| slote_viewport | (assign)      |
| slote_rich_text| (assign)      |
| slote_draw     | (assign)      |
| slote_undo_redo| (assign)      |
| slote_theme    | (assign)      |
| slote_shared   | (assign)      |

Replace `(assign)` with names or leave as-is until you use it.

## Related docs

- [README](../README.md) – repo structure, cmd.py, getting started  
- [Component Test Platforms](../components/COMPONENT_TEST_PLATFORMS.md) – what each component test app covers  
- [Concurrent Development Guide](CONCURRENT_DEVELOPMENT_GUIDE.md) – branching and merging when several people work in parallel  
