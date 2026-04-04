# draw

Custom drawing for Slote (`package:draw`). Public API: [`lib/draw.dart`](lib/draw.dart).

**Engineering roadmap:** [docs/ROADMAP.md](docs/ROADMAP.md) — waves A–G, **`package:viewport`** (**`ZoomPanSurface`**, Wave G note shell), `perfect_freehand`, gestures, erasure, ink undo/redo vs AppFlowy history.

## Getting started

- **Isolated loop:** `cd components/draw/example` → `flutter pub get` → `flutter run`.
- **Main app:** root [`pubspec.yaml`](../pubspec.yaml) depends on this package via `path: components/draw`; note screen uses `DrawController` / `SloteDrawScaffold` (see roadmap touchpoints).

For general Flutter setup, see [Flutter documentation](https://docs.flutter.dev/).
