import 'package:draw/draw.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final samplesTight = [
    const StrokeSample(0, 0, null),
    const StrokeSample(2, 1, null),
    const StrokeSample(1, 2, null),
  ];

  final samplesWide = [
    const StrokeSample(0, 0, null),
    const StrokeSample(50, 0, null),
  ];

  /// Middle point is far from the chord (0,0)→(50,0).
  final samplesCrooked = [
    const StrokeSample(0, 0, null),
    const StrokeSample(25, 40, null),
    const StrokeSample(50, 0, null),
  ];

  /// Long drag nearly collinear with first→last (draw-and-hold straight line).
  final samplesNearLine = [
    const StrokeSample(0, 0, null),
    const StrokeSample(80, 3, null),
    const StrokeSample(160, 0, null),
  ];

  group('strokeSamplesWithinRadiusFromFirst', () {
    test('allows points inside radius', () {
      expect(
        strokeSamplesWithinRadiusFromFirst(samplesTight, 24.0),
        true,
      );
    });

    test('rejects when a point exceeds radius', () {
      expect(
        strokeSamplesWithinRadiusFromFirst(samplesWide, 24.0),
        false,
      );
    });
  });

  group('strokeSamplesWithinDeviationFromChord', () {
    test('allows long near-straight stroke', () {
      expect(strokeSamplesWithinDeviationFromChord(samplesNearLine, 24.0), true);
    });

    test('rejects when a sample wanders off the chord', () {
      expect(strokeSamplesWithinDeviationFromChord(samplesCrooked, 24.0), false);
    });

    test('long straight two-point stroke is on chord', () {
      expect(strokeSamplesWithinDeviationFromChord(samplesWide, 24.0), true);
    });
  });

  group('isStraightLineSnapEligible', () {
    test('false when fewer than 2 samples', () {
      expect(
        isStraightLineSnapEligible(
          samples: [samplesTight.first],
          elapsed: const Duration(milliseconds: 500),
        ),
        false,
      );
    });

    test('false when hold too short', () {
      expect(
        isStraightLineSnapEligible(
          samples: samplesTight,
          elapsed: const Duration(milliseconds: 100),
        ),
        false,
      );
    });

    test('false when path wanders off chord', () {
      expect(
        isStraightLineSnapEligible(
          samples: samplesCrooked,
          elapsed: const Duration(milliseconds: 500),
        ),
        false,
      );
    });

    test('true for long drag along near-straight line after hold', () {
      expect(
        isStraightLineSnapEligible(
          samples: samplesNearLine,
          elapsed: const Duration(milliseconds: 500),
        ),
        true,
      );
    });

    test('true when long hold and tight path', () {
      expect(
        isStraightLineSnapEligible(
          samples: samplesTight,
          elapsed: const Duration(milliseconds: 500),
        ),
        true,
      );
    });
  });

  group('maybeSnapSamplesToStraightLine', () {
    test('returns copy when not eligible', () {
      final out = maybeSnapSamplesToStraightLine(
        samples: samplesTight,
        elapsed: const Duration(milliseconds: 50),
      );
      expect(out.length, samplesTight.length);
      expect(identical(out, samplesTight), false);
    });

    test('returns first and last when eligible', () {
      final out = maybeSnapSamplesToStraightLine(
        samples: samplesTight,
        elapsed: const Duration(milliseconds: 500),
      );
      expect(out.length, 2);
      expect(out.first, samplesTight.first);
      expect(out.last, samplesTight.last);
    });
  });

  group('samplesWithStraightLineSnapForTool', () {
    final t0 = DateTime.utc(2020, 1, 1, 12);

    test('skips eraser', () {
      final out = samplesWithStraightLineSnapForTool(
        samples: samplesTight,
        tool: DrawTool.eraser,
        strokeStartedAt: t0,
        referenceTime: t0.add(const Duration(milliseconds: 500)),
      );
      expect(out.length, samplesTight.length);
    });

    test('skips when no start time', () {
      final out = samplesWithStraightLineSnapForTool(
        samples: samplesTight,
        tool: DrawTool.pen,
        strokeStartedAt: null,
        referenceTime: t0.add(const Duration(milliseconds: 500)),
      );
      expect(out.length, samplesTight.length);
    });

    test('snaps pen when eligible', () {
      final out = samplesWithStraightLineSnapForTool(
        samples: samplesTight,
        tool: DrawTool.pen,
        strokeStartedAt: t0,
        referenceTime: t0.add(const Duration(milliseconds: 500)),
      );
      expect(out.length, 2);
    });
  });
}
