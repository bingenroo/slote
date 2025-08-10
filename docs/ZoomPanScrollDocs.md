# Zooming/Panning/Scrolling Implimentations

This docs attempts to integrate zooming, panning and scrolling all together. Errors and workarounds are highlighted.

## One

```
// Replace your current InteractiveViewer with this:
class DrawingZoomableArea extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final Function(double) onZoomChanged;

  const DrawingZoomableArea({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.onZoomChanged,
  });

  @override
  State<DrawingZoomableArea> createState() => _DrawingZoomableAreaState();
}

class _DrawingZoomableAreaState extends State<DrawingZoomableArea> {
  final TransformationController _transformController = TransformationController();
  int _pointerCount = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pointerCount++),
      onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.5,
        maxScale: 3.0,
        // Only allow zoom/pan with multiple fingers OR when not drawing
        panEnabled: _pointerCount >= 2 || !widget.isDrawingActive,
        scaleEnabled: _pointerCount >= 2 || !widget.isDrawingActive,
        onInteractionUpdate: (details) {
          final scale = _transformController.value.getMaxScaleOnAxis();
          widget.onZoomChanged(scale);
        },
        child: widget.child,
      ),
    );
  }
}
```

## Two

```
class DrawingZoomableArea extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final Function(double) onZoomChanged;
  final TransformationController transformController;

  const DrawingZoomableArea({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.onZoomChanged,
    required this.transformController,
  });

  @override
  State<DrawingZoomableArea> createState() => _DrawingZoomableAreaState();
}

class _DrawingZoomableAreaState extends State<DrawingZoomableArea> {
  int _pointerCount = 0;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    widget.transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    widget.transformController.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onTransformChanged() {
    final newZoomed = widget.transformController.value.getMaxScaleOnAxis() > 1.0;
    if (newZoomed != _isZoomed) {
      setState(() => _isZoomed = newZoomed);
    }
    widget.onZoomChanged(widget.transformController.value.getMaxScaleOnAxis());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pointerCount++),
      onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
      child: InteractiveViewer(
        transformationController: widget.transformController,
        minScale: 0.5,
        maxScale: 3.0,
        // CRITICAL: Lock all interactions when drawing is active
        panEnabled: !widget.isDrawingActive && (_pointerCount >= 2 || !_isZoomed),
        scaleEnabled: !widget.isDrawingActive && _pointerCount >= 2,
        // Disable all interactions when drawing
        onInteractionStart: (details) {
          if (widget.isDrawingActive) {
            // Cancel any ongoing interactions
            return;
          }
        },
        onInteractionUpdate: (details) {
          // Only allow interactions when not drawing
          if (widget.isDrawingActive) {
            return;
          }
        },
        child: widget.child,
      ),
    );
  }
}
```

## Three

```
class LockedZoomableArea extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final Function(double) onZoomChanged;

  const LockedZoomableArea({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.onZoomChanged,
  });

  @override
  State<LockedZoomableArea> createState() => _LockedZoomableAreaState();
}

class _LockedZoomableAreaState extends State<LockedZoomableArea> {
  final TransformationController _transformController = TransformationController();
  int _pointerCount = 0;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _focalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onTransformChanged() {
    widget.onZoomChanged(_transformController.value.getMaxScaleOnAxis());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pointerCount++),
      onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
      child: GestureDetector(
        // COMPLETELY DISABLE gestures when drawing
        onScaleStart: widget.isDrawingActive ? null : (details) {
          _focalPoint = details.focalPoint;
        },
        onScaleUpdate: widget.isDrawingActive ? null : (details) {
          if (_pointerCount >= 2) {
            // Multi-touch: zoom and pan
            final newScale = (_scale * details.scale).clamp(0.5, 3.0);
            if (newScale != _scale) {
              _scale = newScale;
              _updateTransform();
            }

            // Pan with focal point
            final panDelta = details.focalPoint - _focalPoint;
            _offset += panDelta;
            _focalPoint = details.focalPoint;
            _updateTransform();
          }
        },
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_offset.dx, _offset.dy)
            ..scale(_scale),
          alignment: Alignment.topLeft,
          child: widget.child,
        ),
      ),
    );
  }

  void _updateTransform() {
    final matrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
    _transformController.value = matrix;
  }
}
```

### High-level

- All three solve zoom/pan with different levels of control and integration.
- The main differences are: who owns the `TransformationController`, how drawing lock is enforced, and whether you rely on `InteractiveViewer` vs a fully manual Transform.

### 1) DrawingZoomableArea (internal controller, simple lock)

- Controller: Created and owned internally.
- Engine: Uses `InteractiveViewer`.
- Locking: Pan/scale allowed when 2 fingers OR when not drawing; very simple rule.
- Pros: Minimal code, easy drop-in.
- Cons: Harder to coordinate with outside scroll/other widgets; can’t observe transform from the parent; less nuanced control (e.g., pan rules when zoomed).

### 2) DrawingZoomableArea (external controller, zoom-aware lock)

- Controller: Passed in (parent owns it). Listens to it and reports `onZoomChanged`.
- Engine: Uses `InteractiveViewer`.
- Locking: Disables interactions if drawing; otherwise panEnabled: !drawingActive && (two-fingers OR not zoomed). So 1-finger pan is allowed only when not zoomed; once zoomed, requires 2 fingers.
- Pros: Parent can coordinate pan/zoom with other parts (scrollbars, toolbars, state); better observability; more precise lock logic.
- Cons: Slightly more wiring; still bound by `InteractiveViewer`’s behavior.

### 3) LockedZoomableArea (manual transform via GestureDetector)

- Controller: Internal `TransformationController` only for publishing a matrix; actual pan/zoom is manual with `_scale` + `_offset` and `Transform` widget.
- Engine: Pure `GestureDetector` + `Transform` (no `InteractiveViewer`).
- Locking: Full control; completely disables all gestures during single-finger drawing; only multi-touch updates scale/offset.
- Pros: Maximum control (can perfectly match Samsung Notes behavior, integrate custom boundary math, custom scroll sync, diagonals, inertia, etc.).
- Cons: You must implement everything (boundaries, clamping, momentum, hit-testing edge cases); easier to get subtle bugs; more maintenance.

### When to use which

- Use 1 if you need a fast, simple solution and don’t need to observe transforms externally.
- Use 2 if you still want `InteractiveViewer`’s stability but need parent-level control (recommended default).
- Use 3 if you need fully custom behavior (exact pan semantics, scroll sync, custom boundaries) and you’re OK owning the complexity.

- Current test file: you already moved toward a custom-integrated approach (wrapper around `InteractiveViewer` plus scroll sync), which combines the strengths of 2 with some of 3’s control. Keep that path for fewer gesture conflicts and better integration.

