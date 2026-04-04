import 'package:flutter/material.dart';

import 'draw_controller.dart';
import 'draw_tool.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_renderer.dart';

/// Canvas widget for drawing.
///
/// Strokes are stored in **document space**. [documentTransform] maps document
/// coordinates to this widget's local coordinates (paint uses the same matrix).
class DrawCanvas extends StatefulWidget {
  DrawCanvas({
    super.key,
    required this.controller,
    this.isDrawingMode = false,
    this.isDrawingActive = false,
    Matrix4? documentTransform,
  }) : documentTransform = documentTransform ?? Matrix4.identity();

  final DrawController controller;
  final bool isDrawingMode;
  final bool isDrawingActive;

  /// Document → local; identity when the canvas is not inside a zoom/pan shell.
  final Matrix4 documentTransform;

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> {
  List<StrokeSample>? _currentSamples;
  Color? _currentColor;
  double? _currentStrokeWidth;
  DrawTool? _currentTool;

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

  Offset _localToDocument(Offset local) {
    final inv = Matrix4.identity();
    final det = inv.copyInverse(widget.documentTransform);
    if (det == 0.0 || det.isNaN) return local;
    return MatrixUtils.transformPoint(inv, local);
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isDrawingMode) return;

    final doc = _localToDocument(details.localPosition);
    _currentSamples = [StrokeSample(doc.dx, doc.dy, null)];
    _currentColor = widget.controller.currentColor;
    _currentStrokeWidth = widget.controller.currentStrokeWidth;
    _currentTool = widget.controller.currentTool;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isDrawingMode || _currentSamples == null) return;

    final doc = _localToDocument(details.localPosition);
    setState(() {
      _currentSamples!.add(StrokeSample(doc.dx, doc.dy, null));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isDrawingMode || _currentSamples == null) return;

    final stroke = Stroke(
      samples: List<StrokeSample>.from(_currentSamples!),
      color: _currentColor ?? widget.controller.currentColor,
      strokeWidth: _currentStrokeWidth ?? widget.controller.currentStrokeWidth,
      tool: _currentTool ?? widget.controller.currentTool,
      pressureEnabled: widget.controller.pressureEnabled,
    );
    widget.controller.addStroke(stroke);
    setState(() {
      _currentSamples = null;
      _currentColor = null;
      _currentStrokeWidth = null;
      _currentTool = null;
    });
  }

  Stroke? get _previewStroke {
    final s = _currentSamples;
    if (s == null || s.isEmpty) return null;
    return Stroke(
      samples: List<StrokeSample>.from(s),
      color: _currentColor ?? widget.controller.currentColor,
      strokeWidth: _currentStrokeWidth ?? widget.controller.currentStrokeWidth,
      tool: _currentTool ?? widget.controller.currentTool,
      pressureEnabled: widget.controller.pressureEnabled,
    );
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
          currentStroke: _previewStroke,
          documentTransform: widget.documentTransform,
        ),
        child: Container(),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  DrawPainter({
    required this.strokes,
    this.currentStroke,
    required this.documentTransform,
  });

  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Matrix4 documentTransform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(documentTransform.storage);
    for (final stroke in strokes) {
      StrokeRenderer.render(canvas, stroke);
    }
    if (currentStroke != null) {
      StrokeRenderer.render(canvas, currentStroke!, isPreview: true);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        !MatrixUtils.matrixEquals(
          documentTransform,
          oldDelegate.documentTransform,
        );
  }
}
