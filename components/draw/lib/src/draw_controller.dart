import 'package:flutter/material.dart';

import 'draw_tool.dart';
import 'eraser_mode.dart';
import 'stroke/stroke.dart';
import 'stroke/stroke_eraser_split.dart';
import 'stroke/stroke_hit_geometry.dart';

/// Controller for drawing operations
class DrawController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  DrawTool _currentTool = DrawTool.pen;
  bool _pressureEnabled = true;
  EraserMode _eraserMode = EraserMode.pixel;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  DrawTool get currentTool => _currentTool;
  bool get pressureEnabled => _pressureEnabled;

  /// Whole-stroke vs polyline-split erasure (see [eraseStrokesHitByEraserPath]).
  EraserMode get eraserMode => _eraserMode;

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

  void addStroke(Stroke stroke) {
    _strokes.add(stroke);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// Erases ink along [path] using [eraserMode]: [EraserMode.stroke] removes
  /// whole pen/highlighter strokes when hit; [EraserMode.pixel] splits the
  /// centerline (Wave D2). Footprint: [kDefaultEraserDiameterDoc] + ink
  /// half-width. Other tools are unchanged.
  void eraseStrokesHitByEraserPath(List<StrokeSample> path) {
    if (path.isEmpty) return;

    if (_eraserMode == EraserMode.stroke) {
      final before = _strokes.length;
      _strokes.removeWhere((s) => strokeHitByEraserPath(s, path));
      if (_strokes.length != before) notifyListeners();
      return;
    }

    var hit = false;
    for (final s in _strokes) {
      if (strokeHitByEraserPath(s, path)) {
        hit = true;
        break;
      }
    }
    if (!hit) return;

    final out = <Stroke>[];
    for (final s in _strokes) {
      if (s.tool != DrawTool.pen && s.tool != DrawTool.highlighter) {
        out.add(s);
        continue;
      }
      if (!strokeHitByEraserPath(s, path)) {
        out.add(s);
        continue;
      }
      out.addAll(splitStrokeByEraserPath(s, path));
    }

    _strokes
      ..clear()
      ..addAll(out);
    notifyListeners();
  }

  static const int _currentSchemaVersion = 1;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': _currentSchemaVersion,
      'strokes': _strokes.map((s) => s.toJson()).toList(),
      'eraserMode': _eraserMode.name,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _strokes.clear();
    if (json['strokes'] != null) {
      final strokesList = json['strokes'] as List;
      // Drop legacy Wave A–C eraser "strokes" (transparent, never rendered).
      _strokes.addAll(
        strokesList
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .where((s) => s.tool != DrawTool.eraser),
      );
    }
    final modeName = json['eraserMode'] as String?;
    if (modeName != null) {
      _eraserMode = switch (modeName) {
        'stroke' => EraserMode.stroke,
        'pixel' => EraserMode.pixel,
        _ => EraserMode.pixel,
      };
    }
    notifyListeners();
  }
}
