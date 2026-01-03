import 'package:flutter/material.dart';
import '../draw_controller.dart';

/// Represents a single drawing stroke
class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawTool tool;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'tool': tool.toString(),
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double,
      tool: DrawTool.values.firstWhere(
        (t) => t.toString() == json['tool'],
        orElse: () => DrawTool.pen,
      ),
    );
  }
}

