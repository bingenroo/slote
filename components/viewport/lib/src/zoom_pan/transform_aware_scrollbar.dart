import 'package:flutter/material.dart';
import 'boundary_manager.dart';

const double _kTrackWidth = 8.0;
const double _kTrackHeight = 8.0;
const double _kMargin = 4.0;

class TransformAwareScrollbar extends StatefulWidget {
  final Matrix4 transform;
  final BoundaryManager boundaryManager;
  final bool isVisible;
  final void Function(Matrix4)? onTransformApplied;

  const TransformAwareScrollbar({
    super.key,
    required this.transform,
    required this.boundaryManager,
    this.isVisible = true,
    this.onTransformApplied,
  });

  @override
  State<TransformAwareScrollbar> createState() => _TransformAwareScrollbarState();
}

class _TransformAwareScrollbarState extends State<TransformAwareScrollbar> {

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final scrollPositionY = widget.boundaryManager.getScrollPosition(widget.transform);
    final scrollExtentY = widget.boundaryManager.getScrollExtent(widget.transform);
    final scrollPositionX = widget.boundaryManager.getScrollPositionX(widget.transform);
    final scrollExtentX = widget.boundaryManager.getScrollExtentX(widget.transform);
    final scale = widget.transform.getMaxScaleOnAxis();
    final viewportWidth = widget.boundaryManager.viewportSize.width;
    final viewportHeight = widget.boundaryManager.viewportSize.height;

    final showVertical = scrollExtentY < 1.0;
    final showHorizontal = scrollExtentX < 1.0;

    return Stack(
      children: [
        // Vertical scrollbar (right side)
        if (showVertical)
          Positioned(
            right: _kMargin,
            top: 0,
            bottom: showHorizontal ? _kTrackHeight + _kMargin : 0,
            child: _VerticalScrollbarThumb(
              trackHeight: viewportHeight - (showHorizontal ? _kTrackHeight + _kMargin : 0),
              scrollPosition: scrollPositionY,
              scrollExtent: scrollExtentY,
              scale: scale,
              scrollPositionX: scrollPositionX,
              boundaryManager: widget.boundaryManager,
              onTransformApplied: widget.onTransformApplied,
            ),
          ),
        // Horizontal scrollbar (bottom)
        if (showHorizontal)
          Positioned(
            left: 0,
            right: showVertical ? _kTrackWidth + _kMargin : 0,
            bottom: _kMargin,
            child: _HorizontalScrollbarThumb(
              trackWidth: viewportWidth - (showVertical ? _kTrackWidth + _kMargin : 0),
              scrollPosition: scrollPositionX,
              scrollExtent: scrollExtentX,
              scale: scale,
              scrollPositionY: scrollPositionY,
              boundaryManager: widget.boundaryManager,
              onTransformApplied: widget.onTransformApplied,
            ),
          ),
      ],
    );
  }
}

class _VerticalScrollbarThumb extends StatelessWidget {
  final double trackHeight;
  final double scrollPosition;
  final double scrollExtent;
  final double scale;
  final double scrollPositionX;
  final BoundaryManager boundaryManager;
  final void Function(Matrix4)? onTransformApplied;

  const _VerticalScrollbarThumb({
    required this.trackHeight,
    required this.scrollPosition,
    required this.scrollExtent,
    required this.scale,
    required this.scrollPositionX,
    required this.boundaryManager,
    this.onTransformApplied,
  });

  @override
  Widget build(BuildContext context) {
    final minThumb = 32.0.clamp(0.0, trackHeight);
    final thumbHeight = (trackHeight * scrollExtent).clamp(minThumb, trackHeight);
    final maxThumbTravel = trackHeight - thumbHeight;
    final thumbTop = scrollPosition * maxThumbTravel;

    Widget thumb = Container(
      width: _kTrackWidth,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(204),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    if (onTransformApplied != null && maxThumbTravel > 0) {
      thumb = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final newThumbTop = (thumbTop + details.delta.dy).clamp(0.0, maxThumbTravel);
          final newScrollY = maxThumbTravel > 0 ? newThumbTop / maxThumbTravel : 0.0;
          final newTransform = boundaryManager.transformForScrollPosition(
            scale,
            scrollPositionX,
            newScrollY.clamp(0.0, 1.0),
          );
          onTransformApplied!(newTransform);
        },
        child: thumb,
      );
    }

    return Container(
      width: _kTrackWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.withAlpha(26),
      ),
      child: Stack(
        children: [
          Positioned(
            top: thumbTop,
            left: 0,
            right: 0,
            child: SizedBox(height: thumbHeight, child: thumb),
          ),
        ],
      ),
    );
  }
}

class _HorizontalScrollbarThumb extends StatelessWidget {
  final double trackWidth;
  final double scrollPosition;
  final double scrollExtent;
  final double scale;
  final double scrollPositionY;
  final BoundaryManager boundaryManager;
  final void Function(Matrix4)? onTransformApplied;

  const _HorizontalScrollbarThumb({
    required this.trackWidth,
    required this.scrollPosition,
    required this.scrollExtent,
    required this.scale,
    required this.scrollPositionY,
    required this.boundaryManager,
    this.onTransformApplied,
  });

  @override
  Widget build(BuildContext context) {
    final minThumb = 32.0.clamp(0.0, trackWidth);
    final thumbWidth = (trackWidth * scrollExtent).clamp(minThumb, trackWidth);
    final maxThumbTravel = trackWidth - thumbWidth;
    final thumbLeft = scrollPosition * maxThumbTravel;

    Widget thumb = Container(
      height: _kTrackHeight,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(204),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    if (onTransformApplied != null && maxThumbTravel > 0) {
      thumb = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final newThumbLeft = (thumbLeft + details.delta.dx).clamp(0.0, maxThumbTravel);
          final newScrollX = maxThumbTravel > 0 ? newThumbLeft / maxThumbTravel : 0.0;
          final newTransform = boundaryManager.transformForScrollPosition(
            scale,
            newScrollX.clamp(0.0, 1.0),
            scrollPositionY,
          );
          onTransformApplied!(newTransform);
        },
        child: thumb,
      );
    }

    return Container(
      height: _kTrackHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.withAlpha(26),
      ),
      child: Stack(
        children: [
          Positioned(
            left: thumbLeft,
            top: 0,
            bottom: 0,
            child: SizedBox(width: thumbWidth, child: thumb),
          ),
        ],
      ),
    );
  }
}
