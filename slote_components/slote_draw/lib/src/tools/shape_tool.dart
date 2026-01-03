import 'package:flutter/material.dart';
import '../stroke/stroke.dart';

/// Shape tool for drawing shapes
class ShapeTool {
  static Stroke createRectangle(
    Offset start,
    Offset end,
    Color color,
    double strokeWidth,
  ) {
    // Create rectangle from start to end
    final points = [
      start,
      Offset(end.dx, start.dy),
      end,
      Offset(start.dx, end.dy),
      start, // Close the rectangle
    ];

    return Stroke(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      tool: DrawTool.shape,
    );
  }
}

