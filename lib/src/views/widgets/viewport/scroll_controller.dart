import 'package:flutter/material.dart';
import 'dart:developer';

class VerticalScrollController {
  _ScrollControllerState? _state;

  void _attach(_ScrollControllerState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void handlePanStart(PointerDownEvent event) {
    _state?._handlePanStart(event);
  }

  void handlePanUpdate(PointerMoveEvent event) {
    _state?._handlePanUpdate(event);
  }

  void handlePanEnd(PointerUpEvent event) {
    _state?._handlePanEnd(event);
  }

  Widget buildScrollbar() {
    return _state?.buildScrollbar() ?? const SizedBox.shrink();
  }
}

class ScrollController extends StatefulWidget {
  final Matrix4 transform;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final ValueChanged<Matrix4>? onTransformChanged;
  final VerticalScrollController? controller;
  final bool showScrollbar;
  final double
  contentHeight; // Renamed for clarity - this is actually content height
  final double viewportHeight; // Add actual viewport height

  const ScrollController({
    super.key,
    required this.transform,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.contentHeight,
    required this.viewportHeight,
    this.onTransformChanged,
    this.controller,
    this.showScrollbar = true,
  });

  @override
  State<ScrollController> createState() => _ScrollControllerState();
}

class _ScrollControllerState extends State<ScrollController> {
  late Matrix4 _currentTransform;
  double? _lastPanY;

  @override
  void initState() {
    super.initState();
    _currentTransform = Matrix4.copy(widget.transform);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(ScrollController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transform != widget.transform) {
      _currentTransform = Matrix4.copy(widget.transform);
    }
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

  void _handlePanStart(PointerDownEvent event) {
    if (!widget.isDrawingMode || !widget.isDrawingActive) {
      _lastPanY = event.position.dy;
    }
  }

  void _handlePanUpdate(PointerMoveEvent event) {
    if (!widget.isDrawingMode || !widget.isDrawingActive) {
      if (_lastPanY != null) {
        final dy = event.position.dy - _lastPanY!;
        final newTransform = Matrix4.copy(_currentTransform)
          ..translate(0.0, dy);

        // Get viewport and content height from widget properties
        final viewportHeight = widget.viewportHeight;
        final contentHeight = widget.contentHeight;

        // log("viewportHeight: $viewportHeight, contentHeight: $contentHeight");

        // If content is scrollable, apply boundaries
        if (contentHeight > viewportHeight) {
          final newY = newTransform.getTranslation().y;
          final minY = -(contentHeight - viewportHeight);
          const maxY = 0.0;

          final clampedY = newY.clamp(minY, maxY);
          newTransform.setTranslationRaw(
            newTransform.getTranslation().x,
            clampedY,
            newTransform.getTranslation().z,
          );
        } else {
          log("test");
          // If not scrollable, lock translation to 0
          newTransform.setTranslationRaw(
            newTransform.getTranslation().x,
            0.0,
            newTransform.getTranslation().z,
          );
        }

        // Update our internal transform state
        _currentTransform = Matrix4.copy(newTransform);
        widget.onTransformChanged?.call(newTransform);
        _lastPanY = event.position.dy;
      }
    }
  }

  void _handlePanEnd(PointerUpEvent event) {
    _lastPanY = null;
  }

  Widget buildScrollbar() {
    if (!widget.showScrollbar) return const SizedBox.shrink();

    // Move LayoutBuilder inside Positioned, not wrapping it
    return Positioned(
      right: 4,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = widget.viewportHeight;
          final contentHeight = widget.contentHeight;

          // Don't show scrollbar if content fits in viewport
          if (contentHeight <= viewportHeight) {
            // log("Content fits in viewport, returning SizedBox.shrink()");
            return const SizedBox.shrink();
          }

          // Get current Y translation from transform
          final translation = _currentTransform.getTranslation();
          final currentY = translation.y;

          // Calculate scrollbar dimensions
          final scrollableHeight = contentHeight - viewportHeight;
          final scrollbarTrackHeight =
              constraints.maxHeight - 40; // Account for top/bottom margins

          // Calculate thumb size (minimum 20px, maximum is track height)
          final thumbRatio = viewportHeight / contentHeight;
          final thumbHeight = (scrollbarTrackHeight * thumbRatio).clamp(
            20.0,
            scrollbarTrackHeight,
          );

          // Calculate thumb position
          final maxThumbTravel = scrollbarTrackHeight - thumbHeight;
          final scrollProgress = (-currentY / scrollableHeight).clamp(0.0, 1.0);
          final thumbTop = 20 + (scrollProgress * maxThumbTravel);

          // log("Transform Y: $currentY");

          return Container(
            width: 12,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // Scrollbar thumb
                Positioned(
                  top: thumbTop - 20, // Subtract margin
                  child: Container(
                    width: 8,
                    height: thumbHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildScrollbar();
  }
}
