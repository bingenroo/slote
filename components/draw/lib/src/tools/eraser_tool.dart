import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Eraser tool for removing drawing
///
/// Real stroke/pixel erasure is **Wave D**. Committed eraser gestures are not
/// rendered in Wave A.
class EraserTool {
  static Stroke createStroke(
    List<Offset> points,
    double strokeWidth, {
    bool pressureEnabled = true,
  }) {
    return Stroke(
      samples: points
          .map((o) => StrokeSample(o.dx, o.dy, null))
          .toList(),
      color: Colors.transparent,
      strokeWidth: strokeWidth,
      tool: DrawTool.eraser,
      pressureEnabled: pressureEnabled,
    );
  }
}

