import 'dart:async';

import 'package:flutter/material.dart';

import 'draw_controller.dart';
import 'draw_tool.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_renderer.dart';
import 'stroke/straight_line_snap.dart';

/// Canvas widget for drawing.
///
/// Strokes are stored in **document space**. [documentTransform] maps document
/// coordinates to this widget's local coordinates (paint uses the same matrix).
///
/// **Wave B:** Uses a [Listener] and **active pointer count** — samples are
/// added only while exactly **one** pointer is down. A **second** pointer
/// **commits** the in-progress stroke (partial) so parents can clear
/// [isDrawingActive] and allow viewport pinch-zoom — see package roadmap.
///
/// **Wave C:** Speed + dwell straight line ([StraightLineHoldConfig]): slow
/// movement inside a hold radius for [StraightLineHoldConfig.dwellDuration]
/// locks a fixed two-point preview; commit matches that preview.
class DrawCanvas extends StatefulWidget {
  DrawCanvas({
    super.key,
    required this.controller,
    this.isDrawingMode = false,
    this.isDrawingActive = false,
    Matrix4? documentTransform,
    this.onStrokeCaptureActiveChanged,
  }) : documentTransform = documentTransform ?? Matrix4.identity();

  final DrawController controller;
  final bool isDrawingMode;
  final bool isDrawingActive;

  /// Document → local; identity when the canvas is not inside a zoom/pan shell.
  final Matrix4 documentTransform;

  /// Called when in-progress stroke capture starts or ends (commit, partial
  /// commit on second finger, cancel, or [isDrawingMode] turned off).
  final ValueChanged<bool>? onStrokeCaptureActiveChanged;

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> {
  final Set<int> _activePointers = <int>{};

  List<StrokeSample>? _currentSamples;
  Color? _currentColor;
  double? _currentStrokeWidth;
  DrawTool? _currentTool;

  final StraightLineHoldTracker _holdTracker = StraightLineHoldTracker();

  /// Last doc position and stamp for speed; updated every down/move.
  late Offset _lastDocForHold;
  Duration _lastPointerStamp = Duration.zero;

  Timer? _holdPollTimer;

  StrokeSample? _straightLockedStart;
  StrokeSample? _straightLockedEnd;

  bool _captureNotified = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _cancelHoldPoll();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isDrawingMode && oldWidget.isDrawingMode) {
      _discardInProgress();
    }
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _notifyCaptureActive(bool active) {
    if (_captureNotified == active) return;
    _captureNotified = active;
    widget.onStrokeCaptureActiveChanged?.call(active);
  }

  void _cancelHoldPoll() {
    _holdPollTimer?.cancel();
    _holdPollTimer = null;
  }

