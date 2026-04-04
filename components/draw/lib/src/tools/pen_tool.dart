import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Pen tool for drawing
class PenTool {
  static Stroke createStroke(
    List<Offset> points,
    Color color,
    double strokeWidth, {
    bool pressureEnabled = true,
  }) {
    return Stroke(
      samples: points
          .map((o) => StrokeSample(o.dx, o.dy, null))
          .toList(),
      color: color,
      strokeWidth: strokeWidth,
      tool: DrawTool.pen,
      pressureEnabled: pressureEnabled,
    );
  }
}

