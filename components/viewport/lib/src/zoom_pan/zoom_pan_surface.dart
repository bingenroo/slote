import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'boundary_manager.dart';
import 'gesture_handler.dart';
import 'content_measurer.dart';
import 'transform_aware_scrollbar.dart';

/// Controller to set transform from outside (e.g. scrollbar drag).
/// Attach via [ZoomPanSurface.controller].
class ZoomPanController {
  _ZoomPanSurfaceState? _state;

  void _attach(_ZoomPanSurfaceState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Apply a new transform (e.g. from scrollbar drag). Will be constrained
  /// by [BoundaryManager] before applying.
  void applyTransform(Matrix4 transform) {
    _state?._applyTransformFromScrollbar(transform);
  }
}

/// Pans and zooms a child with a [Listener] (not [GestureDetector]) so pointer
/// routing stays predictable for drawing overlays.
///
/// **Coordinates:** Pointer positions are in the **Listener’s local coordinates**
/// (viewport space). The child sits under a [Transform]; [onTransformChanged]
/// publishes the matrix integrators should use for document-space ink and
/// hit-testing (e.g. Slote `draw`).
class ZoomPanSurface extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final ValueChanged<double>? onScaleChanged;
  final ValueChanged<Matrix4>? onTransformChanged;
  final double minScale;
  final double maxScale;
  final bool showScrollbar;
  final double? contentHeight;
  final ZoomPanController? controller;

  const ZoomPanSurface({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    this.onScaleChanged,
    this.onTransformChanged,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.showScrollbar = true,
    this.contentHeight,
    this.controller,
  });

  @override
  State<ZoomPanSurface> createState() => _ZoomPanSurfaceState();
}

class _ZoomPanSurfaceState extends State<ZoomPanSurface> {
  Matrix4 _transform = Matrix4.identity();
  Size _viewport = Size.zero;
  Size _contentSize = Size.zero;

  late GestureHandler _gestureHandler;
  BoundaryManager? _boundaryManager;

  // --- debug instrumentation (disabled) ---
  // import foundation kDebugMode when re-enabling.
  // int _dbgDownCount = 0;

