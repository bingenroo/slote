import 'package:flutter/material.dart';
import 'draw_controller.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_renderer.dart';

/// Canvas widget for drawing
class DrawCanvas extends StatefulWidget {
  final DrawController controller;
  final bool isDrawingMode;
  final bool isDrawingActive;

  const DrawCanvas({
    super.key,
    required this.controller,
    this.isDrawingMode = false,
    this.isDrawingActive = false,
  });

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> {
  Stroke? _currentStroke;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isDrawingMode) return;

    _currentStroke = Stroke(
      points: [details.localPosition],
      color: widget.controller.currentColor,
      strokeWidth: widget.controller.currentStrokeWidth,
      tool: widget.controller.currentTool,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isDrawingMode || _currentStroke == null) return;

    setState(() {
      _currentStroke!.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isDrawingMode || _currentStroke == null) return;

    widget.controller.addStroke(_currentStroke!);
    _currentStroke = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: DrawPainter(
          strokes: widget.controller.strokes,
          currentStroke: _currentStroke,
        ),
        child: Container(),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      StrokeRenderer.render(canvas, stroke);
    }
    if (currentStroke != null) {
      StrokeRenderer.render(canvas, currentStroke!);
    }
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}

