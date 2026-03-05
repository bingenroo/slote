import 'package:flutter/material.dart';
import '../zoom_pan/zoom_pan_surface.dart';

class ViewportSurface extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive;
  final ValueChanged<double>? onScaleChanged;
  final ValueChanged<Matrix4>? onTransformChanged;
  final double minScale;
  final double maxScale;
  final bool showScrollbar;
  final double viewportHeight;
  final double? contentHeight;

  const ViewportSurface({
    super.key,
    required this.child,
    required this.viewportHeight,
    this.contentHeight,
    this.isDrawingMode = false,
    this.isDrawingActive = false,
    this.onScaleChanged,
    this.onTransformChanged,
    this.minScale = 1.0,
    this.maxScale = 3.0,
    this.showScrollbar = true,
  });

  @override
  State<ViewportSurface> createState() => _ViewportSurfaceState();
}

class _ViewportSurfaceState extends State<ViewportSurface> {
  final ZoomPanController _zoomPanController = ZoomPanController();

  @override
  Widget build(BuildContext context) {
    return ZoomPanSurface(
      isDrawingMode: widget.isDrawingMode,
      isDrawingActive: widget.isDrawingActive,
      contentHeight: widget.contentHeight,
      onScaleChanged: widget.onScaleChanged,
      onTransformChanged: widget.onTransformChanged,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      showScrollbar: widget.showScrollbar,
      controller: _zoomPanController,
      child: widget.child,
    );
  }
}
