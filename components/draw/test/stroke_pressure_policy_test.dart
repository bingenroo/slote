import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _stroke({
  required List<StrokeSample> samples,
  bool pressureEnabled = true,
}) {
  return Stroke(
    samples: samples,
    color: Colors.black,
    strokeWidth: 2,
    tool: DrawTool.pen,
    pressureEnabled: pressureEnabled,
  );
}

void main() {
  group('strokeShouldSimulatePressure', () {
    test('false when pressure disabled', () {
      expect(
        strokeShouldSimulatePressure(
          _stroke(
            pressureEnabled: false,
            samples: const [
              StrokeSample(0, 0, 0.2),
              StrokeSample(1, 0, 0.9),
            ],
          ),
        ),
        false,
      );
    });

    test('true when all sample pressures are null', () {
      expect(
        strokeShouldSimulatePressure(
          _stroke(
            samples: const [
              StrokeSample(0, 0, null),
              StrokeSample(1, 0, null),
            ],
          ),
        ),
        true,
      );
    });

    test('true when normalized span is below epsilon (constant hardware)', () {
      expect(
        strokeShouldSimulatePressure(
          _stroke(
            samples: const [
              StrokeSample(0, 0, 1.0),
              StrokeSample(1, 0, 1.0),
              StrokeSample(2, 0, 0.98),
            ],
          ),
        ),
        true,
      );
    });

    test('false when span exceeds epsilon (real stylus variation)', () {
      expect(
        strokeShouldSimulatePressure(
          _stroke(
            samples: const [
              StrokeSample(0, 0, 0.2),
              StrokeSample(1, 0, 0.9),
            ],
          ),
        ),
        false,
      );
    });

    test('true for single sample', () {
      expect(
        strokeShouldSimulatePressure(
          _stroke(samples: const [StrokeSample(0, 0, 0.5)]),
        ),
        true,
      );
    });
  });
}
