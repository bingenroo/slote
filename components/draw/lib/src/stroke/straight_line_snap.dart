import 'dart:ui' show Offset;

import '../draw_tool.dart';

/// Speed + dwell straight line: document-space constants.
abstract final class StraightLineHoldConfig {
  StraightLineHoldConfig._();

  /// Contiguous dwell required before locking a straight segment.
  static const Duration dwellDuration = Duration(milliseconds: 700);

  /// Max instantaneous speed (doc px/s) while the dwell timer runs.
  static const double vMaxHoldDocPxPerSec = 140.0;

  /// Finger must stay within this radius (doc px) of the dwell anchor.
  static const double holdRadiusDocPx = 28.0;

  /// Minimum Δt (microseconds) when computing speed to avoid division blow-ups.
  static const int minDtMicroseconds = 800;
}

/// Result of one hold tick ([StraightLineHoldTracker.tickMove] / [tickStill]).
class StraightLineHoldTickResult {
  const StraightLineHoldTickResult({
    required this.justLocked,
    required this.isLocked,
  });

  /// True only on the transition frame when straight mode engages.
  final bool justLocked;

  final bool isLocked;
}

/// Contiguous dwell: slow movement + inside [holdRadiusDocPx] of anchor → lock.
///
/// Pen/highlighter only; [DrawCanvas] skips the tracker for eraser.
class StraightLineHoldTracker {
  StraightLineHoldTracker();

  Offset? _dwellAnchor;
  DateTime? _dwellStartedAt;
  bool _locked = false;

  bool get isLocked => _locked;

  void reset() {
    _dwellAnchor = null;
    _dwellStartedAt = null;
    _locked = false;
  }

  /// Movement between [prevDoc] and [currentDoc]; [prevStamp]/[currentStamp]
  /// from [PointerEvent.timeStamp] (monotonic deltas).
  ///
  /// [clockNow] overrides wall time for dwell duration (tests only).
  StraightLineHoldTickResult tickMove({
    required Offset prevDoc,
    required Duration prevStamp,
    required Offset currentDoc,
    required Duration currentStamp,
    DateTime? clockNow,
  }) {
    if (_locked) {
      return const StraightLineHoldTickResult(justLocked: false, isLocked: true);
    }

    var dtUs = (currentStamp - prevStamp).inMicroseconds;
    if (dtUs <= 0) {
      dtUs = StraightLineHoldConfig.minDtMicroseconds;
    } else if (dtUs < StraightLineHoldConfig.minDtMicroseconds) {
      dtUs = StraightLineHoldConfig.minDtMicroseconds;
    }
    final dtSec = dtUs / 1e6;
    final dist = (currentDoc - prevDoc).distance;
    final speed = dist / dtSec;

    if (speed > StraightLineHoldConfig.vMaxHoldDocPxPerSec) {
      _resetDwell();
      return const StraightLineHoldTickResult(justLocked: false, isLocked: false);
    }

    return _advanceDwell(currentDoc, clockNow ?? DateTime.now());
  }

  /// Zero-velocity tick (stationary finger / poll timer).
  StraightLineHoldTickResult tickStill(
    Offset currentDoc,
    DateTime currentTime,
  ) {
    if (_locked) {
      return const StraightLineHoldTickResult(justLocked: false, isLocked: true);
    }
    return _advanceDwell(currentDoc, currentTime);
  }

  StraightLineHoldTickResult _advanceDwell(Offset currentDoc, DateTime currentTime) {
    final r = StraightLineHoldConfig.holdRadiusDocPx;

    if (_dwellAnchor == null) {
      _dwellAnchor = currentDoc;
      _dwellStartedAt = currentTime;
      return const StraightLineHoldTickResult(justLocked: false, isLocked: false);
    }

    if ((currentDoc - _dwellAnchor!).distance > r) {
      _resetDwell();
      _dwellAnchor = currentDoc;
      _dwellStartedAt = currentTime;
      return const StraightLineHoldTickResult(justLocked: false, isLocked: false);
    }

    final started = _dwellStartedAt!;
    if (currentTime.difference(started) >= StraightLineHoldConfig.dwellDuration) {
      _locked = true;
      return const StraightLineHoldTickResult(justLocked: true, isLocked: true);
    }

    return const StraightLineHoldTickResult(justLocked: false, isLocked: false);
  }

  void _resetDwell() {
    _dwellAnchor = null;
    _dwellStartedAt = null;
  }
}

/// True if [tool] participates in speed+dwell straight line.
bool straightLineHoldAppliesToTool(DrawTool tool) =>
    tool != DrawTool.eraser;
