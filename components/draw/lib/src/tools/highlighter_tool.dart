import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Highlighter tool for highlighting
class HighlighterTool {
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
      color: color.withValues(alpha: 0.3),
      strokeWidth: strokeWidth,
      tool: DrawTool.highlighter,
      pressureEnabled: pressureEnabled,
    );
  }
}

