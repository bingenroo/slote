# Slote Viewport Example

Standalone test app for the `slote_viewport` component.

## Purpose

This example app allows you to test and debug the viewport/zoom/pan functionality independently without running the full Slote app. It provides a focused environment for:

- Testing zoom in/out functionality
- Testing pan/drag gestures
- Testing scroll behavior
- Testing boundary constraints
- Testing viewport height measurement
- Testing content height management
- Testing drawing mode vs view mode

## Running the Example

```bash
cd slote_components/slote_viewport/example
flutter pub get
flutter run
```

## Features

- **Zoom Controls**: Buttons to zoom in/out (also supports pinch gestures)
- **Content Height Controls**: Adjust content height to test scrolling
- **Viewport Surface**: Main viewport widget with zoom/pan capabilities
- **Scale Indicator**: Shows current zoom level
- **Drawing Mode Toggle**: Switch between drawing and view modes
- **Info Bar**: Real-time viewport and content statistics

## Testing Tips

1. Test pinch-to-zoom gestures on touch devices
2. Test pan/drag gestures to move content
3. Test boundary constraints at min/max zoom levels
4. Test content height changes and scrollbar behavior
5. Test viewport height measurement accuracy
6. Test mode switching between drawing and view modes
7. Monitor performance during zoom/pan operations
