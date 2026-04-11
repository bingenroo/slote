import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('single pointer: capture active then commits one stroke', (tester) async {
    final controller = DrawController();
    final captureStates = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
                onStrokeCaptureActiveChanged: captureStates.add,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawCanvas));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(captureStates.last, true);
    await gesture.moveBy(const Offset(30, 20));
    await gesture.up();
    await tester.pump();

    expect(captureStates.last, false);
    expect(controller.strokes.length, 1);
    expect(controller.strokes.first.samples.length, greaterThan(1));
  });

  testWidgets('second pointer immediately discards in-progress stroke',
      (tester) async {
    final controller = DrawController();
    final captureStates = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
                onStrokeCaptureActiveChanged: captureStates.add,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawCanvas));
    final g1 = await tester.startGesture(center, pointer: 1);
    await tester.pump();
    expect(captureStates.last, true);
    await g1.moveBy(const Offset(40, 0));
    await tester.pump();

    // Second pointer down: immediate discard, no ghost timer, no slop.
    final g2 = await tester.startGesture(center + const Offset(80, 0), pointer: 2);
    await tester.pump();

    expect(controller.strokes, isEmpty);
    expect(captureStates.last, false);

    await g2.up();
    await tester.pump();
    await g1.up();
    await tester.pump();

    expect(controller.strokes, isEmpty);
  });

  testWidgets('early second pointer also discards immediately (no deferred window)',
      (tester) async {
    final controller = DrawController();
    final captureStates = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
                onStrokeCaptureActiveChanged: captureStates.add,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawCanvas));
    // First pointer down (no move yet, so zero ink).
    final g1 = await tester.startGesture(center, pointer: 1);
    await tester.pump();
    expect(captureStates.last, true);

    // Second pointer immediately -- should discard even with zero ink.
    final g2 = await tester.startGesture(center + const Offset(80, 0), pointer: 2);
    await tester.pump();

    expect(controller.strokes, isEmpty);
    expect(captureStates.last, false);

    // Lifting second then continuing first should NOT produce a stroke.
    await g2.up();
    await tester.pump();
    await g1.moveBy(const Offset(40, 0));
    await tester.pump();
    await g1.up();
    await tester.pump();

    expect(controller.strokes, isEmpty);
  });

  testWidgets('move events ignored while multi-touch active', (tester) async {
    final controller = DrawController();
    final captureStates = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
                onStrokeCaptureActiveChanged: captureStates.add,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawCanvas));
    final g1 = await tester.startGesture(center, pointer: 1);
    await tester.pump();
    expect(captureStates.last, true);
    await g1.moveBy(const Offset(20, 0));
    await tester.pump();

    final g2 = await tester.startGesture(center + const Offset(80, 0), pointer: 2);
    await tester.pump();

    // Already discarded by second down.
    expect(captureStates.last, false);

    // Further moves from either pointer should not produce ink.
    await g1.moveBy(const Offset(20, 10));
    await tester.pump();
    await g2.moveBy(const Offset(-12, 0));
    await tester.pump();

    await g2.up();
    await g1.up();
    await tester.pump();

    expect(controller.strokes, isEmpty);
  });

  testWidgets('PointerCancel discards in-progress stroke', (tester) async {
    final controller = DrawController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawCanvas));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.moveBy(const Offset(10, 10));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(controller.strokes, isEmpty);
  });

  testWidgets('eraser removes pen stroke along path', (tester) async {
    final controller = DrawController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawCanvas(
                controller: controller,
                isDrawingMode: true,
              ),
            ),
          ),
        ),
      ),
    );

    final canvasCenter = tester.getCenter(find.byType(DrawCanvas));
    final pen = await tester.startGesture(canvasCenter);
    await tester.pump();
    await pen.moveBy(const Offset(100, 0));
    await pen.up();
    await tester.pump();

    expect(controller.strokes.length, 1);

    controller.setTool(DrawTool.eraser);
    await tester.pump();

    final eraser = await tester.startGesture(canvasCenter);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await eraser.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await eraser.up();
    await tester.pump();

    expect(controller.strokes, isEmpty);
  });
}
