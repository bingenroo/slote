import 'dart:ui' as ui;

import 'stroke.dart';
import 'stroke_hit_geometry.dart';

/// Paints a single eraser disc at the **current** touch (last sample only), like
/// OS “show touches” — no trail of past positions (doc space).
void paintEraserTouchVisual(
  ui.Canvas canvas,
  List<StrokeSample> samples, {
  double eraserDiameterDoc = kDefaultEraserDiameterDoc,
}) {
  if (samples.isEmpty) return;

  final last = samples.last;
  final r = eraserDiameterDoc / 2;
  final center = ui.Offset(last.x, last.y);

  final fill =
      ui.Paint()
        ..color = const ui.Color(0x4DFFFFFF)
        ..style = ui.PaintingStyle.fill;
  final border =
      ui.Paint()
        ..color = const ui.Color(0xB3303030)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;

  canvas.drawCircle(center, r, fill);
  canvas.drawCircle(center, r, border);
}
