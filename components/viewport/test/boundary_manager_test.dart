import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viewport/viewport.dart';

void main() {
  group('BoundaryManager', () {
    test('constrain clamps scale to maxScale', () {
      final bm = BoundaryManager(
        contentSize: const Size(100, 100),
        viewportSize: const Size(100, 100),
        minScale: 0.5,
        maxScale: 2.0,
      );
      final m = Matrix4.identity()..scale(5.0);
      final c = bm.constrain(m);
      expect(c.getMaxScaleOnAxis(), 2.0);
    });

    test('constrain clamps scale to minScale', () {
      final bm = BoundaryManager(
        contentSize: const Size(100, 100),
        viewportSize: const Size(100, 100),
        minScale: 0.5,
        maxScale: 2.0,
      );
      final m = Matrix4.identity()..scale(0.1);
      final c = bm.constrain(m);
      expect(c.getMaxScaleOnAxis(), 0.5);
    });

    test('wide content clamps horizontal translation', () {
      final bm = BoundaryManager(
        contentSize: const Size(400, 100),
        viewportSize: const Size(200, 100),
        minScale: 1.0,
        maxScale: 1.0,
      );
      final m = Matrix4.identity()..translate(-500.0, 0.0);
      final c = bm.constrain(m);
      final tx = c.getTranslation().x;
      expect(tx, greaterThanOrEqualTo(200.0 - 400.0));
      expect(tx, lessThanOrEqualTo(0.0));
    });

    test('short content allows vertical slack band', () {
      final bm = BoundaryManager(
        contentSize: const Size(100, 50),
        viewportSize: const Size(100, 200),
        minScale: 1.0,
        maxScale: 1.0,
      );
      final m = Matrix4.identity()..translate(0.0, 40.0);
      final c = bm.constrain(m);
      final ty = c.getTranslation().y;
      expect(ty, inInclusiveRange(-kVerticalOverscrollSlack, kVerticalOverscrollSlack));
    });

    test('transformForScrollPosition scrollY 0 and 1 are in bounds', () {
      final bm = BoundaryManager(
        contentSize: const Size(100, 400),
        viewportSize: const Size(100, 200),
        minScale: 1.0,
        maxScale: 1.0,
      );
      final t0 = bm.transformForScrollPosition(1.0, 0.0, 0.0);
      final t1 = bm.transformForScrollPosition(1.0, 0.0, 1.0);
      final c0 = bm.constrain(t0);
      final c1 = bm.constrain(t1);
      expect(c0, equals(t0));
      expect(c1, equals(t1));
      expect(c0.getTranslation().y, 0.0);
      expect(c1.getTranslation().y, 200.0 - 400.0);
    });

    test('getScrollPosition returns 0 when content fits vertically', () {
      final bm = BoundaryManager(
        contentSize: const Size(100, 50),
        viewportSize: const Size(100, 200),
        minScale: 1.0,
        maxScale: 1.0,
      );
      final t = Matrix4.identity();
      expect(bm.getScrollPosition(t), 0.0);
    });
  });
}
