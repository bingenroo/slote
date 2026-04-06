import 'package:flutter/material.dart';

import 'draw_tool.dart';
import 'eraser_mode.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_eraser_split.dart';
import 'stroke/stroke_hit_geometry.dart';

class _InkUndoRedoListenable extends ChangeNotifier {
  void notifyHistoryChanged() => notifyListeners();
}

/// Controller for drawing operations.
///
/// **Persistence:** [toJson] / [fromJson] include a top-level `schemaVersion`.
/// Bump the emitted `schemaVersion` when the envelope shape changes and add a branch
/// in [fromJson] to migrate older maps. Stroke-level legacy (`points` vs
/// `samples`, tool strings, etc.) stays tolerant inside [Stroke.fromJson].
class DrawController extends ChangeNotifier {
  DrawController({this.maxUndoLevels = 50}) : assert(maxUndoLevels >= 1);

  /// Max undo steps retained; oldest entries are dropped when exceeded.
  final int maxUndoLevels;

  final List<Stroke> _strokes = [];
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];
  final _InkUndoRedoListenable _inkHistory = _InkUndoRedoListenable();

  int _inkGroupDepth = 0;
  List<Stroke>? _preGroupSnapshot;

  bool _lastCanUndo = false;
  bool _lastCanRedo = false;

  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  DrawTool _currentTool = DrawTool.pen;
  bool _pressureEnabled = true;
  EraserMode _eraserMode = EraserMode.pixel;
  double _eraserDiameterDoc = kDefaultEraserDiameterDoc;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  DrawTool get currentTool => _currentTool;
  bool get pressureEnabled => _pressureEnabled;
  double get eraserDiameterDoc => _eraserDiameterDoc;

  /// Whole-stroke vs polyline-split erasure (see [eraseStrokesHitByEraserPath]).
  EraserMode get eraserMode => _eraserMode;

  /// Notifies when [canUndo] / [canRedo] may have changed (ink history only).
  Listenable get undoRedoListenable => _inkHistory;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Begins a batch of eraser mutations (one undo step for the whole gesture).
  /// Pair with [endInkUndoGroup]. Nesting increments depth; only the outermost
  /// closing finalizes.
  void beginInkUndoGroup() {
    if (_inkGroupDepth == 0) {
      _preGroupSnapshot = _snapshotStrokes();
    }
    _inkGroupDepth++;
  }

  /// Ends an eraser batch started with [beginInkUndoGroup].
  void endInkUndoGroup() {
    if (_inkGroupDepth == 0) return;
    _inkGroupDepth--;
    if (_inkGroupDepth != 0) return;
    final before = _preGroupSnapshot;
    _preGroupSnapshot = null;
    if (before == null) return;
    if (_strokesContentEquals(before, _strokes)) return;
    _pushUndoSnapshot(before);
    _redoStack.clear();
    _notifyInkHistoryMaybeChanged();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshotStrokes());
    final prev = _undoStack.removeLast();
    _replaceStrokesWith(prev);
    notifyListeners();
    _notifyInkHistoryMaybeChanged();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshotStrokes());
    if (_undoStack.length > maxUndoLevels) {
      _undoStack.removeAt(0);
    }
    final next = _redoStack.removeLast();
    _replaceStrokesWith(next);
    notifyListeners();
    _notifyInkHistoryMaybeChanged();
  }

  List<Stroke> _snapshotStrokes() => List<Stroke>.from(_strokes);

  void _replaceStrokesWith(List<Stroke> next) {
    _strokes
      ..clear()
      ..addAll(next);
  }

  void _pushUndoSnapshot(List<Stroke> snapshot) {
    if (_undoStack.length >= maxUndoLevels) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(snapshot);
  }

  void _recordInkMutationStart() {
    assert(
      _inkGroupDepth == 0,
      'Use beginInkUndoGroup/endInkUndoGroup for batched eraser gestures',
    );
    _pushUndoSnapshot(_snapshotStrokes());
    _redoStack.clear();
  }

  void _notifyInkHistoryMaybeChanged() {
    final cu = canUndo;
    final cr = canRedo;
    if (cu != _lastCanUndo || cr != _lastCanRedo) {
      _lastCanUndo = cu;
      _lastCanRedo = cr;
      _inkHistory.notifyHistoryChanged();
    }
  }

  void _clearInkHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _inkGroupDepth = 0;
    _preGroupSnapshot = null;
    _notifyInkHistoryMaybeChanged();
  }

  static bool _strokesContentEquals(List<Stroke> a, List<Stroke> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_strokeEquals(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _strokeEquals(Stroke a, Stroke b) {
    if (a.color != b.color ||
        a.strokeWidth != b.strokeWidth ||
        a.tool != b.tool ||
        a.pressureEnabled != b.pressureEnabled) {
      return false;
    }
    if (a.samples.length != b.samples.length) return false;
    for (var i = 0; i < a.samples.length; i++) {
      final sa = a.samples[i];
      final sb = b.samples[i];
      if (sa.x != sb.x || sa.y != sb.y || sa.pressure != sb.pressure) {
        return false;
      }
    }
    return true;
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void setTool(DrawTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setPressureEnabled(bool enabled) {
    if (_pressureEnabled == enabled) return;
    _pressureEnabled = enabled;
    notifyListeners();
  }

  void setEraserMode(EraserMode mode) {
    if (_eraserMode == mode) return;
    _eraserMode = mode;
    notifyListeners();
  }

  void setEraserDiameterDoc(double diameterDoc) {
    final next = diameterDoc.clamp(1.0, 512.0).toDouble();
    if (_eraserDiameterDoc == next) return;
    _eraserDiameterDoc = next;
    notifyListeners();
  }

  void addStroke(Stroke stroke) {
    assert(_inkGroupDepth == 0);
    _recordInkMutationStart();
    _strokes.add(stroke);
    notifyListeners();
    _notifyInkHistoryMaybeChanged();
  }

  void clear() {
    assert(_inkGroupDepth == 0);
    if (_strokes.isEmpty) return;
    _recordInkMutationStart();
    _strokes.clear();
    notifyListeners();
    _notifyInkHistoryMaybeChanged();
  }

  /// Erases ink along [path] using [eraserMode]: [EraserMode.stroke] removes
  /// whole pen/highlighter strokes when hit; [EraserMode.pixel] splits the
  /// centerline (Wave D2). Footprint: [eraserDiameterDoc] + ink half-width.
  /// Other tools are unchanged.
  void eraseStrokesHitByEraserPath(List<StrokeSample> path) {
    if (path.isEmpty) return;

    if (_eraserMode == EraserMode.stroke) {
      final wouldChange = _strokes.any(
        (s) => strokeHitByEraserPath(
          s,
          path,
          eraserDiameterDoc: _eraserDiameterDoc,
        ),
      );
      if (!wouldChange) return;
      if (_inkGroupDepth == 0) {
        _recordInkMutationStart();
      }
      _strokes.removeWhere(
        (s) => strokeHitByEraserPath(
          s,
          path,
          eraserDiameterDoc: _eraserDiameterDoc,
        ),
      );
      notifyListeners();
      _notifyInkHistoryMaybeChanged();
      return;
    }

    var hit = false;
    for (final s in _strokes) {
      if (strokeHitByEraserPath(
        s,
        path,
        eraserDiameterDoc: _eraserDiameterDoc,
      )) {
        hit = true;
        break;
      }
    }
    if (!hit) return;

    if (_inkGroupDepth == 0) {
      _recordInkMutationStart();
    }

    final out = <Stroke>[];
    for (final s in _strokes) {
      if (s.tool != DrawTool.pen && s.tool != DrawTool.highlighter) {
        out.add(s);
        continue;
      }
      if (!strokeHitByEraserPath(
        s,
        path,
        eraserDiameterDoc: _eraserDiameterDoc,
      )) {
        out.add(s);
        continue;
      }
      out.addAll(
        splitStrokeByEraserPath(s, path, eraserDiameterDoc: _eraserDiameterDoc),
      );
    }

    _strokes
      ..clear()
      ..addAll(out);
    notifyListeners();
    _notifyInkHistoryMaybeChanged();
  }

  static const int _currentSchemaVersion = 1;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': _currentSchemaVersion,
      'strokes': _strokes.map((s) => s.toJson()).toList(),
      'eraserMode': _eraserMode.name,
      'eraserDiameterDoc': _eraserDiameterDoc,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _clearInkHistory();
    _strokes.clear();

    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final Map<String, dynamic> payload = switch (schemaVersion) {
      1 => json,
      // case 2: return _migrateDrawingJsonV2(json); …
      _ => json, // Unknown / future: best-effort if shape matches v1.
    };

    if (payload['strokes'] != null) {
      final strokesList = payload['strokes'] as List;
      // Drop legacy Wave A–C eraser "strokes" (transparent, never rendered).
      _strokes.addAll(
        strokesList
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .where((s) => s.tool != DrawTool.eraser),
      );
    }
    final modeName = payload['eraserMode'] as String?;
    if (modeName != null) {
      _eraserMode = switch (modeName) {
        'stroke' => EraserMode.stroke,
        'pixel' => EraserMode.pixel,
        _ => EraserMode.pixel,
      };
    }
    final eraserDiameterDoc =
        (payload['eraserDiameterDoc'] as num?)?.toDouble();
    if (eraserDiameterDoc != null) {
      _eraserDiameterDoc = eraserDiameterDoc;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _inkHistory.dispose();
    super.dispose();
  }
}
