import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
    final constrained = _boundaryManager!.constrain(transform);
    setState(() {
      _transform = constrained;
    });
    _notifyTransformChanged();
  }

  void _updateContentSize(Size size) {
    setState(() {
      // Always update _contentSize, but prefer provided contentHeight for height
      if (widget.contentHeight != null) {
        _contentSize = Size(_viewport.width, widget.contentHeight!);
      } else {
        _contentSize = size;
      }

      // Always recreate BoundaryManager with correct content size
      if (_viewport != Size.zero) {
        _boundaryManager = BoundaryManager(
          contentSize: _contentSize,
          viewportSize: _viewport,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
        );
      }
    });
  }

  void _constrainTransform() {
    if (_boundaryManager != null) {
      final constrained = _boundaryManager!.constrain(_transform);

      if (constrained != _transform) {
        setState(() {
          _transform = constrained;
        });
        _notifyTransformChanged();
      }
    }
  }

  void _notifyTransformChanged() {
    widget.onScaleChanged?.call(_transform.getMaxScaleOnAxis());
    widget.onTransformChanged?.call(_transform);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _gestureHandler.addPointer(event.pointer, event.position);

    // Initialize zoom state if we have 2 pointers
    if (_gestureHandler.pointerCount == 2) {
      _gestureHandler.initializeZoom(_transform);
    }

    // Initialize pan state for 1 pointer (drag-to-scroll at any scale)
    if (_gestureHandler.pointerCount == 1 && !widget.isDrawingMode) {
      _gestureHandler.initializePan(_transform);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _gestureHandler.updatePointer(event.pointer, event.position);

    // Handle 2-finger zoom/pan
    if (_gestureHandler.pointerCount == 2 && !widget.isDrawingActive) {
      final newTransform = _gestureHandler.calculateZoomTransform();
      if (newTransform != null) {
        setState(() {
          _transform = newTransform;
        });
        _constrainTransform();
      }
    }
    // Handle 1-finger pan (drag-to-scroll at any scale when not drawing)
    else if (_gestureHandler.pointerCount == 1 &&
        !widget.isDrawingMode) {
      final newTransform = _gestureHandler.calculatePanTransform();
      final manager = _boundaryManager ?? _tempBoundaryManager();
      if (newTransform != null && manager != null) {
        final constrainedTransform = manager.constrain(newTransform);

        final originalY = newTransform.getTranslation().y;
        final constrainedY = constrainedTransform.getTranslation().y;
        final wasConstrained =
            (originalY - constrainedY).abs() > 0.001;

        setState(() {
          _transform = constrainedTransform;
        });

        if (wasConstrained) {
          _gestureHandler.resetPanState(_transform);
        }

        _notifyTransformChanged();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _gestureHandler.removePointer(event.pointer);
    // When going from 2 to 1 finger, re-initialize pan so next move doesn't jump
    if (_gestureHandler.pointerCount == 1) {
      _gestureHandler.reinitializePanFromCurrentPointer(_transform);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _gestureHandler.removePointer(event.pointer);
    if (_gestureHandler.pointerCount == 1) {
      _gestureHandler.reinitializePanFromCurrentPointer(_transform);
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
    final constrained = boundaryManager.constrain(newTransform);
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
        _viewport = viewportSize;

        // Use provided contentHeight, or measured _contentSize, or a fallback larger than
        // viewport so the first drag/wheel can scroll before ContentMeasurer reports (post-frame).
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
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth,
                      maxHeight: double.infinity,
                      alignment: Alignment.topLeft,
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
              TransformAwareScrollbar(
                transform: _transform,
                boundaryManager: _boundaryManager!,
                isVisible: true,
                onTransformApplied: widget.controller?.applyTransform,
              ),
          ],
        );
      },
    );
  }
}

