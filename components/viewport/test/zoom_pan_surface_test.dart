import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viewport/viewport.dart';

void main() {
  testWidgets('two-finger pinch invokes onTransformChanged when in bounds', (
    tester,
  ) async {
    var notifyCount = 0;
    Matrix4? lastTransform;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: ZoomPanSurface(
              isDrawingMode: false,
              isDrawingActive: false,
              contentHeight: 800,
              minScale: 0.5,
              maxScale: 3.0,
              showScrollbar: false,
              onTransformChanged: (m) {
                notifyCount++;
                lastTransform = m.clone();
              },
              child: const SizedBox(width: 400, height: 800),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final center = const Offset(200, 300);
    final g1 = await tester.startGesture(center - const Offset(30, 0));
    await tester.pump();
    final g2 = await tester.startGesture(center + const Offset(30, 0));
    await tester.pump();

    await g1.moveBy(const Offset(-15, 0));
    await g2.moveBy(const Offset(15, 0));
    await tester.pump();

    expect(notifyCount, greaterThan(0));
    expect(lastTransform, isNotNull);
    expect(lastTransform!.getMaxScaleOnAxis(), greaterThan(1.0));
  });

  testWidgets('pinch works when ZoomPanSurface is offset (local vs global coords)', (
    tester,
  ) async {
    Matrix4? lastTransform;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 40,
                top: 60,
                width: 400,
                height: 500,
                child: ZoomPanSurface(
                  isDrawingMode: false,
                  isDrawingActive: false,
                  contentHeight: 900,
                  minScale: 0.5,
                  maxScale: 3.0,
                  showScrollbar: false,
                  onTransformChanged: (m) {
                    lastTransform = m.clone();
                  },
                  child: const SizedBox(width: 400, height: 900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Local center of the Positioned surface (not screen origin).
    const localCenter = Offset(200, 250);
    final g1 = await tester.startGesture(
      const Offset(40, 60) + localCenter - const Offset(30, 0),
    );
    await tester.pump();
    final g2 = await tester.startGesture(
      const Offset(40, 60) + localCenter + const Offset(30, 0),
    );
    await tester.pump();

    await g1.moveBy(const Offset(-20, 0));
    await g2.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(lastTransform, isNotNull);
    expect(lastTransform!.getMaxScaleOnAxis(), greaterThan(1.0));
  });

  testWidgets('one-finger pan then pointer up settles rubber-band', (tester) async {
    Matrix4? lastAfterUp;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: ZoomPanSurface(
              isDrawingMode: false,
              isDrawingActive: false,
              contentHeight: 600,
              minScale: 1.0,
              maxScale: 1.0,
              showScrollbar: false,
              onTransformChanged: (m) {
                lastAfterUp = m.clone();
              },
              child: const SizedBox(width: 200, height: 600),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final g = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    await g.moveBy(const Offset(0, 120));
    await tester.pump();
    await g.up();
    await tester.pump();

    expect(lastAfterUp, isNotNull);
    expect(lastAfterUp!.getTranslation().y, 0.0);
  });
}
