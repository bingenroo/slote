import 'package:flutter/material.dart';

import 'draw_tool.dart';
import 'stroke/stroke.dart';

/// Controller for drawing operations
class DrawController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  DrawTool _currentTool = DrawTool.pen;
  bool _pressureEnabled = true;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  DrawTool get currentTool => _currentTool;
  bool get pressureEnabled => _pressureEnabled;

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

  void addStroke(Stroke stroke) {
    _strokes.add(stroke);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  static const int _currentSchemaVersion = 1;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': _currentSchemaVersion,
      'strokes': _strokes.map((s) => s.toJson()).toList(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _strokes.clear();
    if (json['strokes'] != null) {
      final strokesList = json['strokes'] as List;
      _strokes.addAll(
        strokesList.map((s) => Stroke.fromJson(s as Map<String, dynamic>)),
      );
    }
    notifyListeners();
  }
}
