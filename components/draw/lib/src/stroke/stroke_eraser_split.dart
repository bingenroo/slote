import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../draw_tool.dart';
import 'stroke.dart';
import 'stroke_hit_geometry.dart';

const double _kTEps = 1e-7;
const double _kPosEpsSq = 1e-10;

/// Splits [stroke] into zero or more strokes by removing portions of the
/// centerline inside the union of eraser discs (same footprint as
/// [strokeHitByEraserPath]).
List<Stroke> splitStrokeByEraserPath(
  Stroke stroke,
  List<StrokeSample> eraserPath, {
  double eraserDiameterDoc = kDefaultEraserDiameterDoc,
}) {
  if (eraserPath.isEmpty) return [stroke];
  if (stroke.tool != DrawTool.pen && stroke.tool != DrawTool.highlighter) {
    return [stroke];
  }
  final samples = stroke.samples;
  if (samples.isEmpty) return [stroke];

  final reach = eraserReachForStroke(
    stroke,
    eraserDiameterDoc: eraserDiameterDoc,
  );

  if (samples.length == 1) {
    final p = Offset(samples.single.x, samples.single.y);
    if (pointInsideEraserFootprint(p, eraserPath, reach)) return [];
    return [stroke];
  }

  List<StrokeSample>? run;
  final polylines = <List<StrokeSample>>[];

  void flushRun() {
    if (run != null && run!.length >= 2) {
      polylines.add(List<StrokeSample>.from(run!));
    }
    run = null;
  }

  void addKeptChord(StrokeSample pStart, StrokeSample pEnd) {
    if (_dist2sq(pStart, pEnd) < _kPosEpsSq) return;
    if (run == null) {
      run = [pStart, pEnd];
      return;
    }
    if (_dist2sq(run!.last, pStart) <= _kPosEpsSq) {
      run!.add(pEnd);
    } else {
      flushRun();
      run = [pStart, pEnd];
    }
  }

  for (var i = 0; i < samples.length - 1; i++) {
    final a = samples[i];
    final b = samples[i + 1];
    final intervals = _keptParameterIntervals(a, b, eraserPath, reach);
    for (final iv in intervals) {
      addKeptChord(_lerpSample(a, b, iv.$1), _lerpSample(a, b, iv.$2));
    }
  }

  flushRun();

  return polylines
      .map(
        (pts) => Stroke(
          samples: pts,
          color: stroke.color,
          strokeWidth: stroke.strokeWidth,
          tool: stroke.tool,
          pressureEnabled: stroke.pressureEnabled,
        ),
      )
      .toList();
}

double _dist2sq(StrokeSample a, StrokeSample b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}

StrokeSample _lerpSample(StrokeSample a, StrokeSample b, double t) {
  final x = a.x + (b.x - a.x) * t;
  final y = a.y + (b.y - a.y) * t;
  final pa = a.pressure;
  final pb = b.pressure;
  final double? p;
  if (pa != null && pb != null) {
    p = pa + (pb - pa) * t;
  } else if (pa != null) {
    p = pa;
  } else if (pb != null) {
    p = pb;
  } else {
    p = null;
  }
  return StrokeSample(x, y, p);
}

/// Parameter intervals on segment _ab_ (t in [0,1]) kept outside eraser union.
List<(double, double)> _keptParameterIntervals(
  StrokeSample a,
  StrokeSample b,
  List<StrokeSample> eraserPath,
  double reach,
) {
  final ox = a.x;
  final oy = a.y;
  final dx = b.x - a.x;
  final dy = b.y - a.y;

  final ts = <double>{0, 1};
  for (final e in eraserPath) {
    _addCircleSegmentRoots(ox, oy, dx, dy, e.x, e.y, reach, ts);
  }

  final sorted = ts.toList()..sort();
  final uniq = <double>[];
  for (final t in sorted) {
    if (uniq.isEmpty || (t - uniq.last).abs() > _kTEps) uniq.add(t);
  }

  final kept = <(double, double)>[];
  for (var i = 0; i < uniq.length - 1; i++) {
    final ta = uniq[i];
    final tb = uniq[i + 1];
    if (tb - ta <= _kTEps) continue;
    final tm = (ta + tb) / 2;
    final mx = ox + dx * tm;
    final my = oy + dy * tm;
    if (!pointInsideEraserFootprint(Offset(mx, my), eraserPath, reach)) {
      kept.add((ta, tb));
    }
  }
  return kept;
}

/// Adds t in (0,1) where |(A + t D) - C| = R, segment A + t*(B-A).
void _addCircleSegmentRoots(
  double ox,
  double oy,
  double dx,
  double dy,
  double cx,
  double cy,
  double R,
  Set<double> ts,
) {
  final fx = ox - cx;
  final fy = oy - cy;
  final a = dx * dx + dy * dy;
  if (a < 1e-18) return;

  final b = 2 * (fx * dx + fy * dy);
  final c = fx * fx + fy * fy - R * R;
  final disc = b * b - 4 * a * c;
  if (disc < 0) return;

  final s = math.sqrt(disc);
  final t1 = (-b - s) / (2 * a);
  final t2 = (-b + s) / (2 * a);
  for (final t in [t1, t2]) {
    if (t > _kTEps && t < 1 - _kTEps) ts.add(t);
  }
}
