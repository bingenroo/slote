import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../draw_tool.dart';
import 'stroke.dart';

/// Renders strokes using [getStroke] outlines (filled paths).
///
/// [DrawTool.eraser] strokes are not drawn; real erasure is Wave D.
class StrokeRenderer {
  static void render(
    Canvas canvas,
    Stroke stroke, {
    bool isPreview = false,
  }) {
    if (stroke.tool == DrawTool.eraser) return;

    final points = _toPointVectors(stroke);
    if (points.isEmpty) return;
    if (points.length == 1) points.add(points.first);

    final options = _optionsFor(stroke, isPreview: isPreview);
    final outline = getStroke(points, options: options);
    if (outline.length < 3) return;

    final path = Path()..addPolygon(outline, true);

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (stroke.tool == DrawTool.highlighter) {
      paint.blendMode = BlendMode.srcOver;
    }

    canvas.drawPath(path, paint);
  }

  static List<PointVector> _toPointVectors(Stroke stroke) {
    if (!stroke.pressureEnabled) {
      return stroke.samples
          .map((s) => PointVector(s.x, s.y, 0.5))
          .toList();
    }
    final allNull = stroke.samples.every((s) => s.pressure == null);
    if (allNull) {
      return stroke.samples.map((s) => PointVector(s.x, s.y)).toList();
    }
    return stroke.samples
        .map((s) => PointVector(s.x, s.y, s.pressure ?? 0.5))
        .toList();
  }

  static StrokeOptions _optionsFor(Stroke stroke, {required bool isPreview}) {
    final simulatePressure = stroke.pressureEnabled &&
        stroke.samples.every((s) => s.pressure == null);

    final size = (stroke.strokeWidth * 2).clamp(1.0, 256.0);

    final thinning = stroke.tool == DrawTool.highlighter ? 0.0 : 0.5;

    return StrokeOptions(
      size: size,
      thinning: thinning,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: simulatePressure,
      isComplete: !isPreview,
    );
  }
}
