import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawController JSON', () {
    test('legacy payload without schemaVersion decodes', () {
      final c = DrawController();
      c.fromJson({
        'strokes': [
          {
            'points': [
              {'x': 1.0, 'y': 2.0},
              {'x': 3.0, 'y': 4.0},
            ],
            'color': 0xff000000,
            'strokeWidth': 2.0,
            'tool': 'DrawTool.pen',
          },
        ],
      });

      expect(c.strokes.length, 1);
      expect(c.strokes.first.samples.length, 2);
      expect(c.strokes.first.pressureEnabled, false);
      expect(c.strokes.first.samples.first.x, 1.0);
    });

    test('schema v1 round-trip', () {
      final c = DrawController();
      c.addStroke(
        Stroke(
          samples: const [
            StrokeSample(0, 0, null),
            StrokeSample(10, 5, null),
          ],
          color: Colors.red,
          strokeWidth: 4,
          tool: DrawTool.highlighter,
          pressureEnabled: true,
        ),
      );

      final json = c.toJson();
      expect(json['schemaVersion'], 1);

      final c2 = DrawController();
      c2.fromJson(json);

      expect(c2.strokes.length, 1);
      expect(c2.strokes.first.tool, DrawTool.highlighter);
      expect(c2.strokes.first.samples.length, 2);
      expect(c2.strokes.first.pressureEnabled, true);
    });
  });
}
