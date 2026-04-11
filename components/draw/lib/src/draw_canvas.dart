import 'dart:async';

import 'package:flutter/material.dart';

import 'draw_controller.dart';
import 'draw_tool.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_renderer.dart';
import 'stroke/straight_line_snap.dart';
import 'stroke/stroke_eraser_visual.dart';

/// Canvas widget for drawing.
///
/// Strokes are stored in **document space**.
///
/// [documentTransform] is a **document → this widget's local** mapping used for
/// both sampling (local → document via inverse) and painting (document → local
/// via canvas transform).
///
/// **Integration note (important):**
///
/// - If this `DrawCanvas` is placed **inside the same `Transform`** as the
///   document/editor (e.g. under `ViewportSurface` / `ZoomPanSurface`), keep
///   [documentTransform] as **identity** (omit it). The viewport's transform
///   will already apply to both ink and text.
/// - If this `DrawCanvas` is an **overlay outside** that `Transform` (painted in
///   viewport coordinates), pass the live viewport matrix so ink stays "stuck to
///   paper" while zooming and panning.
///
/// **Multi-touch rule:** Two or more pointers **immediately** discard any
/// in-progress stroke — multi-touch is reserved for zoom/pan only.
///
/// **Wave C:** Speed + dwell straight line ([StraightLineHoldConfig]): slow
/// movement inside a hold radius for [StraightLineHoldConfig.dwellDuration]
/// locks a fixed two-point preview; commit matches that preview.
///
/// **Wave D:** [DrawTool.eraser] splits pen/highlighter strokes where the fixed
/// eraser disc overlaps ink (`kDefaultEraserDiameterDoc` in
/// `stroke_hit_geometry.dart`, `stroke_eraser_split.dart`); preview is one
/// "show touches" disc at the pointer; gestures are not stored as strokes.
///
/// **Wave E:** Eraser drags call [DrawController.beginInkUndoGroup] /
/// [DrawController.endInkUndoGroup] so live erase steps form **one** undo step.
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

  /// Called when in-progress stroke capture starts or ends (commit, cancel, or
  /// [isDrawingMode] turned off).
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

  /// True after eraser pointer-down opened an ink undo group (Wave E).
  bool _eraserInkUndoGroupOpen = false;

  /// Pointer id that owns the current in-progress stroke; commit only on its up.
  int? _drawingPointerId;

  // --- debug instrumentation (disabled) ---
  // import foundation kDebugMode when re-enabling.
  // int _dbgDownCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _cancelHoldPoll();
    if (_eraserInkUndoGroupOpen) {
      widget.controller.endInkUndoGroup();
      _eraserInkUndoGroupOpen = false;
    }
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

  void _endEraserInkUndoGroupIfOpen() {
    if (!_eraserInkUndoGroupOpen) return;
    widget.controller.endInkUndoGroup();
    _eraserInkUndoGroupOpen = false;
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
    _activePointers.add(event.pointer);

    // if (kDebugMode && _dbgDownCount < 25) {
    //   _dbgDownCount++;
    //   final scale = widget.documentTransform.getMaxScaleOnAxis();
    //   final t = widget.documentTransform.getTranslation();
    //   debugPrint(
    //     'DrawCanvas down#$_dbgDownCount ptr=${event.pointer} '
    //     'local=${event.localPosition} '
    //     'doc=${_localToDocument(event.localPosition)} '
    //     'activePointers=${_activePointers.length} '
    //     'scale=${scale.toStringAsFixed(3)} '
    //     'tx=${t.x.toStringAsFixed(1)} ty=${t.y.toStringAsFixed(1)} '
    //     'drawingMode=${widget.isDrawingMode}',
    //   );
    // }

    if (!widget.isDrawingMode) return;

    // Multi-touch rule: 2+ pointers = zoom/pan only, immediately discard.
    if (_activePointers.length > 1) {
      _discardInProgress();
      return;
    }

    final doc = _localToDocument(event.localPosition);
    final isEraser = widget.controller.currentTool == DrawTool.eraser;
    _drawingPointerId = event.pointer;
    setState(() {
      _holdTracker.reset();
      _clearStraightLock();
      _currentSamples = [
        StrokeSample(doc.dx, doc.dy, _pressureForSample(event)),
      ];
      _currentColor = widget.controller.currentColor;
      _currentStrokeWidth = widget.controller.currentStrokeWidth;
      _currentTool = widget.controller.currentTool;
      _lastDocForHold = doc;
      _lastPointerStamp = event.timeStamp;
    });
    if (isEraser) {
      widget.controller.beginInkUndoGroup();
      _eraserInkUndoGroupOpen = true;
    }
    _startHoldPoll();
    _notifyCaptureActive(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.isDrawingMode) return;
    if (_currentSamples == null) return;
    if (_activePointers.length > 1) return;
    if (event.pointer != _drawingPointerId) return;

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
        _currentSamples!.add(
          StrokeSample(doc.dx, doc.dy, _pressureForSample(event)),
        );
      }
    });

    if (tool == DrawTool.eraser) {
      final path = _currentSamples;
      if (path != null && path.isNotEmpty) {
        widget.controller.eraseStrokesHitByEraserPath(
          List<StrokeSample>.from(path),
        );
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final shouldCommit =
        _drawingPointerId == event.pointer && _currentSamples != null;
    _activePointers.remove(event.pointer);
    if (shouldCommit) {
      _commitAndClearInProgress();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (event.pointer == _drawingPointerId) {
      _discardInProgress();
    }
  }

  void _commitAndClearInProgress() {
    _cancelHoldPoll();
    final samples = _currentSamples;
    if (samples == null || samples.isEmpty) {
      setState(() {
        _drawingPointerId = null;
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
    final locked =
        _straightLockedStart != null &&
        _straightLockedEnd != null &&
        straightLineHoldAppliesToTool(tool);

    final committedSamples =
        locked
            ? <StrokeSample>[_straightLockedStart!, _straightLockedEnd!]
            : List<StrokeSample>.from(samples);

    if (tool == DrawTool.eraser) {
      widget.controller.eraseStrokesHitByEraserPath(committedSamples);
      _endEraserInkUndoGroupIfOpen();
      setState(() {
        _drawingPointerId = null;
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

    final stroke = Stroke(
      samples: committedSamples,
      color: _currentColor ?? widget.controller.currentColor,
      strokeWidth: _currentStrokeWidth ?? widget.controller.currentStrokeWidth,
      tool: tool,
      pressureEnabled: locked ? false : widget.controller.pressureEnabled,
    );
    widget.controller.addStroke(stroke);
    setState(() {
      _drawingPointerId = null;
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
    _drawingPointerId = null;
    if (_currentSamples == null) return;
    _endEraserInkUndoGroupIfOpen();
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
    final locked =
        _straightLockedStart != null &&
        _straightLockedEnd != null &&
        straightLineHoldAppliesToTool(tool);

    final previewSamples =
        locked
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
          eraserDiameterDoc: widget.controller.eraserDiameterDoc,
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
    required this.eraserDiameterDoc,
  });

  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Matrix4 documentTransform;
  final double eraserDiameterDoc;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(documentTransform.storage);
    for (final stroke in strokes) {
      StrokeRenderer.render(canvas, stroke);
    }
    if (currentStroke != null) {
      if (currentStroke!.tool == DrawTool.eraser) {
        paintEraserTouchVisual(
          canvas,
          currentStroke!.samples,
          eraserDiameterDoc: eraserDiameterDoc,
        );
      } else {
        StrokeRenderer.render(canvas, currentStroke!, isPreview: true);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.eraserDiameterDoc != eraserDiameterDoc ||
        !MatrixUtils.matrixEquals(
          documentTransform,
          oldDelegate.documentTransform,
        );
  }
}
