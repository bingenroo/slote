import 'package:flutter/material.dart';
import '../stroke/stroke.dart';

/// Pen tool for drawing
class PenTool {
  static Stroke createStroke(
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    return Stroke(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      tool: DrawTool.pen,
    );
  }
}

