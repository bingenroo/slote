import '../draw_tool.dart';
import 'stroke.dart';

/// Draw-and-hold straight line (Wave C): document-space thresholds.
abstract final class StraightLineInkConfig {
  StraightLineInkConfig._();

  /// Minimum time the stroke must be held before a snap is allowed.
  static const Duration minHold = Duration(milliseconds: 350);

  /// Max perpendicular distance from the **first→last** chord any sample may
  /// have (document space). When the chord is ~zero, we fall back to
  /// [maxHoldStillRadiusPx] (hold-still / tiny wiggle).
  static const double maxDeviationFromChordPx = 24.0;

  /// Used only when first and last samples are nearly coincident.
  static const double maxHoldStillRadiusPx = 24.0;

  /// Squared chord length below this → treat stroke as hold-still (radius test).
  static const double chordLengthSquaredEpsilon = 1.0;
}

double _distanceSquaredPointToSegment(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final abx = bx - ax;
  final aby = by - ay;
  final apx = px - ax;
  final apy = py - ay;
  final abLenSq = abx * abx + aby * aby;
  if (abLenSq < 1e-12) {
    return apx * apx + apy * apy;
  }
  var t = (apx * abx + apy * aby) / abLenSq;
  if (t < 0.0) {
    t = 0.0;
  } else if (t > 1.0) {
    t = 1.0;
  }
  final cx = ax + t * abx;
  final cy = ay + t * aby;
  final dx = px - cx;
  final dy = py - cy;
  return dx * dx + dy * dy;
}

/// True if every sample stays within [maxDeviation] of [samples.first] (Euclidean).
bool strokeSamplesWithinRadiusFromFirst(
  List<StrokeSample> samples,
  double maxDeviation,
) {
  if (samples.isEmpty) return true;
  final fx = samples.first.x;
  final fy = samples.first.y;
  final maxSq = maxDeviation * maxDeviation;
  for (final s in samples) {
    final dx = s.x - fx;
    final dy = s.y - fy;
    if (dx * dx + dy * dy > maxSq) return false;
  }
  return true;
}

/// True if every sample stays within [maxDeviation] of the segment
/// **first → last** (perpendicular distance), or within [maxDeviation] of
/// [samples.first] when the chord is shorter than
/// [StraightLineInkConfig.chordLengthSquaredEpsilon].
bool strokeSamplesWithinDeviationFromChord(
  List<StrokeSample> samples,
  double maxDeviation, {
  double chordEpsSq = StraightLineInkConfig.chordLengthSquaredEpsilon,
  double holdStillMaxRadius = StraightLineInkConfig.maxHoldStillRadiusPx,
}) {
  if (samples.isEmpty) return true;
  if (samples.length < 2) {
    return strokeSamplesWithinRadiusFromFirst(samples, holdStillMaxRadius);
  }
  final a = samples.first;
  final b = samples.last;
  final ax = a.x;
  final ay = a.y;
  final bx = b.x;
  final by = b.y;
  final abx = bx - ax;
  final aby = by - ay;
  final chordLenSq = abx * abx + aby * aby;
  if (chordLenSq < chordEpsSq) {
    return strokeSamplesWithinRadiusFromFirst(samples, holdStillMaxRadius);
  }
  final maxSq = maxDeviation * maxDeviation;
  for (final s in samples) {
    if (_distanceSquaredPointToSegment(s.x, s.y, ax, ay, bx, by) > maxSq) {
      return false;
    }
  }
  return true;
}

/// Whether hold time and tight path allow replacing the stroke with first→last.
bool isStraightLineSnapEligible({
  required List<StrokeSample> samples,
  required Duration elapsed,
  Duration minHold = StraightLineInkConfig.minHold,
  double maxDeviation = StraightLineInkConfig.maxDeviationFromChordPx,
}) {
  if (samples.length < 2) return false;
  if (elapsed < minHold) return false;
  return strokeSamplesWithinDeviationFromChord(samples, maxDeviation);
}

/// Returns `[first, last]` when eligible; otherwise a copy of [samples].
List<StrokeSample> maybeSnapSamplesToStraightLine({
  required List<StrokeSample> samples,
  required Duration elapsed,
  Duration minHold = StraightLineInkConfig.minHold,
  double maxDeviation = StraightLineInkConfig.maxDeviationFromChordPx,
}) {
  if (!isStraightLineSnapEligible(
    samples: samples,
    elapsed: elapsed,
    minHold: minHold,
    maxDeviation: maxDeviation,
  )) {
    return List<StrokeSample>.from(samples);
  }
  return [samples.first, samples.last];
}

/// Applies straight-line snap for pen/highlighter commits and previews.
List<StrokeSample> samplesWithStraightLineSnapForTool({
  required List<StrokeSample> samples,
  required DrawTool tool,
  required DateTime? strokeStartedAt,
  DateTime? referenceTime,
}) {
  final now = referenceTime ?? DateTime.now();
  if (tool == DrawTool.eraser || strokeStartedAt == null) {
    return List<StrokeSample>.from(samples);
  }
  return maybeSnapSamplesToStraightLine(
    samples: samples,
    elapsed: now.difference(strokeStartedAt),
  );
}
