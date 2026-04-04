import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Highlighter tool for highlighting.
///
/// Store the user's chosen [color] (typically opaque); [StrokeRenderer] applies
/// translucent ink and a wider tip so it reads as a marker, including for
/// strokes created by [DrawCanvas].
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
      color: color,
      strokeWidth: strokeWidth,
      tool: DrawTool.highlighter,
      pressureEnabled: pressureEnabled,
    );
  }
}

