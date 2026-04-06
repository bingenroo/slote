import 'dart:ui' show Offset, Rect;

import '../draw_tool.dart';
import 'stroke.dart';

/// Fixed eraser nib **diameter** in document space (logical px). Visual and
/// hit-testing use the same value so the disc must overlap ink to erase.
const double kDefaultEraserDiameterDoc = 24.0;

double _eraserRadiusDocFor(double eraserDiameterDoc) => eraserDiameterDoc / 2;

/// Eraser radius plus half ink width — same value used for hit-test, split, and UX.
double eraserReachForStroke(
  Stroke stroke, {
  double eraserDiameterDoc = kDefaultEraserDiameterDoc,
}) => _eraserRadiusDocFor(eraserDiameterDoc) + strokeInkHalfWidth(stroke);

/// True if [p] lies inside any eraser disc of radius [reachRadius] centered on
/// [eraserPath] samples (doc space). [reachRadius] is typically
/// [eraserReachForStroke] for the stroke being edited.
bool pointInsideEraserFootprint(
  Offset p,
  List<StrokeSample> eraserPath,
  double reachRadius,
) {
  final r2 = reachRadius * reachRadius;
  for (final s in eraserPath) {
    final dx = p.dx - s.x;
    final dy = p.dy - s.y;
    if (dx * dx + dy * dy <= r2) return true;
  }
  return false;
}

/// Hit-testing geometry aligned with [StrokeRenderer] / perfect_freehand `size`.
///
/// Keep [strokeInkSize] in sync with stroke outline width (see `StrokeRenderer`).
double strokeInkSize(Stroke stroke) {
  final widthFactor = stroke.tool == DrawTool.highlighter ? 3.25 : 2.0;
  return (stroke.strokeWidth * widthFactor).clamp(1.0, 256.0);
}

/// Half-width of ink around the stroke centerline (matches rendering scale).
double strokeInkHalfWidth(Stroke stroke) => strokeInkSize(stroke) / 2;

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

  final half = strokeInkHalfWidth(stroke);
  return Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
}

/// Shortest distance from [p] to the closed rectangle [r] (0 if inside).
double distancePointToRect(Offset p, Rect r) {
  final cx = p.dx.clamp(r.left, r.right);
  final cy = p.dy.clamp(r.top, r.bottom);
  return (Offset(cx, cy) - p).distance;
}

/// Shortest distance from [p] to segment _ab_.
double distancePointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;
  final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lenSq == 0) return (p - a).distance;
  var t = (ap.dx * ab.dx + ap.dy * ab.dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - proj).distance;
}

/// Minimum distance from [p] to the polyline through [samples] (doc space).
double distancePointToStrokePolyline(Offset p, List<StrokeSample> samples) {
  if (samples.isEmpty) return double.infinity;
  if (samples.length == 1) {
    return (p - Offset(samples.first.x, samples.first.y)).distance;
  }
  var minD = double.infinity;
  for (var i = 0; i < samples.length - 1; i++) {
    final a = Offset(samples[i].x, samples[i].y);
    final b = Offset(samples[i + 1].x, samples[i + 1].y);
    final d = distancePointToSegment(p, a, b);
    if (d < minD) minD = d;
  }
  return minD;
}

/// True when the eraser disc (fixed [kDefaultEraserDiameterDoc]) at any path
/// sample overlaps the ink tube around [stroke]'s centerline polyline.
bool strokeHitByEraserPath(
  Stroke stroke,
  List<StrokeSample> path, {
  double eraserDiameterDoc = kDefaultEraserDiameterDoc,
}) {
  if (path.isEmpty) return false;
  if (stroke.tool != DrawTool.pen && stroke.tool != DrawTool.highlighter) {
    return false;
  }
  if (stroke.samples.isEmpty) return false;

  final reach = eraserReachForStroke(
    stroke,
    eraserDiameterDoc: eraserDiameterDoc,
  );

  for (final s in path) {
    final p = Offset(s.x, s.y);
    if (distancePointToStrokePolyline(p, stroke.samples) <= reach) {
      return true;
    }
  }
  return false;
}