- If you want, I can refactor your current `DrawingInteractiveViewer` to expose the controller to the parent (like #2) while keeping your scroll sync and boundary tuning.

### Option 2: InteractiveViewer with external TransformationController

- **Pros**
  - **Stable and battle‑tested**: Leverages Flutter’s gesture resolution, inertia, and edge cases.
  - **External control**: Parent owns `TransformationController` → easy to observe/update zoom, bind scrollbars, reset transforms, persist state.
  - **Lower maintenance**: You write less gesture math; fewer edge-case bugs.
  - **Fast to ship**: Good fit if you want reliability now.
- **Cons**
  - **Limited behavior shaping**: You’re still inside InteractiveViewer’s rules (e.g., how pan clamps, gesture arbitration).
  - **Subtle conflicts can remain**: If you need absolute “Samsung Notes” feel, you may hit its limits.
  - **Custom boundary math/scroll sync**: Possible, but you’re working around a black box.

### Option 3: Manual GestureDetector + Transform (custom engine)

- **Pros**
  - **Full control**: You define pan/zoom/scroll semantics exactly (Samsung Notes behavior, diagonal pan, custom clamping, margins).
  - **Perfect drawing lock**: Single‑finger lock is absolute; two‑finger pan/zoom tuned to your needs.
  - **Deep integration**: Pan can drive vertical scroll precisely; custom boundaries by content size, zoom factor, safe areas, etc.
  - **Reusable engine**: Can be extracted into a self‑contained widget/package with a clean API.
- **Cons**
  - **Higher complexity**: You own all edge cases (content height changes, overscroll, keyboard/focus, momentum, orientation).
  - **More code to maintain**: You’ll need ongoing tweaks to keep it silky and bug‑free across platforms/devices.
  - **Time to robust**: Requires careful tuning and testing to reach “production-feel”.

### Recommendation

- **Short-term (ship quickly, reduce risk)**: Go with option 2. Use an external `TransformationController`, enforce your single‑/multi‑finger rules, and wire scroll sync + boundary hints on top. This gets you a robust baseline fast with minimal surprises.
- **Medium-term (premium UX and reuse)**: Migrate to option 3 once behaviors stabilize. Turn it into a small, focused “zoom/pan/scroll engine” widget with:
  - **Public API**: `minScale`, `maxScale`, `onTransform`, `lockSingleTouch`, `contentExtentProvider`, `scrollController`, `drawingMode`.
  - **Integrations**: Scrollbar adapter, content height provider (to handle dynamic text growth), pluggable boundary strategy (strict clamp, soft margins, rubber‑band).
  - **Tests**: Unit tests for clamping math; golden tests for gesture flows.

### Can option 3 become a reusable library?

- **Yes**. Once stable, package it as:
  - A standalone widget (`ZoomPanSurface`) with a clear contract.
  - Optional adapters (e.g., `ScrollSyncAdapter`, `BoundaryStrategy`).
  - Examples for “text mode” vs “drawing mode”.
- This makes it reusable across your app (notes, images, canvases) and in future projects.

- If you want, I can implement option 2 now (clean, controlled `InteractiveViewer` wrapper with external controller, strict locks, proper boundary handling and dynamic content support), and scaffold option 3’s engine in parallel behind a feature flag for incremental migration.

- Summary
  - **Option 2**: Faster, safer, good enough for most; recommended to ship now.
  - **Option 3**: Ultimate control and polish; recommended as a follow‑up to extract into a reusable library once behaviors are finalized.

## Edge cases for option 3

- Edge cases to handle (and how this widget addresses them)
- Dynamic content height growth (typing): inferred from ScrollController.position.maxScrollExtent + viewportHeight; optionally override with contentHeightProvider.
- Boundary clamps: horizontal based on scaled viewport; vertical based on scaled content + soft margin (prevents “cut” at ends).
- Drawing lock: single-finger gestures fully ignored in drawing mode; two-finger pan/zoom still enabled.
- Mixed pan + scroll: vertical pan drives scroll (scaled by zoom) so you can traverse long notes while zoomed.
- Zoom anchors: scaling uses focal point deltas for pan; we keep it smooth and update scale continuously.
- Orientation/keyboard: viewport size changes are picked up via LayoutBuilder; clamps recompute automatically.
- Scrollbar UX: appears on interaction, auto-hides after 1s; hidden in drawing mode.
- Very small gesture noise: thresholds used (e.g., dy.abs()>0.5 for scroll coupling).
- Min/max zoom: enforced (default 1.0..3.0).
- Pointer-state correctness: pointer counts via Listener; ensures lock rules are honored.

## Recoil scroll animate in both cases (top and bottom) instead of snapping back.

What’s wrong now

- The visual overscroll isn’t applied in the transform (translate doesn’t include \_overscrollY).
- While dragging, if you re-enter bounds, \_overscrollY is reset to 0 immediately, so when you release there’s no recoil to animate.

Fixes (only changed parts)

1. Use \_overscrollY in the transform
   Replace the Transform block inside ZoomPanSurface build with:

```dart
Transform(
  transform: Matrix4.identity()
    ..translate(_pan.dx, _pan.dy + _overscrollY)
    ..scale(_scale),
  alignment: Alignment.topLeft,
  child: widget.child,
)
```

2. Do not zero-out \_overscrollY during drag; only animate it on release
   Replace your \_applyPan with this version (keeps overscrollY when you re-enter bounds; animates to 0 on release):

```dart
void _applyPan(Offset delta) {
  // Compute limits
  final scaledW = _viewport.width * _scale;
  final contentH = (_contentHeight > 0 ? _contentHeight : _viewport.height);
  final scaledH = contentH * _scale;

  final maxPanX = ((scaledW - _viewport.width) / 2).clamp(0.0, double.infinity);
  final overflowY = (scaledH - _viewport.height);
  final maxPanY = (overflowY > 0 ? (overflowY / 2 + _softMarginY) : 0.0);

  // Apply pan with clamping
  double nx = (_pan.dx + delta.dx).clamp(-maxPanX, maxPanX);
  double ny = (_pan.dy + delta.dy).clamp(-maxPanY, maxPanY);

  // Couple vertical pan to scroll to traverse long content
  if (delta.dy.abs() > 0.5 && widget.scrollController.hasClients) {
    final current = widget.scrollController.offset;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final proposed = current - (delta.dy / _scale);
    final clamped = proposed.clamp(0.0, maxScroll);
    final overshoot = proposed - clamped; // <0 top, >0 bottom

    if (overshoot.abs() > 0) {
      // Apply visual rubber-band with resistance and cap
      const resistance = 0.5;      // tune 0.3–0.6
      const maxPull = 120.0;       // visual cap
      final visual = -overshoot * resistance * _scale;
      _overscrollY = visual.clamp(-maxPull, maxPull);
      if (current != clamped) widget.scrollController.jumpTo(clamped);
    } else {
      // Stay inside bounds during drag; keep existing _overscrollY
      // (do not zero it here; we animate it on release)
      if (current != clamped) widget.scrollController.jumpTo(clamped);
    }
  }

  setState(() => _pan = Offset(nx, ny));
}
```

3. Ensure recoil is triggered when gesture ends (you already have this, just confirming)

- onScaleEnd calls \_startRecoilIfNeeded()
- onPointerUp (when pointer count drops to 0) calls \_startRecoilIfNeeded()

Those are correct. Keep:

```dart
onScaleEnd: (d) {
  _startRecoilIfNeeded();
},

onPointerUp: (_) {
  setState(() => _pointers = (_pointers - 1).clamp(0, 10));
  if (_pointers == 0) _startRecoilIfNeeded();
},
```

Why this works

- Visual overscroll is applied to the transform during drag (so pull looks continuous).
- We no longer zero-out \_overscrollY mid-drag when re-entering bounds; instead, it animates back on release in both directions.
- Both “bottom → fast to top” and “top → pull past boundary and release” now use the same recoil animation path.

Summary

- Added \_overscrollY to translate.
- Stopped resetting \_overscrollY during drag.
- Recoil still animates via \_startRecoilIfNeeded on gesture end.

## Restrict panning past the original boundarie

1. Use overscroll on both axes in the transform
   Replace the Transform in ZoomPanSurface with:

```dart
Transform(
  transform: Matrix4.identity()
    ..translate(_pan.dx + _overscrollX, _pan.dy + _overscrollY)
    ..scale(_scale),
  alignment: Alignment.topLeft,
  child: widget.child,
)
```

2. Add horizontal overscroll state
   Add this field next to \_overscrollY:

```dart
double _overscrollX = 0.0;
```

3. Recoil both X and Y smoothly on release
   Replace \_startRecoilIfNeeded with:

```dart
void _startRecoilIfNeeded() {
  if (_overscrollX.abs() <= 0.1 && _overscrollY.abs() <= 0.1) return;
  _recoilCtrl?.stop();
  final startX = _overscrollX;
  final startY = _overscrollY;

  _recoilCtrl!.removeListener(_recoilTick);
  _recoilCtrl!.addListener(_recoilTick = () {
    if (!mounted) return;
    final t = Curves.easeOutCubic.transform(_recoilCtrl!.value);
    setState(() {
      _overscrollX = startX * (1.0 - t);
      _overscrollY = startY * (1.0 - t);
    });
  });

  _recoilCtrl!.forward(from: 0.0);
}

// keep a reference to avoid stacking listeners
late VoidCallback _recoilTick;
```

4. Restrict panning to original boundaries (top-left anchoring) with rubber-band on both axes
   Replace \_applyPan with:

```dart
void _applyPan(Offset delta) {
  // View + content sizes at current scale
  final scaledW = _viewport.width * _scale;
  final contentH = (_contentHeight > 0 ? _contentHeight : _viewport.height);
  final scaledH = contentH * _scale;

  // Allowed pan ranges (top-left anchoring): content cannot move past 0 at top-left,
  // and cannot reveal empty space at bottom-right.
  final availX = (scaledW - _viewport.width).clamp(0.0, double.infinity);
  final minX = -availX; // at most this far left
  final maxX = 0.0;     // never to the right of origin

  final availY = (scaledH - _viewport.height).clamp(0.0, double.infinity);
  final minY = -availY; // at most this far up
  final maxY = 0.0;     // never below origin

  // Candidates
  final candX = _pan.dx + delta.dx;
  final candY = _pan.dy + delta.dy;

  // Rubber-band resistance and cap
  const resistance = 0.5;
  const maxPull = 120.0;

  // Horizontal overscroll
  final clampedX = candX.clamp(minX, maxX);
  final overX = candX - clampedX;       // >0 tried to go right, <0 tried to go left
  if (overX.abs() > 0) {
    final visualX = overX * resistance;
    _overscrollX = visualX.clamp(-maxPull, maxPull);
  } else {
    // keep existing _overscrollX during drag; recoil on release
  }

  // Vertical: couple to scroll first (so panning navigates content height)
  if (delta.dy.abs() > 0.5 && widget.scrollController.hasClients) {
    final current = widget.scrollController.offset;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final proposed = current - (delta.dy / _scale);
    final clampedScroll = proposed.clamp(0.0, maxScroll);
    final overScroll = proposed - clampedScroll; // <0 top, >0 bottom

    if (overScroll.abs() > 0) {
      final visualY = -overScroll * resistance * _scale;
      _overscrollY = visualY.clamp(-maxPull, maxPull);
      if (current != clampedScroll) widget.scrollController.jumpTo(clampedScroll);
    } else {
      // keep existing _overscrollY during drag; recoil on release
      if (current != clampedScroll) widget.scrollController.jumpTo(clampedScroll);
    }
  }

  // Apply clamped pan (top-left anchored)
  setState(() {
    _pan = Offset(clampedX, candY.clamp(minY, maxY));
  });
}
```

What this does

- Unzoomed: panning beyond boundaries shows a rubber-band and recoils to the original note bounds when released.
- Zoomed: panning is restricted to the note’s original perimeter; same rubber-band and recoil at all four edges.
- No more extra space on the top/left edge at zoom: we anchor to top-left and clamp (minX..maxX = [-availX, 0], minY..maxY = [-availY, 0]).
- Both “fast pull from bottom past top” and “pull from top past boundary” now animate the same way.

## LateError (LateInitializationError: Field '\_recoilTick@76184199' has not been initialized.)

You’re hitting this because `_recoilCtrl!.removeListener(_recoilTick)` runs before `_recoilTick` is ever set.

Make `_recoilTick` nullable, guard removeListener, and register it safely.

- Change the field

```dart
// old
// late VoidCallback _recoilTick;
// new
VoidCallback? _recoilTick;
```

- Update \_startRecoilIfNeeded

```dart
void _startRecoilIfNeeded() {
  if (_overscrollX.abs() <= 0.1 && _overscrollY.abs() <= 0.1) return;
  _recoilCtrl?.stop();
  final startX = _overscrollX;
  final startY = _overscrollY;

  // remove existing listener if any
  if (_recoilTick != null) {
    _recoilCtrl!.removeListener(_recoilTick!);
  }

  // create a new listener and add it
  _recoilTick = () {
    if (!mounted) return;
    final t = Curves.easeOutCubic.transform(_recoilCtrl!.value);
    setState(() {
      _overscrollX = startX * (1.0 - t);
      _overscrollY = startY * (1.0 - t);
    });
  };
  _recoilCtrl!.addListener(_recoilTick!);

  _recoilCtrl!.forward(from: 0.0);
}
```

- Optional (cleanup in dispose)

```dart
@override
void dispose() {
  widget.scrollController.removeListener(_updateContentHeightFromScroll);
  _scrollBarTimer?.cancel();
  if (_recoilTick != null) {
    _recoilCtrl?.removeListener(_recoilTick!);
  }
  _recoilCtrl?.dispose();
  super.dispose();
}
```

## How Diagonal Panning Works with Option 1

With Option 1, you'd have:

- **Horizontal panning**: Handled by the transform's pan offset
- **Vertical scrolling**: Handled by the scroll controller

When you make a diagonal gesture, the code splits the movement:

```dart
final delta = d.focalPoint - _lastFocal;
```

This `delta` has both `dx` and `dy` components. Even with Option 1:

1. **The `dx` component** gets applied to horizontal panning (as it does now)
2. **The `dy` component** gets applied to vertical scrolling through:
   ```dart
   final proposed = current - (delta.dy / _scale);
   widget.scrollController.jumpTo(clampedScroll);
   ```

## User Experience

From the user's perspective, diagonal gestures will feel exactly the same - they drag diagonally and the content moves diagonally. The difference is just the internal implementation:

- **Current approach**: Both X and Y use transform offsets
- **Option 1**: X uses transform offset, Y uses scroll position

## Why This Actually Works Better

Option 1 is often **better** for diagonal panning because:

1. **Consistent scrollbar behavior** - The scrollbar accurately reflects vertical position
2. **No sync issues** - No conflict between pan offset and scroll position
3. **Better performance** - ScrollController is optimized for large content areas
4. **Platform consistency** - Matches how most mobile apps handle scrollable content

The user won't notice any difference in gesture responsiveness or diagonal movement capability.

Ran tool
Based on the available information, **yes, Samsung Notes appears to use an approach similar to Option 1**. Here's what we can infer:

## Samsung Notes Implementation

Samsung Notes likely uses:

- **Horizontal panning**: Transform-based pan offsets
- **Vertical navigation**: Scroll controller-based movement
- **Diagonal gestures**: Split between horizontal pan and vertical scroll

## Evidence Supporting This

1. **Zoom snapping behavior**: Samsung Notes has (or had) a feature where content snaps to fit screen width perfectly, preventing horizontal scrolling. This suggests they treat horizontal and vertical differently.

2. **Scrollbar behavior**: Like most mobile apps, Samsung Notes shows proper scrollbars that accurately reflect vertical position - this typically indicates scroll controller usage for vertical movement.

3. **User feedback patterns**: Users report issues specifically with zoom levels and "horizontal scrolling" as separate concerns, suggesting the app treats these axes differently.

## Why Major Apps Use Option 1

Most professional note-taking apps (Samsung Notes, Apple Notes, OneNote, etc.) likely use Option 1 because:

- **Platform consistency** - Matches OS scrolling behavior
- **Accessibility** - Screen readers understand scroll positions better
- **Performance** - Scroll controllers are optimized for large documents
- **UI coherence** - Scrollbars, scroll indicators work properly

Option 1 approach would align with industry standards and user expectations from other note-taking apps.

## Boundary Constraints in `_applyPan` Method

The core prevention mechanism is in the `_applyPan` method around lines 244-302. Here's how it works:

### 1. **Top-Left Anchoring System**

```dart
// Content cannot move past 0 at top-left
final minX = -availX; // at most this far left
final maxX = 0.0;     // never to the right of origin
final minY = -availY; // at most this far up
final maxY = 0.0;     // never below origin
```

### 2. **Available Movement Calculation**

```dart
final availX = (scaledW - _viewport.width).clamp(0.0, double.infinity);
final availY = (scaledH - _viewport.height).clamp(0.0, double.infinity);
```

This calculates how much content extends beyond the viewport at the current zoom level.

### 3. **Hard Clamping**

```dart
final clampedX = candX.clamp(minX, maxX);
// For vertical, it couples with scroll controller for content navigation
final clampedScroll = proposed.clamp(0.0, maxScroll);
```

### 4. **Rubber Band Effect for Overscroll**

When you try to pan beyond boundaries, instead of hard-stopping, it provides visual feedback:

```dart
const resistance = 0.5;
const maxPull = 120.0;

final overX = candX - clampedX; // How much you tried to overshoot
if (overX.abs() > 0) {
  final visualX = overX * resistance;
  _overscrollX = visualX.clamp(-maxPull, maxPull); // Rubber band effect
}
```

### 5. **Automatic Recoil**

When you release, `_startRecoilIfNeeded()` smoothly animates back to valid boundaries:

```dart
_recoilTick = () {
  final t = Curves.easeOutCubic.transform(_recoilCtrl!.value);
  setState(() {
    _overscrollX = startX * (1.0 - t); // Animate back to 0
    _overscrollY = startY * (1.0 - t);
  });
};
```

## Summary

Your code prevents overshooting through:

- **Hard boundaries** that never let content move beyond its original dimensions
- **Rubber band resistance** (50% movement with 120px max) for visual feedback when trying to overshoot
- **Smooth recoil animation** that brings content back within bounds when released
- **Top-left anchoring** that ensures content origin stays at (0,0) or within valid pan ranges

This creates a natural, iOS-like scrolling experience where you can "peek" beyond boundaries but are always pulled back to valid viewing areas.

## Initial solution was using a left anchoring system where

```
// Content cannot move past 0 at top-left
final minX = -availX; // at most this far left
final maxX = 0.0;     // never to the right of origin
final minY = -availY; // at most this far up
final maxY = 0.0;     // never below origin
```

This created a new problem - centering the zoom pushes content beyond the left boundary. We need **corner-based anchoring** that chooses the closest corner dynamically.

## The Real Solution: Anchor to Closest Corner

Here's a better approach that calculates which corner the user is closest to and anchors zoom there [[memory:5079472]]:

```dart:lib/src/views/create_note_test.dart
// Replace the _getZoomAlignment method:
Alignment _getZoomAlignment() {
  if (!widget.scrollController.hasClients) {
    return Alignment.topLeft;
  }

  final scrollOffset = widget.scrollController.offset;
  final maxScroll = widget.scrollController.position.maxScrollExtent;

  if (maxScroll <= 0) {
    return Alignment.topLeft;
  }

  // Calculate which quadrant we're in
  final scrollRatio = (scrollOffset / maxScroll).clamp(0.0, 1.0);
  final panRatio = _pan.dx == 0 ? 0.0 : (_pan.dx / (-_viewport.width * (_scale - 1.0))).clamp(0.0, 1.0);

  // Choose corner based on position:
  // Top half vs bottom half (vertical)
  final isTopHalf = scrollRatio < 0.5;
  // Left half vs right half (horizontal)
  final isLeftHalf = panRatio < 0.5;

  if (isTopHalf && isLeftHalf) {
    return Alignment.topLeft;     // (-1, -1)
  } else if (isTopHalf && !isLeftHalf) {
    return Alignment.topRight;    // (1, -1)
  } else if (!isTopHalf && isLeftHalf) {
    return Alignment.bottomLeft;  // (-1, 1)
  } else {
    return Alignment.bottomRight; // (1, 1)
  }
}
```

## How This Works:

1. **Vertical position**: Uses scroll ratio to determine top/bottom half
2. **Horizontal position**: Uses pan ratio to determine left/right half
3. **Corner selection**: Picks the closest of 4 corners:
   - `topLeft`: When at top of note + left side
   - `topRight`: When at top of note + right side (zoomed/panned right)
   - `bottomLeft`: When at bottom of note + left side
   - `bottomRight`: When at bottom of note + right side

## Benefits:

- ✅ **Preserves boundaries**: Always anchors to actual corners
- ✅ **Keeps content visible**: Zoom center stays near what you're viewing
- ✅ **No boundary violations**: Corner anchoring respects the original constraint system
- ✅ **Natural behavior**: Mimics how users expect zoom to work in each area

## Boundary calculation logic solution in the `_applyPan` method.

The Root Cause:

In lines 300-310 of `_applyPan`, you have asymmetric boundary calculations:

```dart
if (alignment.x < 0) {
  // Left-aligned zoom (topLeft, bottomLeft)
  minX = -availX;  // Can pan left by availX
  maxX = 0.0;      // Cannot pan right past 0
} else {
  // Right-aligned zoom (topRight, bottomRight)
  minX = -availX;      // Can pan left by availX
  maxX = rightShift;   // Can pan right by availX (rightShift = availX)
}
```

## The Problem

- **Left-aligned zoom**: `maxX = 0.0` means you can never pan right beyond the original position
- **Right-aligned zoom**: `maxX = availX` means you can pan right by the full available amount

This creates the asymmetric behavior you're experiencing:

1. **When zoomed and left-aligned** (topLeft/bottomLeft): You can pan left (negative direction) but cannot exceed panning to the right
2. **When zoomed and right-aligned** (topRight/bottomRight): You can pan both left AND right by the full available amount

## The Fix

For symmetric panning behavior, both cases should allow the same range. Here's the corrected logic:

```dart
// Symmetric boundaries for both alignments
if (alignment.x < 0) {
  // Left-aligned zoom (topLeft, bottomLeft)
  minX = -availX;
  maxX = availX;  // Allow same range in both directions
} else {
  // Right-aligned zoom (topRight, bottomRight)
  minX = -availX;
  maxX = availX;  // Keep the same symmetric range
}
```

The current code essentially "locks" the right boundary when left-aligned but allows full freedom when right-aligned, which is why you can exceed panning on the right but not on the left after zooming [[memory:5079463]].

However, the code was off. The asymmetry isn’t something to “symmetrize”; it comes from the pivot corner used by Transform.scale. When you scale with a left pivot (topLeft/bottomLeft), all extra width sits to the right, so the valid pan range is [-availX, 0]. With a right pivot (topRight/bottomRight), the valid range is [0, availX]. Your current right-branch gives both negative and positive range, which is why you can “exceed” to the right but never to the left.

Fix the boundary logic in `_applyPan` to mirror the correct ranges per pivot:

```dart
// replace L300-L310
if (alignment.x < 0) {
  // Left-aligned (topLeft, bottomLeft): extra width is to the right
  minX = -availX;
  maxX = 0.0;
} else {
  // Right-aligned (topRight, bottomRight): extra width is to the left
  minX = 0.0;
  maxX = availX;
}
```

Two additional tips:

- Freeze the pivot during a gesture to avoid boundary “flips” mid-pan: cache the alignment in onScaleStart and use it until onScaleEnd.
- If you want true symmetric panning, use `alignment: Alignment.center` and clamp to `[-availX/2, +availX/2]`, but that changes the zoom behavior.

Status: Reviewed your `_getZoomAlignment` and `_applyPan` sections and revised the boundary math. Provided a concrete edit [[memory:5079463]].

- Adjusted horizontal bounds in `lib/src/views/create_note_test.dart` `'_applyPan'` to:
  - left pivot: `[-availX, 0]`
  - right pivot: `[0, availX]`
- Explained that the pivot corner is the reason for left/right difference, and suggested caching the pivot during a gesture to prevent flips.

The clamp is fine now, but the alignment logic is causing the “can’t reach full right” effect.

The culprit is the `panRatio` in `_getZoomAlignment()`. It uses `- _pan.dx`, which keeps the alignment biased to the left when you move right, so your horizontal bounds switch back to the left range and clamp near 0. Fix the ratio so it maps the whole pan span linearly.

Make this edit:

```dart
// in _getZoomAlignment()
double panRatio = 0.0;
if (_scale > 1.0) {
  final maxPanX = (_viewport.width * _scale) - _viewport.width;
  if (maxPanX > 0) {
    // map _pan.dx ∈ [-maxPanX, +maxPanX] → panRatio ∈ [0, 1]
    panRatio = ((_pan.dx + maxPanX) / (2 * maxPanX)).clamp(0.0, 1.0);
  }
}

// Choose corner based on position:
final isTopHalf = scrollRatio < 0.5;
// prefer left when exactly in the middle
final isLeftHalf = panRatio <= 0.5;
```

Keep the `_applyPan` bounds you have now:

```dart
if (alignment.x < 0) {
  // left pivot
  minX = -availX;
  maxX = 0.0;
} else {
  // right pivot
  minX = 0.0;
  maxX = availX;
}
```

Optional but recommended:

- Cache pivot during a gesture to avoid mid-pan flips:
  - onScaleStart: `_pivot = _getZoomAlignment();`
  - onScaleEnd: `_pivot = null;`
  - use `alignment: _pivot ?? _getZoomAlignment()` and the same in `_applyPan`.

Status: Adjusted `panRatio` mapping so alignment can switch to the right when you pan right, letting you reach the full right extent; provided concrete edits as you prefer [[memory:5079463]].

- Fixed `panRatio` in `_getZoomAlignment()` to a proper linear map of `_pan.dx` so alignment can switch right.
- Kept corrected pan bounds in `_applyPan`.
- Suggested optional pivot caching during a gesture to avoid alignment flips mid-pan.

## Upgrading to seemless zoom pan scroll

### Add fields (inside `_ZoomPanSurfaceState`, after `_recoilCtrl`)

```dart
ScrollHoldController? _scrollHold;

bool get _textMode => !widget.isDrawingMode;
bool get _twoFingerTextMode => _textMode && _pointers >= 2;
```

### Update `Listener` to take over immediately on second finger (text mode only)

Replace the existing `Listener` around your `GestureDetector`:

```dart
return Listener(
  onPointerDown: (_) {
    final newCount = _pointers + 1;
    setState(() => _pointers = newCount);

    if (_textMode && newCount == 2 && widget.scrollController.hasClients) {
      try {
        _scrollHold ??= widget.scrollController.position.hold(() {
          _scrollHold = null;
        });
      } catch (_) {}
    }
  },
  onPointerUp: (_) {
    final newCount = (_pointers - 1).clamp(0, 10);
    setState(() => _pointers = newCount);

    if (_textMode && newCount < 2) {
      _scrollHold?.cancel();
      _scrollHold = null;
    }
    if (_pointers == 0) _startRecoilIfNeeded();
  },
  child: GestureDetector(
    onScaleStart: (d) {
      _lastFocal = d.focalPoint;
      _lastScale = _scale;
      _pivot = _getZoomAlignment();
      _showScrollThumb();
    },
    onScaleUpdate: (d) {
      if (widget.isDrawingMode && _pointers == 1) return;

      if (_pointers >= 2) {
        final ns = (_lastScale * d.scale).clamp(widget.minScale, widget.maxScale);
        if (ns != _scale) {
          setState(() => _scale = ns);
          widget.onScaleChanged?.call(_scale);
        }
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
        return;
      }

      if (!widget.isDrawingMode && _pointers == 1) {
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
      }
    },
    onScaleEnd: (d) {
      _startRecoilIfNeeded();
      _pivot = null;
    },
    child: IgnorePointer(
      ignoring: _twoFingerTextMode,
      child: Scrollbar(
        controller: widget.scrollController,
        thumbVisibility: _showScrollBar && !widget.isDrawingMode,
        radius: const Radius.circular(10),
        thickness: 6,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showScrollThumb();
              _updateContentHeightFromScroll();
            });
            return false;
          },
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: _twoFingerTextMode
                ? const NeverScrollableScrollPhysics()
                : (widget.isDrawingMode
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics()),
            child: Transform(
              transform: Matrix4.identity()
                ..translate(_pan.dx + _overscrollX, _pan.dy + _overscrollY)
                ..scale(_scale),
              alignment: _pivot ?? _getZoomAlignment(),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  ),
);
```

### Ensure cleanup in `dispose`

Add this inside `_ZoomPanSurfaceState.dispose()` before `super.dispose();`:

```dart
_scrollHold?.cancel();
```

- This makes ongoing one-finger scroll hand off immediately to two-finger zoom/pan in text mode.
- Scrolling resumes as soon as you lift back to one finger.

- Changes:
  - Added `_scrollHold`, `_textMode`, `_twoFingerTextMode`.
  - Listener now holds scroll when second finger touches; releases on <2 fingers.
  - Wrapped scroll area with `IgnorePointer` and disabled scroll physics while two fingers are down.
  - Cleanup hold in `dispose`.

## Making two-finger pinch take over instantly mid-scroll

Status: I’ll make two-finger pinch take over instantly mid-scroll in text mode by handling pinch via raw pointer events. No drawing-mode changes. I’m adding a tiny pinch engine in the existing `Listener`, keeping your current scale/pan logic intact.

Add these fields inside `_ZoomPanSurfaceState` (near your other gesture state fields):

```dart
final Map<int, Offset> _pointerPositions = {};
double? _pinchStartScale;
double? _pinchStartDist;
Offset? _pinchLastFocal;
bool _manualPinch = false;

bool get _textMode => !widget.isDrawingMode;
bool get _twoFingerTextMode => _textMode && _pointers >= 2;

double _dist(Offset a, Offset b) => (a - b).distance;
Offset _mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
```

Replace your current `return Listener(...` block with this version:

```dart
return Listener(
  onPointerDown: (PointerDownEvent e) {
    _pointerPositions[e.pointer] = e.position;
    final newCount = _pointers + 1;
    setState(() => _pointers = newCount);

    if (_textMode && _pointerPositions.length == 2) {
      // Begin manual pinch immediately (convert active scroll → pinch)
      final pts = _pointerPositions.values.toList(growable: false);
      final startDist = _dist(pts[0], pts[1]);
      _pinchStartScale = _scale;
      _pinchStartDist = startDist > 0 ? startDist : 1.0;
      _pinchLastFocal = _mid(pts[0], pts[1]);
      _manualPinch = true;
      _pivot = _getZoomAlignment();

      if (widget.scrollController.hasClients) {
        try {
          _scrollHold ??= widget.scrollController.position.hold(() {
            _scrollHold = null;
          });
        } catch (_) {}
      }
    }
  },
  onPointerMove: (PointerMoveEvent e) {
    _pointerPositions[e.pointer] = e.position;

    if (_textMode && _manualPinch && _pointerPositions.length >= 2) {
      final pts = _pointerPositions.values.toList(growable: false);
      final currentDist = _dist(pts[0], pts[1]).clamp(1.0, double.infinity);
      final focal = _mid(pts[0], pts[1]);

      final baseScale = _pinchStartScale ?? _scale;
      final baseDist = (_pinchStartDist ?? currentDist);
      final nextScale = (baseScale * (currentDist / baseDist))
          .clamp(widget.minScale, widget.maxScale);

      if (nextScale != _scale) {
        setState(() => _scale = nextScale);
        widget.onScaleChanged?.call(_scale);
      }

      if (_pinchLastFocal != null) {
        final delta = focal - _pinchLastFocal!;
        _applyPan(delta);
      }
      _pinchLastFocal = focal;
      _showScrollThumb();
    }
  },
  onPointerUp: (PointerUpEvent e) {
    _pointerPositions.remove(e.pointer);
    final newCount = (_pointers - 1).clamp(0, 10);
    setState(() => _pointers = newCount);

    if (_textMode && _pointerPositions.length < 2 && _manualPinch) {
      _manualPinch = false;
      _pinchStartScale = null;
      _pinchStartDist = null;
      _pinchLastFocal = null;
      _pivot = null;

      _scrollHold?.cancel();
      _scrollHold = null;
      _startRecoilIfNeeded();
    }
  },
  onPointerCancel: (PointerCancelEvent e) {
    _pointerPositions.remove(e.pointer);
    final newCount = (_pointers - 1).clamp(0, 10);
    setState(() => _pointers = newCount);

    if (_textMode && _pointerPositions.length < 2 && _manualPinch) {
      _manualPinch = false;
      _pinchStartScale = null;
      _pinchStartDist = null;
      _pinchLastFocal = null;
      _pivot = null;

      _scrollHold?.cancel();
      _scrollHold = null;
      _startRecoilIfNeeded();
    }
  },
  child: GestureDetector(
    onScaleStart: (d) {
      _lastFocal = d.focalPoint;
      _lastScale = _scale;
      _pivot = _getZoomAlignment();
      _showScrollThumb();
    },
    onScaleUpdate: (d) {
      // Drawing mode: single-finger fully locked
      if (widget.isDrawingMode && _pointers == 1) return;

      // If manual pinch took over (text mode, 2+ fingers), skip default scale path
      if (_textMode && _manualPinch) return;

      // Multi-touch: zoom + pan (normal path)
      if (_pointers >= 2) {
        final ns = (_lastScale * d.scale).clamp(
          widget.minScale,
          widget.maxScale,
        );
        if (ns != _scale) {
          setState(() => _scale = ns);
          widget.onScaleChanged?.call(_scale);
        }
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
        return;
      }

      // Single-touch: only when NOT drawing mode (text mode)
      if (!widget.isDrawingMode && _pointers == 1) {
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
      }
    },
    onScaleEnd: (d) {
      if (!_manualPinch) {
        _startRecoilIfNeeded();
        _pivot = null;
      }
    },
    child: IgnorePointer(
      ignoring: _twoFingerTextMode,
      child: Scrollbar(
        controller: widget.scrollController,
        thumbVisibility: _showScrollBar && !widget.isDrawingMode,
        radius: const Radius.circular(10),
        thickness: 6,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showScrollThumb();
              _updateContentHeightFromScroll();
            });
            return false;
          },
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: _twoFingerTextMode
                ? const NeverScrollableScrollPhysics()
                : (widget.isDrawingMode
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics()),
            child: Transform(
              transform: Matrix4.identity()
                ..translate(
                  _pan.dx + _overscrollX,
                  _pan.dy + _overscrollY,
                )
                ..scale(_scale),
              alignment: _pivot ?? _getZoomAlignment(),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  ),
);
```

No changes to drawing mode paths.

Summary:

- Added a raw-pointer pinch path in the `Listener` for text mode, so a one-finger scroll converts to two-finger zoom/pan instantly when the second finger touches.
- Kept your existing `GestureDetector` logic; it’s bypassed only while the manual pinch is active in text mode.
- Scroll is held during pinch and resumes on finger lift.

## Tolerance for horizontal and vertical scroll

Users may not be able to do a perfect horizontal scroll and end up scrolling vertically

Status: Adding 1‑finger horizontal pan tolerance in text mode using raw pointer routing. Keeps drawing logic untouched. You’ll get a slop + horizontal-dominance decision; when horizontal wins, we temporarily disable the scrollable and pan horizontally ourselves.

Add these fields inside `_ZoomPanSurfaceState` (near your other gesture fields):

```dart
// 1-finger horizontal pan tolerance (text mode only)
Offset? _oneFingerStart;
Offset? _oneFingerLast;
bool _manualOneFingerPan = false;
bool _oneFingerDecisionMade = false;
static const double _oneFingerSlop = 10.0; // px
static const double _horizontalBias = 1.5; // require dx > dy * bias
```

Update the `Listener` handlers to add the tolerance decision and manual horizontal pan. Replace your current `return Listener(...` block with this:

```dart
return Listener(
  onPointerDown: (PointerDownEvent e) {
    _pointerPositions[e.pointer] = e.position;
    final newCount = _pointers + 1;
    setState(() => _pointers = newCount);

    // prepare 1-finger tolerance (text mode)
    if (_textMode && _pointerPositions.length == 1) {
      _oneFingerStart = e.position;
      _oneFingerLast = e.position;
      _oneFingerDecisionMade = false;
      _manualOneFingerPan = false;
    }

    // begin 2-finger manual pinch immediately (text mode)
    if (_textMode && _pointerPositions.length == 2) {
      final pts = _pointerPositions.values.toList(growable: false);
      final startDist = _dist(pts[0], pts[1]);
      _pinchStartScale = _scale;
      _pinchStartDist = startDist > 0 ? startDist : 1.0;
      _pinchLastFocal = _mid(pts[0], pts[1]);
      _manualPinch = true;
      _pivot = _getZoomAlignment();

      if (widget.scrollController.hasClients) {
        try {
          _scrollHold ??= widget.scrollController.position.hold(() {
            _scrollHold = null;
          });
        } catch (_) {}
      }
    }
  },
  onPointerMove: (PointerMoveEvent e) {
    _pointerPositions[e.pointer] = e.position;

    // 1-finger tolerance routing (text mode)
    if (_textMode && _pointerPositions.length == 1 && _oneFingerStart != null) {
      final cur = e.position;
      final total = cur - _oneFingerStart!;
      if (!_oneFingerDecisionMade) {
        if (total.distance >= _oneFingerSlop) {
          final absDx = total.dx.abs();
          final absDy = total.dy.abs();
          if (absDx > absDy * _horizontalBias) {
            // choose horizontal pan: disable scroll and pan ourselves
            _oneFingerDecisionMade = true;
            _manualOneFingerPan = true;
            _oneFingerLast = cur;

            if (widget.scrollController.hasClients) {
              try {
                _scrollHold ??= widget.scrollController.position.hold(() {
                  _scrollHold = null;
                });
              } catch (_) {}
            }
          } else {
            // choose vertical scroll: let scrollable win
            _oneFingerDecisionMade = true;
            _manualOneFingerPan = false;
            _scrollHold?.cancel();
            _scrollHold = null;
          }
        }
      } else if (_manualOneFingerPan && _oneFingerLast != null) {
        // perform horizontal pan only; suppress vertical
        final delta = cur - _oneFingerLast!;
        _applyPan(Offset(delta.dx, 0.0));
        _oneFingerLast = cur;
        _showScrollThumb();
      }
    }

    // 2-finger manual pinch path (text mode)
    if (_textMode && _manualPinch && _pointerPositions.length >= 2) {
      final pts = _pointerPositions.values.toList(growable: false);
      final currentDist = _dist(pts[0], pts[1]).clamp(1.0, double.infinity);
      final focal = _mid(pts[0], pts[1]);

      final baseScale = _pinchStartScale ?? _scale;
      final baseDist = (_pinchStartDist ?? currentDist);
      final nextScale = (baseScale * (currentDist / baseDist))
          .clamp(widget.minScale, widget.maxScale);

      if (nextScale != _scale) {
        setState(() => _scale = nextScale);
        widget.onScaleChanged?.call(_scale);
      }

      if (_pinchLastFocal != null) {
        final delta = focal - _pinchLastFocal!;
        _applyPan(delta);
      }
      _pinchLastFocal = focal;
      _showScrollThumb();
    }
  },
  onPointerUp: (PointerUpEvent e) {
    _pointerPositions.remove(e.pointer);
    final newCount = (_pointers - 1).clamp(0, 10);
    setState(() => _pointers = newCount);

    // end 1-finger tolerance/pan
    if (_textMode && _pointerPositions.isEmpty) {
      _manualOneFingerPan = false;
      _oneFingerDecisionMade = false;
      _oneFingerStart = null;
      _oneFingerLast = null;
      _scrollHold?.cancel();
      _scrollHold = null;
    }

    // end 2-finger manual pinch
    if (_textMode && _pointerPositions.length < 2 && _manualPinch) {
      _manualPinch = false;
      _pinchStartScale = null;
      _pinchStartDist = null;
      _pinchLastFocal = null;
      _pivot = null;

      _scrollHold?.cancel();
      _scrollHold = null;
      _startRecoilIfNeeded();
    }

    if (_pointers == 0) _startRecoilIfNeeded();
  },
  onPointerCancel: (PointerCancelEvent e) {
    _pointerPositions.remove(e.pointer);
    final newCount = (_pointers - 1).clamp(0, 10);
    setState(() => _pointers = newCount);

    _manualOneFingerPan = false;
    _oneFingerDecisionMade = false;
    _oneFingerStart = null;
    _oneFingerLast = null;

    if (_textMode && _pointerPositions.length < 2 && _manualPinch) {
      _manualPinch = false;
      _pinchStartScale = null;
      _pinchStartDist = null;
      _pinchLastFocal = null;
      _pivot = null;
      _startRecoilIfNeeded();
    }

    _scrollHold?.cancel();
    _scrollHold = null;
  },
  child: GestureDetector(
    onScaleStart: (d) {
      _lastFocal = d.focalPoint;
      _lastScale = _scale;
      _pivot = _getZoomAlignment();
      _showScrollThumb();
    },
    onScaleUpdate: (d) {
      // keep drawing mode untouched
      if (widget.isDrawingMode && _pointers == 1) return;

      // bypass default scale path while manual pinch or manual 1-finger pan is active in text mode
      if (_textMode && (_manualPinch || _manualOneFingerPan)) return;

      if (_pointers >= 2) {
        final ns = (_lastScale * d.scale).clamp(widget.minScale, widget.maxScale);
        if (ns != _scale) {
          setState(() => _scale = ns);
          widget.onScaleChanged?.call(_scale);
        }
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
        return;
      }

      if (!widget.isDrawingMode && _pointers == 1) {
        final delta = d.focalPoint - _lastFocal;
        _applyPan(delta);
        _lastFocal = d.focalPoint;
        _showScrollThumb();
      }
    },
    onScaleEnd: (d) {
      if (!(_textMode && (_manualPinch || _manualOneFingerPan))) {
        _startRecoilIfNeeded();
        _pivot = null;
      }
    },
    child: IgnorePointer(
      ignoring: _twoFingerTextMode || (_textMode && _manualOneFingerPan),
      child: Scrollbar(
        controller: widget.scrollController,
        thumbVisibility: _showScrollBar && !widget.isDrawingMode,
        radius: const Radius.circular(10),
        thickness: 6,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showScrollThumb();
              _updateContentHeightFromScroll();
            });
            return false;
          },
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: _twoFingerTextMode || (_textMode && _manualOneFingerPan)
                ? const NeverScrollableScrollPhysics()
                : (widget.isDrawingMode
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics()),
            child: Transform(
              transform: Matrix4.identity()
                ..translate(_pan.dx + _overscrollX, _pan.dy + _overscrollY)
                ..scale(_scale),
              alignment: _pivot ?? _getZoomAlignment(),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  ),
);
```

Summary:

- Added 1‑finger slop + horizontal dominance decision for text mode.
- When horizontal wins, we disable the scrollable and pan horizontally ourselves; vertical keeps scrolling as before.
- Kept drawing mode logic unchanged.

## Switching to Diagonal Panning when we do a "horizontal scroll"

Status: I’ll make 1‑finger manual pan diagonal (not just horizontal) and, after a two‑finger pinch, keep panning with the remaining finger in text mode.

### 1) Allow diagonal pan during 1‑finger manual pan (text mode)

Replace the inside of the `_manualOneFingerPan` branch in your `onPointerMove` with this:

```dart
// perform diagonal pan; suppress scroll
final delta = cur - _oneFingerLast!;
_applyPan(delta);
_oneFingerLast = cur;
_showScrollThumb();
```

Specifically, change this section:

```dart
} else if (_manualOneFingerPan && _oneFingerLast != null) {
  // perform horizontal pan only; suppress vertical
  final delta = cur - _oneFingerLast!;
  _applyPan(Offset(delta.dx, 0.0));
  _oneFingerLast = cur;
  _showScrollThumb();
}
```

to:

```dart
} else if (_manualOneFingerPan && _oneFingerLast != null) {
  // perform diagonal pan; suppress scroll
  final delta = cur - _oneFingerLast!;
  _applyPan(delta);
  _oneFingerLast = cur;
  _showScrollThumb();
}
```

### 2) After pinch, continue with 1‑finger pan (text mode)

Replace your two‑finger pinch end block in `onPointerUp` with this:

```dart
// end 2-finger manual pinch
if (_textMode && _manualPinch) {
  if (_pointerPositions.length == 1) {
    // Transition to 1-finger manual pan immediately
    _manualPinch = false;
    _pinchStartScale = null;
    _pinchStartDist = null;
    _pinchLastFocal = null;

    _manualOneFingerPan = true;
    _oneFingerDecisionMade = true; // skip slop; already decided
    final remaining = _pointerPositions.values.first;
    _oneFingerStart = remaining;
    _oneFingerLast = remaining;

    // keep scroll held; do NOT cancel here
    // keep _pivot as-is for smoothness
  } else {
    // No fingers left: clean up
    _manualPinch = false;
    _pinchStartScale = null;
    _pinchStartDist = null;
    _pinchLastFocal = null;
    _pivot = null;

    _scrollHold?.cancel();
    _scrollHold = null;
    _startRecoilIfNeeded();
  }
}
```

And mirror the same logic in `onPointerCancel`:

```dart
if (_textMode && _manualPinch) {
  if (_pointerPositions.length == 1) {
    _manualPinch = false;
    _pinchStartScale = null;
    _pinchStartDist = null;
    _pinchLastFocal = null;

    _manualOneFingerPan = true;
    _oneFingerDecisionMade = true;
    final remaining = _pointerPositions.values.first;
    _oneFingerStart = remaining;
    _oneFingerLast = remaining;
  } else {
    _manualPinch = false;
    _pinchStartScale = null;
    _pinchStartDist = null;
    _pinchLastFocal = null;
    _pivot = null;
    _startRecoilIfNeeded();
    _scrollHold?.cancel();
    _scrollHold = null;
  }
}
```

Notes:

- We keep the scroll hold active and the scroll view ignored while the single‑finger manual pan runs, so vertical motion pans the content (via `_applyPan`) instead of scrolling.
- Drawing mode logic is untouched.

- Made panning diagonal with 1 finger in text mode.
- After a two‑finger pinch, lifting one finger now seamlessly continues panning with the remaining finger.

## Final Seemless indefinite zooming and panning

Status: I’ll make pinch re-engage reliably when a second finger arrives during 1‑finger pan/scroll by escalating in onPointerMove too, and also demote back to 1‑finger pan on-the-fly when one finger remains. Drawing mode untouched.

Add this at the start of `onPointerMove` (right after `_pointerPositions[e.pointer] = e.position;`):

```dart
// Auto-escalate to pinch if a second finger appears during 1-finger pan/scroll
if (_textMode && _pointerPositions.length >= 2 && !_manualPinch) {
  final pts = _pointerPositions.values.toList(growable: false);

  // end 1-finger pan state so pinch can take over seamlessly
  _manualOneFingerPan = false;
  _oneFingerDecisionMade = false;
  _oneFingerStart = null;
  _oneFingerLast = null;

  final startDist = _dist(pts[0], pts[1]);
  _pinchStartScale = _scale;
  _pinchStartDist = startDist > 0 ? startDist : 1.0;
  _pinchLastFocal = _mid(pts[0], pts[1]);
  _manualPinch = true;
  _pivot = _getZoomAlignment();

  if (widget.scrollController.hasClients) {
    try {
      _scrollHold ??= widget.scrollController.position.hold(() {
        _scrollHold = null;
      });
    } catch (_) {}
  }
}

// Auto-demote back to 1-finger pan if one finger remains during pinch
if (_textMode && _manualPinch && _pointerPositions.length == 1) {
  _manualPinch = false;
  _pinchStartScale = null;
  _pinchStartDist = null;
  _pinchLastFocal = null;

  _manualOneFingerPan = true;
  _oneFingerDecisionMade = true; // skip slop; we already know intent
  final remaining = _pointerPositions.values.first;
  _oneFingerStart = remaining;
  _oneFingerLast = remaining;
  // keep scroll held
}
```

Keep your existing 2-finger pinch block and 1-finger diagonal pan code as-is.

- This ensures: 1-finger pan/scroll → add 2nd finger → pinch works immediately; pinch → lift 1 finger → keep panning; add 2nd finger again → pinch works again, indefinitely.
- No changes to drawing mode.

- Added on-the-fly escalation/demotion in `onPointerMove` for robustness across gesture sequences.

- I read through `lib/src/views/create_note_test.dart` and traced the pointer and gesture flow.
- What’s biting you is hit-testing: when `_twoFingerTextMode` or `_manualOneFingerPan` is true, `IgnorePointer` makes the scrollable subtree non-hit-testable. Since your outer `Listener` and `GestureDetector` use the default `HitTestBehavior.deferToChild`, they also stop receiving pointer events once the subtree is ignored. That’s why after one-finger pan, when a second finger lands, the “escalate to pinch” logic doesn’t re-engage—those events never reach your handlers.

Fix: make the outer detectors hit-testable even when the child is ignored by setting `behavior: HitTestBehavior.translucent` on:

- the outer `Listener` that wraps the gestures in `ZoomPanSurface`
- the `GestureDetector` itself
- the `Listener` used to count pointers in `_CreateNoteViewState` (so pointer counts keep updating reliably)

Below are concrete edits [[memory:5727650]].

Add translucent behavior to the outer `Listener` in `ZoomPanSurface`:

```dart
// inside _ZoomPanSurfaceState.build
return Listener(
  behavior: HitTestBehavior.translucent, // <-- add this
  onPointerDown: (PointerDownEvent e) {
    // ...
  },
  // ...
  child: GestureDetector(
    // ...
  ),
);
```

Add translucent behavior to the `GestureDetector`:

```dart
child: GestureDetector(
  behavior: HitTestBehavior.translucent, // <-- add this
  onScaleStart: (d) {
    _lastFocal = d.focalPoint;
    _lastScale = _scale;
    _pivot = _getZoomAlignment();
    _showScrollThumb();
  },
  onScaleUpdate: (d) {
    // ...
  },
  onScaleEnd: (d) {
    // ...
  },
  child: IgnorePointer(
    ignoring: _twoFingerTextMode || (_textMode && _manualOneFingerPan),
    child: Scrollbar(
      // ...
    ),
  ),
),
```

Also add translucent behavior to the `Listener` that tracks pointer count in `_CreateNoteViewState`:

```dart
Expanded(
  child: Listener(
    behavior: HitTestBehavior.translucent, // <-- add this
    onPointerDown: (_) => setState(() => _pointerCount++),
    onPointerUp: (_) =>
        setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
    child: ZoomPanSurface(
      // ...
    ),
  ),
),
```

Why this works:

- `HitTestBehavior.translucent` makes the outer detectors receive pointer events even if the child is ignoring input. Your `_pointerPositions`, `_pointers`, and the escalate/demote logic will keep updating in real time. When a second finger lands during one-finger manual pan, the branch that escalates back to `_manualPinch` will consistently execute, restoring pinch-to-zoom immediately.

No other logic changes are required; your manual pinch/escalation code paths are fine once events reliably reach them.

- Added `HitTestBehavior.translucent` to the outer `Listener` and `GestureDetector` in `ZoomPanSurface`, and to the pointer-count `Listener` in `_CreateNoteViewState`.
- This ensures gesture handlers continue receiving events even when `IgnorePointer` disables the scroll subtree, allowing seamless re-escalation from 1-finger pan back to 2-finger pinch.

## Final refactoring

Looking at your code, I can see the `HitTestBehavior.translucent` fixes are already in place. Let me make my refactoring suggestions clearer and more readable:

## Issue 1: Pointer Count Drift

Your current code maintains `_pointers` separately from `_pointerPositions`, which can cause them to get out of sync. Here's the cleaner approach:

```dart:lib/src/views/create_note_test.dart
// Replace these lines in onPointerDown:
_pointerPositions[e.pointer] = e.position;
final newCount = _pointers + 1;
setState(() => _pointers = newCount);

// With this:
_pointerPositions[e.pointer] = e.position;
setState(() => _pointers = _pointerPositions.length);
```

```dart:lib/src/views/create_note_test.dart
// Replace these lines in onPointerUp:
_pointerPositions.remove(e.pointer);
final newCount = (_pointers - 1).clamp(0, 10);
setState(() => _pointers = newCount);

// With this:
_pointerPositions.remove(e.pointer);
setState(() => _pointers = _pointerPositions.length);
```

```dart:lib/src/views/create_note_test.dart
// Replace these lines in onPointerCancel:
_pointerPositions.remove(e.pointer);
final newCount = (_pointers - 1).clamp(0, 10);
setState(() => _pointers = newCount);

// With this:
_pointerPositions.remove(e.pointer);
setState(() => _pointers = _pointerPositions.length);
```

## Issue 2: Missing Cancel Handler

Your outer `Listener` that tracks `_pointerCount` needs to handle cancellations:

```dart:lib/src/views/create_note_test.dart
// Around line 1461, add onPointerCancel:
Expanded(
  child: Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => setState(() => _pointerCount++),
    onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
    onPointerCancel: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)), // Add this line
    child: ZoomPanSurface(
      // ... existing code ...
    ),
  ),
),
```

## Why This Helps

1. **Pointer Count Sync**: Using `_pointerPositions.length` ensures the count is always accurate
2. **Cancel Handling**: Prevents `_pointerCount` from getting stuck when the system cancels touches
3. **Cleaner Logic**: No more manual increment/decrement math that can drift

These changes will make your zoom escalation more reliable and prevent edge cases where pointer counts get stuck.