  @override
  void initState() {
    super.initState();
    _gestureHandler = GestureHandler();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant ZoomPanSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void _applyTransformFromScrollbar(Matrix4 transform) {
    if (_boundaryManager == null) return;
    final constrained = _boundaryManager!.constrain(transform, rubberBand: false);
    setState(() {
      _transform = constrained;
    });
    _notifyTransformChanged();
  }

  /// Updates measured content size; [BoundaryManager] is built in [build] from
  /// [_contentSize] and current viewport constraints (single source of truth).
  void _updateContentSize(Size size) {
    setState(() {
      if (widget.contentHeight != null) {
        _contentSize = Size(_viewport.width, widget.contentHeight!);
      } else {
        _contentSize = size;
      }
    });
  }

  /// Clamps [_transform] with [BoundaryManager] and notifies listeners.
  ///
  /// Always calls [_notifyTransformChanged] when a manager exists so pinch
  /// updates still propagate when the matrix is already in bounds (see
  /// two-finger branch in [_handlePointerMove]).
  void _constrainTransform({bool rubberBand = false}) {
    if (_boundaryManager == null) return;
    final constrained = _boundaryManager!.constrain(
      _transform,
      rubberBand: rubberBand,
    );
    if (constrained != _transform) {
      setState(() {
        _transform = constrained;
      });
    }
    _notifyTransformChanged();
  }

  void _settleTransform() {
    if (_boundaryManager == null) return;
    final settled = _boundaryManager!.settle(_transform);
    if (settled != _transform) {
      setState(() {
        _transform = settled;
      });
      _notifyTransformChanged();
    }
  }

  void _notifyTransformChanged() {
    widget.onScaleChanged?.call(_transform.getMaxScaleOnAxis());
    widget.onTransformChanged?.call(_transform);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // if (kDebugMode && _dbgDownCount < 25) {
    //   _dbgDownCount++;
    //   final scale = _transform.getMaxScaleOnAxis();
    //   final t = _transform.getTranslation();
    //   debugPrint(
    //     'ZoomPanSurface down#$_dbgDownCount ptr=${event.pointer} '
    //     'local=${event.localPosition} pointers=${_gestureHandler.pointerCount + 1} '
    //     'scale=${scale.toStringAsFixed(3)} '
    //     'tx=${t.x.toStringAsFixed(1)} ty=${t.y.toStringAsFixed(1)} '
    //     'drawingMode=${widget.isDrawingMode} drawingActive=${widget.isDrawingActive}',
    //   );
    // }

    _gestureHandler.addPointer(event.pointer, event.localPosition);

    if (_gestureHandler.pointerCount == 2) {
      _gestureHandler.initializeZoom(_transform);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _gestureHandler.updatePointer(event.pointer, event.localPosition);

    // Handle 2-finger zoom/pan
    if (_gestureHandler.pointerCount == 2 && !widget.isDrawingActive) {
      final newTransform = _gestureHandler.calculateZoomTransform();
      if (newTransform != null) {
        setState(() {
          _transform = newTransform;
        });
        _constrainTransform(rubberBand: true);
        if (_boundaryManager == null) {
          _notifyTransformChanged();
        }
      }
    }
    // Handle 1-finger pan (drag-to-scroll at any scale when not drawing)
    else if (_gestureHandler.pointerCount == 1 &&
        !widget.isDrawingMode) {
      final delta = _gestureHandler.consumePanDelta(event.localPosition);
      if (delta == Offset.zero) return;
      final manager = _boundaryManager ?? _tempBoundaryManager();
      if (manager == null) return;
      final newTransform = Matrix4.copy(_transform)..translate(delta.dx, delta.dy);
      final constrainedTransform = manager.constrain(
        newTransform,
        rubberBand: true,
      );
      setState(() {
        _transform = constrainedTransform;
      });
      _notifyTransformChanged();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _gestureHandler.removePointer(event.pointer);
    if (_gestureHandler.pointerCount == 0) {
      _settleTransform();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _gestureHandler.removePointer(event.pointer);
    if (_gestureHandler.pointerCount == 0) {
      _settleTransform();
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta;
    if (delta.dy == 0.0 && delta.dx == 0.0) return;
    // Use current boundary manager, or a temporary one so we don't drop the first wheel
    // before first layout (e.g. when _viewport is set but _boundaryManager not yet).
    final manager = _boundaryManager ?? _tempBoundaryManager();
    if (manager == null) return;
    _applyScrollDelta(delta, manager);
  }

  BoundaryManager? _tempBoundaryManager() {
    if (_viewport == Size.zero) return null;
    final contentSize = _contentSize != Size.zero
        ? _contentSize
        : Size(_viewport.width, _viewport.height * 2);
    return BoundaryManager(
      contentSize: contentSize,
      viewportSize: _viewport,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
    );
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {}

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final delta = event.panDelta;
    if (delta.dy == 0.0 && delta.dx == 0.0) return;
    final manager = _boundaryManager ?? _tempBoundaryManager();
    if (manager == null) return;
    _applyScrollDelta(delta, manager);
  }

  void _handlePointerPanZoomEnd(PointerPanZoomEndEvent event) {}

  void _applyScrollDelta(Offset delta, [BoundaryManager? manager]) {
    final boundaryManager = manager ?? _boundaryManager;
    if (boundaryManager == null) return;
    final scale = _transform.getMaxScaleOnAxis();
    // Scale scroll by 1/scale so zoomed-in view scrolls proportionally (not too fast)
    final scaleFactor = 1.0 / scale;
    final adjustedDelta = Offset(delta.dx * scaleFactor, delta.dy * scaleFactor);
    final newTransform = Matrix4.copy(_transform)
      ..translate(-adjustedDelta.dx, -adjustedDelta.dy);
    final constrained = boundaryManager.constrain(
      newTransform,
      rubberBand: false,
    );
    setState(() {
      _transform = constrained;
    });
    _notifyTransformChanged();
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final effectiveContentSize = widget.contentHeight != null
            ? Size(viewportSize.width, widget.contentHeight!)
            : (_contentSize != Size.zero
                ? _contentSize
                : Size(viewportSize.width, viewportSize.height * 2));

        final boundaryManager = BoundaryManager(
          contentSize: effectiveContentSize,
          viewportSize: viewportSize,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
        );

        _viewport = viewportSize;
        _boundaryManager = boundaryManager;

        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              onPointerSignal: _handlePointerSignal,
              onPointerPanZoomStart: _handlePointerPanZoomStart,
              onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
              onPointerPanZoomEnd: _handlePointerPanZoomEnd,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: ClipRect(
                  child: Transform(
                    transform: _transform,
                    child: _HitTestExpandedBox(
                      child: ContentMeasurer(
                        onSizeChanged: _updateContentSize,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Custom scrollbar (vertical and horizontal, interactive)
            if (widget.showScrollbar && _boundaryManager != null)
              IgnorePointer(
                // In drawing mode, a new stroke must be able to start anywhere.
                // We still render scrollbars as a hint, but they must not steal
                // the pointer-down hit test (which would create “dead bands” where
                // new strokes can’t begin while continuing strokes can cross).
                ignoring: widget.isDrawingMode,
                child: TransformAwareScrollbar(
                  transform: _transform,
                  boundaryManager: _boundaryManager!,
                  isVisible: true,
                  onTransformApplied: widget.controller?.applyTransform,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Like [OverflowBox] but does **not** clip hit-testing to its own size.
///
/// [OverflowBox] lets its child paint beyond its bounds, but
/// `RenderBox.hitTest` gates on `size.contains(position)`, so touches that map
/// to content coordinates outside the viewport-sized box are silently dropped.
/// This widget keeps the same layout behaviour (child is unconstrained in
/// height) but forwards **all** hit-tests to the child.
class _HitTestExpandedBox extends SingleChildRenderObjectWidget {
  const _HitTestExpandedBox({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTestExpandedBox();
}

class _RenderHitTestExpandedBox extends RenderProxyBox {
  @override
  void performLayout() {
    if (child != null) {
      child!.layout(
        constraints.copyWith(maxHeight: double.infinity),
        parentUsesSize: true,
      );
      size = constraints.biggest;
    } else {
      size = constraints.smallest;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the default `size.contains(position)` gate so the child (which may
    // be taller than this box) can handle its own bounds.
    if (hitTestChildren(result, position: position) ||
        hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

