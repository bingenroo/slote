import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';

/// Eraser tool for removing drawing.
///
/// Product erasure is applied in [DrawCanvas] via
/// [DrawController.eraseStrokesHitByEraserPath] (whole-stroke removal). The
/// [createStroke] helper remains for tests; the canvas does not commit eraser
/// strokes to the model.
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

