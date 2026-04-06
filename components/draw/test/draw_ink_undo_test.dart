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
  group('DrawController ink undo/redo', () {
    test('undo after addStroke restores empty; redo reapplies', () {
      final c = DrawController();
      final s = _penLine(0, 0, 10, 0);
      c.addStroke(s);
      expect(c.strokes.length, 1);
      expect(c.canUndo, true);
      expect(c.canRedo, false);

      c.undo();
      expect(c.strokes, isEmpty);
      expect(c.canUndo, false);
      expect(c.canRedo, true);

      c.redo();
      expect(c.strokes.length, 1);
      expect(c.canUndo, true);
      expect(c.canRedo, false);
    });

    test('clear is undoable', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 10, 0));
      c.clear();
      expect(c.strokes, isEmpty);
      c.undo();
      expect(c.strokes.length, 1);
    });

    test('eraser batch: begin/end group yields single undo step', () {
      final c = DrawController();
      c.setEraserMode(EraserMode.pixel);
      c.addStroke(_penLine(0, 0, 100, 0));
      c.beginInkUndoGroup();
      c.eraseStrokesHitByEraserPath([const StrokeSample(30, 0, null)]);
      c.eraseStrokesHitByEraserPath([const StrokeSample(60, 0, null)]);
      c.endInkUndoGroup();

      expect(c.strokes.length, greaterThan(1));
      expect(c.canUndo, true);

      c.undo();
      expect(c.strokes.length, 1);
      expect(c.strokes.first.samples.first.x, 0);
      expect(c.strokes.first.samples.last.x, 100);
    });

    test('erase without group records one undo per mutating call', () {
      final c = DrawController();
      c.setEraserMode(EraserMode.pixel);
      c.addStroke(_penLine(0, 0, 100, 0));
      c.eraseStrokesHitByEraserPath([const StrokeSample(25, 0, null)]);
      final afterFirst = c.strokes.length;
      expect(afterFirst, greaterThan(1));
      c.eraseStrokesHitByEraserPath([const StrokeSample(75, 0, null)]);
      expect(c.canUndo, true);

      c.undo();
      expect(c.strokes.length, afterFirst);

      c.undo();
      expect(c.strokes.length, 1);
    });

    test('fromJson clears undo stack', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 10, 0));
      expect(c.canUndo, true);

      c.fromJson({
        'schemaVersion': 1,
        'strokes': <Object>[],
      });
      expect(c.strokes, isEmpty);
      expect(c.canUndo, false);
      expect(c.canRedo, false);
    });

    test('new ink mutation clears redo', () {
      final c = DrawController();
      c.addStroke(_penLine(0, 0, 10, 0));
      c.undo();
      expect(c.canRedo, true);
      c.addStroke(_penLine(5, 0, 15, 0));
      expect(c.canRedo, false);
    });
  });
}
