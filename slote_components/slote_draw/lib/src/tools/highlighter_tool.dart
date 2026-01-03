import 'package:flutter/material.dart';
import '../stroke/stroke.dart';

/// Highlighter tool for highlighting
class HighlighterTool {
  static Stroke createStroke(
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    return Stroke(
      points: points,
      color: color.withOpacity(0.3), // Semi-transparent for highlighting
      strokeWidth: strokeWidth,
      tool: DrawTool.highlighter,
    );
  }
}

