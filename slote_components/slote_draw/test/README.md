# Slote Draw Test

Standalone test app for the `slote_draw` component.

## Purpose

This test app allows you to test and debug the drawing functionality independently without running the full Slote app. It provides a focused environment for:

- Testing drawing tools (pen, eraser, highlighter)
- Testing color selection
- Testing stroke width adjustment
- Testing canvas interactions
- Debugging drawing performance

## Running the Test App

```bash
cd slote_components/slote_draw/test
flutter pub get
flutter run
```

## Features

- **Pen Tool**: Draw with customizable color and stroke width
- **Highlighter Tool**: Draw with semi-transparent strokes
- **Eraser Tool**: Remove drawing strokes
- **Color Picker**: Select from predefined colors
- **Stroke Width Slider**: Adjust stroke width from 1px to 20px
- **Clear Canvas**: Remove all strokes
- **Drawing Mode Toggle**: Switch between drawing and view mode

## Testing Tips

1. Test different stroke widths to ensure smooth rendering
2. Test color changes during active drawing
3. Test tool switching mid-drawing
4. Test eraser functionality with different stroke widths
5. Test highlighter opacity behavior
6. Monitor performance with many strokes
