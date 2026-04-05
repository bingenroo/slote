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
    test('hits pen stroke when eraser sample is inside inflated bounds', () {
      final stroke = _penLine(0, 0, 100, 0);
      const eraserW = 20.0;
      final path = [const StrokeSample(50, 0, null)];
      expect(strokeHitByEraserPath(stroke, path, eraserW), true);
    });

    test('misses when eraser path is far away', () {
      final stroke = _penLine(0, 0, 100, 0);
      const eraserW = 2.0;
      final path = [const StrokeSample(50, 80, null)];
      expect(strokeHitByEraserPath(stroke, path, eraserW), false);
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
      expect(strokeHitByEraserPath(stroke, path, 40), false);
    });
  });

  group('DrawController.eraseStrokesHitByEraserPath', () {
    test('removes intersecting strokes only', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 50, 0));
      c.addStroke(_penLine(200, 0, 250, 0));

      c.eraseStrokesHitByEraserPath(
        [const StrokeSample(25, 0, null)],
        20,
      );

      expect(c.strokes.length, 1);
      expect(c.strokes.first.samples.first.x, 200);
    });

    test('empty path is a no-op and does not notify', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 10, 0));
      var notifications = 0;
      c.addListener(() => notifications++);

      c.eraseStrokesHitByEraserPath([], 10);

      expect(c.strokes.length, 1);
      expect(notifications, 0);
    });
  });
}