  void _startHoldPoll() {
    _cancelHoldPoll();
    _holdPollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _currentSamples == null) return;
      final tool = _currentTool ?? widget.controller.currentTool;
      if (!straightLineHoldAppliesToTool(tool) || _holdTracker.isLocked) return;
      final r = _holdTracker.tickStill(_lastDocForHold, DateTime.now());
      if (r.justLocked) {
        _lockStraightLine(_lastDocForHold, null);
      }
      if (r.justLocked) setState(() {});
    });
  }

  void _lockStraightLine(Offset endDoc, double? pressure) {
    final s = _currentSamples;
    if (s == null || s.isEmpty) return;
    _straightLockedStart = s.first;
    _straightLockedEnd = StrokeSample(endDoc.dx, endDoc.dy, pressure);
  }

  void _clearStraightLock() {
    _straightLockedStart = null;
    _straightLockedEnd = null;
  }

  Offset _localToDocument(Offset local) {
    final inv = Matrix4.identity();
    final det = inv.copyInverse(widget.documentTransform);
    if (det == 0.0 || det.isNaN) return local;
    return MatrixUtils.transformPoint(inv, local);
  }

  double? _pressureForSample(PointerEvent event) {
    if (!widget.controller.pressureEnabled) return null;
    final min = event.pressureMin;
    final max = event.pressureMax;
    if (max > min) {
      return ((event.pressure - min) / (max - min)).clamp(0.0, 1.0);
    }
    return event.pressure.clamp(0.0, 1.0);
  }

  void _handlePointerDown(PointerDownEvent event) {
    final hadNone = _activePointers.isEmpty;
    _activePointers.add(event.pointer);

    if (!widget.isDrawingMode) return;

    if (_currentSamples != null && _activePointers.length == 2) {
      _commitAndClearInProgress();
      return;
    }

    if (hadNone && _activePointers.length == 1) {
      final doc = _localToDocument(event.localPosition);
      setState(() {
        _holdTracker.reset();
        _clearStraightLock();
        _currentSamples = [StrokeSample(doc.dx, doc.dy, _pressureForSample(event))];
        _currentColor = widget.controller.currentColor;
        _currentStrokeWidth = widget.controller.currentStrokeWidth;
        _currentTool = widget.controller.currentTool;
        _lastDocForHold = doc;
        _lastPointerStamp = event.timeStamp;
      });
      _startHoldPoll();
      _notifyCaptureActive(true);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.isDrawingMode || _activePointers.length != 1) return;
    if (_currentSamples == null) return;

    final doc = _localToDocument(event.localPosition);
    final tool = _currentTool ?? widget.controller.currentTool;

    if (straightLineHoldAppliesToTool(tool) && !_holdTracker.isLocked) {
      final r = _holdTracker.tickMove(
        prevDoc: _lastDocForHold,
        prevStamp: _lastPointerStamp,
        currentDoc: doc,
        currentStamp: event.timeStamp,
      );
      if (r.justLocked) {
        _lockStraightLine(doc, _pressureForSample(event));
      }
    }

    _lastDocForHold = doc;
    _lastPointerStamp = event.timeStamp;

    setState(() {
      if (!_holdTracker.isLocked) {
        _currentSamples!.add(StrokeSample(doc.dx, doc.dy, _pressureForSample(event)));
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_currentSamples != null) {
      _commitAndClearInProgress();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _discardInProgress();
  }

  void _commitAndClearInProgress() {
    _cancelHoldPoll();
    final samples = _currentSamples;
    if (samples == null || samples.isEmpty) {
      setState(() {
        _currentSamples = null;
        _currentColor = null;
        _currentStrokeWidth = null;
        _currentTool = null;
        _holdTracker.reset();
        _clearStraightLock();
      });
      _notifyCaptureActive(false);
      return;
    }

    final tool = _currentTool ?? widget.controller.currentTool;
    final locked = _straightLockedStart != null &&
        _straightLockedEnd != null &&
        straightLineHoldAppliesToTool(tool);

    final committedSamples = locked
        ? <StrokeSample>[_straightLockedStart!, _straightLockedEnd!]
        : List<StrokeSample>.from(samples);

    final stroke = Stroke(
      samples: committedSamples,
      color: _currentColor ?? widget.controller.currentColor,
      strokeWidth: _currentStrokeWidth ?? widget.controller.currentStrokeWidth,
      tool: tool,
      pressureEnabled: locked ? false : widget.controller.pressureEnabled,
    );
    widget.controller.addStroke(stroke);
    setState(() {
      _currentSamples = null;
      _currentColor = null;
      _currentStrokeWidth = null;
      _currentTool = null;
      _holdTracker.reset();
      _clearStraightLock();
    });
    _notifyCaptureActive(false);
  }

  void _discardInProgress() {
    _cancelHoldPoll();
    if (_currentSamples == null) return;
    setState(() {
      _currentSamples = null;
      _currentColor = null;
      _currentStrokeWidth = null;
      _currentTool = null;
      _holdTracker.reset();
      _clearStraightLock();
    });
    _notifyCaptureActive(false);
  }

  Stroke? get _previewStroke {
    final s = _currentSamples;
    if (s == null || s.isEmpty) return null;
    final tool = _currentTool ?? widget.controller.currentTool;
    final locked = _straightLockedStart != null &&
        _straightLockedEnd != null &&
        straightLineHoldAppliesToTool(tool);

    final previewSamples = locked
        ? <StrokeSample>[_straightLockedStart!, _straightLockedEnd!]
        : List<StrokeSample>.from(s);

    return Stroke(
      samples: previewSamples,
      color: _currentColor ?? widget.controller.currentColor,
      strokeWidth: _currentStrokeWidth ?? widget.controller.currentStrokeWidth,
      tool: tool,
      pressureEnabled: locked ? false : widget.controller.pressureEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: CustomPaint(
        painter: DrawPainter(
          strokes: widget.controller.strokes,
          currentStroke: _previewStroke,
          documentTransform: widget.documentTransform,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  DrawPainter({
    required this.strokes,
    this.currentStroke,
    required this.documentTransform,
  });

  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Matrix4 documentTransform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(documentTransform.storage);
    for (final stroke in strokes) {
      StrokeRenderer.render(canvas, stroke);
    }
    if (currentStroke != null) {
      StrokeRenderer.render(canvas, currentStroke!, isPreview: true);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        !MatrixUtils.matrixEquals(
          documentTransform,
          oldDelegate.documentTransform,
        );
  }
}
