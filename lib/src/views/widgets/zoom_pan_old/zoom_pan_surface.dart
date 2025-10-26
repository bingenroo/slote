import 'package:flutter/material.dart';
import 'boundary_manager.dart';
import 'gesture_handler.dart';
import 'content_measurer.dart';
import 'transform_aware_scrollbar.dart';
import 'dart:developer';

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
  }

  void _updateContentSize(Size size) {
    setState(() {
      // Always update _contentSize, but prefer provided contentHeight for height
      if (widget.contentHeight != null) {
        _contentSize = Size(_viewport.width, widget.contentHeight!);
        log('Using provided contentHeight: $_contentSize');
      } else {
        _contentSize = size;
        log('Using measured size: $_contentSize');
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

    // Initialize pan state if we have 1 pointer and in text mode
    if (_gestureHandler.pointerCount == 1 && !widget.isDrawingMode) {
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
    // Handle 1-finger scroll/pan in text mode
    else if (_gestureHandler.pointerCount == 1 && !widget.isDrawingMode) {
      final newTransform = _gestureHandler.calculatePanTransform();
      if (newTransform != null && _boundaryManager != null) {
        log('=== GESTURE MOVE DEBUG ===');
        log('Original transform Y: ${newTransform.getTranslation().y}');

        // Apply boundary constraints BEFORE setting the transform
        final constrainedTransform = _boundaryManager!.constrain(newTransform);

        log(
          'Constrained transform Y: ${constrainedTransform.getTranslation().y}',
        );

        // Check if the transform was constrained (boundary hit)
        final originalY = newTransform.getTranslation().y;
        final constrainedY = constrainedTransform.getTranslation().y;
        final wasConstrained =
            (originalY - constrainedY).abs() >
            0.001; // Use tolerance for float comparison

        log(
          'Was constrained: $wasConstrained (diff: ${(originalY - constrainedY).abs()})',
        );

        setState(() {
          _transform = constrainedTransform;
        });

        // Reset gesture state if boundary was hit
        if (wasConstrained) {
          log('RESETTING gesture state due to boundary hit');
          _gestureHandler.resetPanState(_transform);
        }

        log('===========================');

        _notifyTransformChanged();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _gestureHandler.removePointer(event.pointer);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _gestureHandler.removePointer(event.pointer);
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
                    child: ContentMeasurer(
                      onSizeChanged: _updateContentSize,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
            // Custom scrollbar
            if (widget.showScrollbar && _boundaryManager != null)
              TransformAwareScrollbar(
                transform: _transform,
                boundaryManager: _boundaryManager!,
                isVisible: !widget.isDrawingMode, // Only show in text mode
              ),
          ],
        );
      },
    );
  }
}
