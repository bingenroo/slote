// Smoke tests: example app shell + viewport + draw integration.

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viewport/viewport.dart';

import 'package:draw_example/main.dart';

void main() {
  testWidgets('Example app builds and shows draw example title', (WidgetTester tester) async {
    await tester.pumpWidget(const DrawExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Draw Example'), findsOneWidget);
  });

  testWidgets('DrawCanvas inside ViewportSurface commits stroke after layout', (
    WidgetTester tester,
  ) async {
    final controller = DrawController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 480,
            child: ViewportSurface(
              viewportHeight: 480,
              contentHeight: 1200,
              isDrawingMode: true,
              isDrawingActive: false,
              showScrollbar: false,
              child: SizedBox(
                height: 1200,
                width: 320,
                child: DrawCanvas(
                  controller: controller,
                  isDrawingMode: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final g = await tester.startGesture(const Offset(160, 240));
    await tester.pump();
    await g.moveBy(const Offset(50, 30));
    await tester.pump();
    await g.up();
    await tester.pump();

    expect(controller.strokes.length, 1);
    expect(controller.strokes.first.samples.length, greaterThan(1));

    controller.dispose();
  });

  testWidgets('DrawCanvas receives hits at bottom of viewport after zoom', (
    WidgetTester tester,
  ) async {
    final controller = DrawController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: ViewportSurface(
              viewportHeight: 400,
              contentHeight: 1200,
              isDrawingMode: true,
              isDrawingActive: false,
              showScrollbar: false,
              child: SizedBox(
                height: 1200,
                width: 300,
                child: DrawCanvas(
                  controller: controller,
                  isDrawingMode: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pinch to zoom ~2x near the bottom of the viewport.
    final g1 = await tester.startGesture(const Offset(120, 350));
    await tester.pump();
    final g2 = await tester.startGesture(const Offset(180, 350));
    await tester.pump();
    await g1.moveBy(const Offset(-30, 0));
    await g2.moveBy(const Offset(30, 0));
    await tester.pump();
    await g1.up();
    await g2.up();
    await tester.pump();

    // Draw near the bottom of the viewport -- this used to be a "dead zone"
    // where the OverflowBox clipped hit-testing to viewport size.
    final draw = await tester.startGesture(const Offset(150, 380));
    await tester.pump();
    await draw.moveBy(const Offset(40, 0));
    await tester.pump();
    await draw.up();
    await tester.pump();

    expect(controller.strokes.length, 1);
    expect(controller.strokes.first.samples.length, greaterThan(1));

    controller.dispose();
  });
}
