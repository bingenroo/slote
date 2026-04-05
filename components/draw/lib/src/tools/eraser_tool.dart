import 'package:flutter/material.dart';

import '../draw_tool.dart';
import '../stroke/stroke.dart';
import '../stroke/stroke_hit_geometry.dart';

/// Eraser tool for removing drawing.
///
/// Product erasure is applied in [DrawCanvas] via
/// [DrawController.eraseStrokesHitByEraserPath]: a fixed disc
/// ([kDefaultEraserDiameterDoc]) cuts the stroke **centerline** (vector split,
/// Wave D2); preview is a single touch indicator matching hit-testing.
/// The [createStroke] helper remains for tests; the canvas does not commit eraser
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

