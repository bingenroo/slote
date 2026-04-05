import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _penLine(double x0, double y0, double x1, double y1) {
  return Stroke(
    samples: [
      StrokeSample(x0, y0, null),
      StrokeSample(x1, y1, null),
    ],
    color: Colors.black,
    strokeWidth: 2,
    tool: DrawTool.pen,
    pressureEnabled: false,
  );
}

void main() {
  group('strokeHitByEraserPath', () {
    test('hits when eraser disc overlaps stroke polyline', () {
      final stroke = _penLine(0, 0, 100, 0);
      final path = [const StrokeSample(50, 0, null)];
      expect(strokeHitByEraserPath(stroke, path), true);
    });

    test('misses when path is far from polyline (not just bbox)', () {
      final stroke = _penLine(0, 0, 100, 0);
      // Horizontal line y=0; 24px disc radius 12 + ink half 2 => reach 14
      final path = [const StrokeSample(50, 20, null)];
      expect(strokeHitByEraserPath(stroke, path), false);
    });

    test('misses when eraser path is far away', () {
      final stroke = _penLine(0, 0, 100, 0);
      final path = [const StrokeSample(50, 80, null)];
      expect(strokeHitByEraserPath(stroke, path), false);
    });

    test('ignores shape tool', () {
      final stroke = Stroke(
        samples: const [StrokeSample(0, 0, null), StrokeSample(10, 0, null)],
        color: Colors.black,
        strokeWidth: 2,
        tool: DrawTool.shape,
        pressureEnabled: false,
      );
      final path = [const StrokeSample(5, 0, null)];
      expect(strokeHitByEraserPath(stroke, path), false);
    });
  });

  group('DrawController.eraseStrokesHitByEraserPath', () {
    test('stroke mode removes whole stroke when hit', () {
      final c = DrawController();
      c.setEraserMode(EraserMode.stroke);
      c.addStroke(_penLine(0, 0, 50, 0));
      c.addStroke(_penLine(200, 0, 250, 0));

      c.eraseStrokesHitByEraserPath([const StrokeSample(25, 0, null)]);

      expect(c.strokes.length, 1);
      expect(c.strokes.first.samples.first.x, 200);
    });

    test('splits hit stroke into fragments; leaves others untouched', () {
      final c = DrawController();
      c.setEraserMode(EraserMode.pixel);
      c.addStroke(_penLine(0, 0, 50, 0));
      c.addStroke(_penLine(200, 0, 250, 0));

      c.eraseStrokesHitByEraserPath([const StrokeSample(25, 0, null)]);

      // Reach ~14px: first line becomes left + right fragments; second line intact.
      expect(c.strokes.length, 3);
      final xs = c.strokes.map((s) => s.samples.first.x).toList()..sort();
      expect(xs.any((x) => (x - 200).abs() < 0.01), true);
      final firstLineFrags =
          c.strokes.where((s) => s.samples.last.x <= 55).toList();
      expect(firstLineFrags.length, 2);
    });

    test('full pass removes entire pen stroke', () {
      final c = DrawController();
      c.setEraserMode(EraserMode.pixel);
      c.addStroke(_penLine(0, 0, 100, 0));
      // Dense samples along the line inside reach of the 24px eraser.
      final path = <StrokeSample>[
        for (var x = 0.0; x <= 100; x += 8) StrokeSample(x, 0, null),
      ];
      c.eraseStrokesHitByEraserPath(path);
      expect(c.strokes, isEmpty);
    });

    test('empty path is a no-op and does not notify', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 10, 0));
      var notifications = 0;
      c.addListener(() => notifications++);

      c.eraseStrokesHitByEraserPath([]);

      expect(c.strokes.length, 1);
      expect(notifications, 0);
    });
  });
}
