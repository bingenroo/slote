import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Shape tool for drawing shapes
class ShapeTool {
  static Stroke createRectangle(
    Offset start,
    Offset end,
    Color color,
    double strokeWidth, {
    bool pressureEnabled = true,
  }) {
    final points = [
      start,
      Offset(end.dx, start.dy),
      end,
      Offset(start.dx, end.dy),
      start,
    ];

    return Stroke(
      samples: points
          .map((o) => StrokeSample(o.dx, o.dy, null))
          .toList(),
      color: color,
      strokeWidth: strokeWidth,
      tool: DrawTool.shape,
      pressureEnabled: pressureEnabled,
    );
  }
}

