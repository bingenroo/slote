# Viewport example

Example app for the `viewport` component.

## Purpose

Run and debug viewport/zoom/pan without the full Slote app:

- Zoom in/out (pinch and limits)
- Pan/drag and scroll
- Boundary constraints
- Viewport and content height
- Drawing vs view mode

## Run

```bash
cd components/viewport/example
flutter pub get
flutter run
```

## Features

- **ViewportSurface**: Zoom/pan with scrollbar
- **Scale indicator**: Current zoom level
- **Info bar**: Viewport and content stats

## Tips

1. Use pinch to zoom on touch devices
2. Pan/drag to move content
3. Try min/max zoom boundaries
4. Use the scrollbar to pan
