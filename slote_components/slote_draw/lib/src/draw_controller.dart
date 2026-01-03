import 'package:flutter/material.dart';
import 'stroke/stroke.dart';
import 'tools/pen_tool.dart';

/// Controller for drawing operations
class DrawController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  DrawTool _currentTool = DrawTool.pen;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  DrawTool get currentTool => _currentTool;

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

  void addStroke(Stroke stroke) {
    _strokes.add(stroke);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
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

enum DrawTool {
  pen,
  eraser,
  highlighter,
  shape,
}

