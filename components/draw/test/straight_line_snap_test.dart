import 'package:draw/draw.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StraightLineHoldTracker', () {
    test('fast move resets dwell', () {
      final t = StraightLineHoldTracker();
      final t0 = DateTime.utc(2020, 1, 1, 12);
      t.tickMove(
        prevDoc: Offset.zero,
        prevStamp: Duration.zero,
        currentDoc: const Offset(5, 0),
        currentStamp: const Duration(milliseconds: 100),
        clockNow: t0,
      );
      t.tickMove(
        prevDoc: const Offset(5, 0),
        prevStamp: const Duration(milliseconds: 100),
        currentDoc: const Offset(200, 0),
        currentStamp: const Duration(milliseconds: 110),
        clockNow: t0.add(const Duration(milliseconds: 1)),
      );
      expect(t.isLocked, false);
      final r = t.tickStill(const Offset(200, 0), t0.add(const Duration(seconds: 5)));
      expect(r.justLocked, false);
    });

    test('slow moves accumulate dwell then lock', () {
      final t = StraightLineHoldTracker();
      final t0 = DateTime.utc(2020, 1, 1, 12);
      t.tickMove(
        prevDoc: Offset.zero,
        prevStamp: Duration.zero,
        currentDoc: const Offset(4, 0),
        currentStamp: const Duration(milliseconds: 50),
        clockNow: t0,
      );
      expect(t.isLocked, false);
      final r = t.tickMove(
        prevDoc: const Offset(4, 0),
        prevStamp: const Duration(milliseconds: 50),
        currentDoc: const Offset(8, 0),
        currentStamp: const Duration(milliseconds: 100),
        clockNow: t0.add(const Duration(milliseconds: 800)),
      );
      expect(r.justLocked, true);
      expect(t.isLocked, true);
    });

    test('tickStill reaches dwell duration', () {
      final t = StraightLineHoldTracker();
      var time = DateTime.utc(2020, 1, 1, 12);
      t.tickStill(const Offset(10, 10), time);
      time = time.add(const Duration(milliseconds: 400));
      expect(t.tickStill(const Offset(12, 10), time).justLocked, false);
      time = time.add(const Duration(milliseconds: 400));
      expect(t.tickStill(const Offset(11, 11), time).justLocked, true);
      expect(t.isLocked, true);
    });

    test('moving outside hold radius restarts dwell', () {
      final t = StraightLineHoldTracker();
      final t0 = DateTime.utc(2020, 1, 1, 12);
      t.tickStill(const Offset(0, 0), t0);
      t.tickStill(const Offset(50, 0), t0.add(const Duration(milliseconds: 500)));
      final r = t.tickStill(
        const Offset(51, 0),
        t0.add(const Duration(milliseconds: 900)),
      );
      expect(r.justLocked, false);
      expect(t.isLocked, false);
    });

    test('reset clears lock', () {
      final t = StraightLineHoldTracker();
      final t0 = DateTime.utc(2020, 1, 1, 12);
      t.tickStill(const Offset(0, 0), t0);
      t.tickStill(Offset.zero, t0.add(const Duration(milliseconds: 800)));
      expect(t.isLocked, true);
      t.reset();
      expect(t.isLocked, false);
    });
  });

  group('straightLineHoldAppliesToTool', () {
    test('false for eraser', () {
      expect(straightLineHoldAppliesToTool(DrawTool.eraser), false);
    });

    test('true for pen and highlighter', () {
      expect(straightLineHoldAppliesToTool(DrawTool.pen), true);
      expect(straightLineHoldAppliesToTool(DrawTool.highlighter), true);
    });
  });
}
