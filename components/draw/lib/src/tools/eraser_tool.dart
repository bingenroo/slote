import 'package:flutter/material.dart';
import '../stroke/stroke.dart';
import '../draw_controller.dart';

/// Eraser tool for removing drawing
class EraserTool {
  static Stroke createStroke(
    List<Offset> points,
    double strokeWidth,
  ) {
    return Stroke(
      points: points,
      color: Colors.transparent, // Eraser uses transparent color
      strokeWidth: strokeWidth,
      tool: DrawTool.eraser,
    );
  }
}

