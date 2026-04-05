import 'dart:ui' show Offset, Rect;

import '../draw_tool.dart';
import 'stroke.dart';

/// Hit-testing geometry aligned with [StrokeRenderer] / perfect_freehand `size`.
///
/// Keep [strokeInkSize] in sync with stroke outline width (see `StrokeRenderer`).
double strokeInkSize(Stroke stroke) {
  final widthFactor = stroke.tool == DrawTool.highlighter ? 3.25 : 2.0;
  return (stroke.strokeWidth * widthFactor).clamp(1.0, 256.0);
}

/// Eraser uses the same scale as pen ink ([widthFactor] 2.0).
double eraserInkSize(double strokeWidth) {
  return (strokeWidth * 2.0).clamp(1.0, 256.0);
}

double eraserTipRadius(double strokeWidth) => eraserInkSize(strokeWidth) / 2;

/// Axis-aligned bounds of sample polyline inflated by half ink size (doc space).
Rect boundsForHitTest(Stroke stroke) {
  final samples = stroke.samples;
  if (samples.isEmpty) return Rect.zero;

  var minX = samples.first.x;
  var maxX = minX;
  var minY = samples.first.y;
  var maxY = minY;
  for (var i = 1; i < samples.length; i++) {
    final s = samples[i];
    if (s.x < minX) minX = s.x;
    if (s.x > maxX) maxX = s.x;
    if (s.y < minY) minY = s.y;
    if (s.y > maxY) maxY = s.y;
  }

  final half = strokeInkSize(stroke) / 2;
  return Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
}

/// Shortest distance from [p] to the closed rectangle [r] (0 if inside).
double distancePointToRect(Offset p, Rect r) {
  final cx = p.dx.clamp(r.left, r.right);
  final cy = p.dy.clamp(r.top, r.bottom);
  return (Offset(cx, cy) - p).distance;
}

/// True if any eraser sample’s tip circle intersects [stroke]’s hit bounds.
bool strokeHitByEraserPath(
  Stroke stroke,
  List<StrokeSample> path,
  double eraserStrokeWidth,
) {
  if (path.isEmpty) return false;
  if (stroke.tool != DrawTool.pen && stroke.tool != DrawTool.highlighter) {
    return false;
  }
  if (stroke.samples.isEmpty) return false;

  final b = boundsForHitTest(stroke);
  final radius = eraserTipRadius(eraserStrokeWidth);
  for (final s in path) {
    if (distancePointToRect(Offset(s.x, s.y), b) <= radius) return true;
  }
  return false;
}
