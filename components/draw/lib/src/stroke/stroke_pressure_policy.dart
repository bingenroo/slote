import 'stroke.dart';

/// If the normalized pressure range across samples is below this, the pointer
/// source is treated as non-varying (mouse, trackpad, many simulators). We then
/// let [perfect_freehand] derive pressure from stroke dynamics (`simulatePressure`).
const double kStrokePressureFlatSpanEpsilon = 0.05;

/// Whether [getStroke] should use `simulatePressure: true` and omit per-point Z.
///
/// When [Stroke.pressureEnabled] is false, returns false (uniform ink).
bool strokeShouldSimulatePressure(Stroke stroke) {
  if (!stroke.pressureEnabled) return false;
  if (stroke.samples.isEmpty) return true;
  if (stroke.samples.every((s) => s.pressure == null)) return true;

  final values = stroke.samples.map((s) => s.pressure ?? 0.5).toList();
  if (values.length < 2) return true;

  var minV = values.first;
  var maxV = values.first;
  for (final v in values) {
    if (v < minV) minV = v;
    if (v > maxV) maxV = v;
  }
  return (maxV - minV) < kStrokePressureFlatSpanEpsilon;
}
