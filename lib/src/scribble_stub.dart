// Temporary stub file for scribble package types
// TODO: Replace with slote_draw implementation

import 'package:flutter/material.dart';
import 'dart:convert';

/// Stub for ScribbleNotifier
/// TODO: Replace with DrawController from slote_draw
class ScribbleNotifier extends ValueNotifier<dynamic> {
  ScribbleNotifier({
    Duration? straightLineHoldDuration,
    bool? enableStraightLineConversion,
  }) : super(_DrawingState());

  Sketch get currentSketch => Sketch();

  void setColor(Color color) {
    // Stub implementation
  }

  void setStrokeWidth(double width) {
    // Stub implementation
  }

  void setEraser() {
    value = Erasing();
  }

  void setSketch({required Sketch sketch, bool? addToUndoHistory}) {
    // Stub implementation
  }
}

/// Stub for Erasing state
class Erasing {
  Erasing();
}

/// Stub for Sketch
class Sketch {
  final List<dynamic> lines;

  Sketch({List<dynamic>? lines}) : lines = lines ?? [];

  Map<String, dynamic> toJson() {
    return {
      'lines': lines,
    };
  }

  static Sketch fromJson(Map<String, dynamic> json) {
    return Sketch(
      lines: json['lines'] as List<dynamic>? ?? [],
    );
  }
}

/// Stub for DrawingState
class _DrawingState {}

