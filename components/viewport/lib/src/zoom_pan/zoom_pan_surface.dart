import 'package:flutter/material.dart';
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

    // Initialize zoom state if we have 2 pointers and not drawing
    if (_gestureHandler.pointerCount == 2 && !widget.isDrawingActive) {
      _gestureHandler.initializeZoom(_transform);
    }

    // Initialize pan state if we have 1 pointer, not drawing, and zoomed (scale > 1)
    final scale = _transform.getMaxScaleOnAxis();
    if (_gestureHandler.pointerCount == 1 &&
        !widget.isDrawingMode &&
        scale > 1.0) {
      _gestureHandler.initializePan(_transform);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _gestureHandler.updatePointer(event.pointer, event.position);

    // Handle 2-finger zoom/pan (only when not drawing)
    if (_gestureHandler.pointerCount == 2 && !widget.isDrawingActive) {
      final newTransform = _gestureHandler.calculateZoomTransform();
      if (newTransform != null) {
        setState(() {
          _transform = newTransform;
        });
        _constrainTransform();
      }
    }
    // Handle 1-finger pan only when zoomed (scale > 1) and not drawing
    else if (_gestureHandler.pointerCount == 1 &&
        !widget.isDrawingMode &&
        _transform.getMaxScaleOnAxis() > 1.0) {
      final newTransform = _gestureHandler.calculatePanTransform();
      if (newTransform != null && _boundaryManager != null) {
        final constrainedTransform = _boundaryManager!.constrain(newTransform);

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);

        // Update boundary manager if content size is available
        if (widget.contentHeight != null) {
          _contentSize = Size(_viewport.width, widget.contentHeight!);
        } else if (_contentSize == Size.zero) {
          // Only use a default if we have no content size at all
          _contentSize = _viewport;
        }

        _boundaryManager = BoundaryManager(
          contentSize: _contentSize,
          viewportSize: _viewport,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
        );

        return Stack(
          children: [
            Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
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
                isVisible: !widget.isDrawingMode,
                onTransformApplied: widget.controller?.applyTransform,
              ),
          ],
        );
      },
    );
  }
}

