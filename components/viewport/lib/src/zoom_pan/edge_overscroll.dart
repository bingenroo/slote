import 'dart:math' as math;

/// iOS-style rubber-band resistance past a hard edge.
///
/// [overshootPastEdge] is how far past the bound the unconstrained value lies
/// (always non-negative). Returns the resisted distance to add inside the bound.
double edgeRubberResist(double overshootPastEdge, double maxRubber) {
  if (overshootPastEdge <= 0 || maxRubber <= 0) return 0;
  final x = overshootPastEdge / (maxRubber * 0.45);
  // Stable tanh without relying on dart:math.tanh (SDK variance).
  if (x > 20) return maxRubber;
  if (x < -20) return -maxRubber;
  final e2x = math.exp(2 * x);
  return maxRubber * ((e2x - 1) / (e2x + 1));
}

/// Applies rubber-band on one axis when [value] is outside [[hardMin], [hardMax]].
double applyAxisRubber(
  double value,
  double hardMin,
  double hardMax, {
  required double maxRubber,
}) {
  if (value < hardMin) {
    final overshoot = hardMin - value;
    return hardMin - edgeRubberResist(overshoot, maxRubber);
  }
  if (value > hardMax) {
    final overshoot = value - hardMax;
    return hardMax + edgeRubberResist(overshoot, maxRubber);
  }
  return value;
}
