import 'package:flutter/material.dart';
import 'dart:developer';
import 'scroll_controller.dart' as scroll;

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
  final double contentHeight;

  const ViewportSurface({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.viewportHeight,
    required this.contentHeight,
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
  // Matrix4 _transform = Matrix4.identity();
  // late scroll.VerticalScrollController _scrollController;
  late scroll.ScrollController _scrollWidget;

  @override
  void initState() {
    super.initState();
    // _scrollController = scroll.VerticalScrollController();
  }

  // void _onTransformChanged(Matrix4 newTransform) {
  //   setState(() {
  //     _transform = newTransform;
  //   });
  //   widget.onTransformChanged?.call(newTransform);
  // }

  // void _handlePanStart(PointerDownEvent event) {
  //   // In future, you can add logic here to determine which controller should handle this
  //   // For now, just vertical scroll

  //   _scrollController.handlePanStart(event);
  // }

  // void _handlePanUpdate(PointerMoveEvent event) {
  //   // In future, you can add logic here to route to different controllers
  //   // based on gesture type, current mode, etc.
  //   _scrollController.handlePanUpdate(event);
  // }

  // void _handlePanEnd(PointerUpEvent event) {
  //   _scrollController.handlePanEnd(event);
  // }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final contentHeight = widget.contentHeight;
        final contentHeight = constraints.maxHeight;
        final viewportHeight = widget.viewportHeight;

        // log(
        //   "Viewport Surface: $contentHeight, Viewport Height: $viewportHeight",
        // );

        return Listener(
          // onPointerDown: _handlePanStart,
          // onPointerMove: _handlePanUpdate,
          // onPointerUp: _handlePanEnd,
          child: Stack(
            children: [
              // Transform(transform: _transform, child: widget.child),
              widget.child,
              // scroll.ScrollController(
              //   transform: _transform,
              //   isDrawingMode: widget.isDrawingMode,
              //   isDrawingActive: widget.isDrawingActive,
              //   onTransformChanged: _onTransformChanged,
              //   controller: _scrollController,
              //   showScrollbar: widget.showScrollbar,
              //   contentHeight: contentHeight,
              //   viewportHeight: viewportHeight,
              // ),
              // Future: Add other UI elements from other controllers here
            ],
          ),
        );
      },
    );
  }
}
