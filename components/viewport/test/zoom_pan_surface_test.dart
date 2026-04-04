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
}
