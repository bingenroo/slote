# Fix draw + viewport zoom issues

**Date:** 2026-04-11

## Summary

Fixed three interrelated bugs in draw+viewport: zoom snapping to corners instead of finger midpoint, non-drawable dead zones after zooming, and two-finger input incorrectly triggering draw instead of zoom/pan.

## Root cause analysis

### Bug 1: Zoom snaps to corner/edge positions instead of finger midpoint

**File:** `components/viewport/lib/src/zoom_pan/gesture_handler.dart`

In `calculateZoomTransform()`, the focal delta was applied via `result.translate(focalDelta.dx, focalDelta.dy)`. This post-multiplied a translation, applying the delta in **content space** (scaled by the zoom factor), not in **viewport/screen space** where the fingers actually moved.

After `result.multiply(zoomTransform)`, the matrix was `initialTransform * zoomTransform` (a translate-then-scale matrix). Calling `result.translate(fd.dx, fd.dy)` produced `initialTransform * zoomTransform * translate(fd)`, shifting every content point by `fd` before transformation — meaning the viewport-space shift was `newScale * fd` instead of just `fd`.

**Fix:** Extract the translation and scale from the result matrix and rebuild it, applying `focalDelta` in viewport space:

```dart
result.multiply(zoomTransform);
final t = result.getTranslation();
final newScale = result.getMaxScaleOnAxis();
return Matrix4.identity()
  ..translate(t.x + focalDelta.dx, t.y + focalDelta.dy)
  ..scale(newScale);
```

### Bug 2: Non-drawable area after zooming (the "dead zone")

**File:** `components/viewport/lib/src/zoom_pan/zoom_pan_surface.dart`

The widget tree used an `OverflowBox` between the `Transform` and the content:

```
Listener (viewport, translucent)
  SizedBox (viewport size)
    ClipRect
      Transform (_transform)
        OverflowBox (maxHeight: infinity, but own size = viewport)
          ContentMeasurer
            child (DrawCanvas inside SizedBox(3200))
```

Flutter's `RenderBox.hitTest()` calls `size.contains(position)` before forwarding to children. The `OverflowBox` sized itself to **viewport dimensions** (its parent's constraints), but allowed its child to paint at full content size. When zoomed in and panned, the `Transform` inverse mapped a viewport touch coordinate to content space — but this content-space coordinate could exceed the OverflowBox's height (viewport height), causing `size.contains()` to return false. The touch was silently dropped before reaching `DrawCanvas`.

**Example:** Viewport = 500px, zoomed 2x, panned to ty=-600. A touch at viewport y=450 maps to content y=(450+600)/2 = 525, which is outside the OverflowBox's 500px height. DrawCanvas never sees the pointer down.

This also explained **Bug 4** (drawing past non-drawable area works): once a `Listener` captures a pointer via the down event, it continues receiving move/up events even if the finger moves outside the widget. Starting in the hittable area works; starting outside doesn't.

**Fix:** Replaced `OverflowBox` with a custom `_HitTestExpandedBox` widget that overrides `hitTest` to skip the `size.contains` check and always forward to the child. The `ClipRect` above already prevents painting outside the viewport.

### Bug 3: Two-finger input sometimes draws instead of zooming

**File:** `components/draw/lib/src/draw_canvas.dart`

The code had elaborate ghost-touch timers, path-length thresholds, and deferred cancellation that were added in past attempts to fix the issue. This complexity meant in certain timing/interaction scenarios, two-finger gestures could still produce ink. The rule is simple: **2+ pointers = zoom/pan only, never draw.**

**Fix:** Simplified `_handlePointerDown`: when `_activePointers.length > 1`, immediately call `_discardInProgress()` with no ghost timers, no path-length checks, no deferred windows. Removed `_ghostWatchPointerId`, `_ghostMultiTouchTimer`, `_secondaryDownLocal`, path-length constants, and the associated move-event logic for secondary pointers.

### Bug 5: Debug logging

Replaced HTTP-POST `_dbgLog` methods in both `draw_canvas.dart` and `zoom_pan_surface.dart` with lightweight `debugPrint` behind `kDebugMode`, throttled to the first 25 pointer-downs.

## Files changed

- `components/viewport/lib/src/zoom_pan/gesture_handler.dart` — fixed focal delta application in viewport space
- `components/viewport/lib/src/zoom_pan/zoom_pan_surface.dart` — replaced OverflowBox with _HitTestExpandedBox, replaced HTTP debug logs
- `components/draw/lib/src/draw_canvas.dart` — simplified multi-touch to immediate discard, replaced HTTP debug logs
- `components/draw/test/draw_canvas_test.dart` — updated tests for immediate discard behavior
- `components/draw/example/test/widget_test.dart` — added hit-test-after-zoom integration test
- `components/viewport/test/zoom_pan_surface_test.dart` — no changes needed (existing tests pass)
- `components/viewport/test/boundary_manager_test.dart` — no changes needed (existing tests pass)

## Constraints preserved

- One-finger in drawing mode = draw (unchanged)
- Two-finger always = zoom/pan, never draw (enforced strictly)
- Pen/stylus behavior unchanged
- All tests pass
