import 'package:flutter/material.dart';

import '../draw_tool.dart';

/// One sample of a stroke in **document space** (see [Stroke]).
class StrokeSample {
  const StrokeSample(this.x, this.y, [this.pressure]);

  final double x;
  final double y;

  /// Normalized 0–1, or null to let [perfect_freehand] simulate from spacing.
  final double? pressure;

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (pressure != null) 'p': pressure,
      };

  factory StrokeSample.fromJson(Map<String, dynamic> json) {
    return StrokeSample(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['p'] as num?)?.toDouble(),
    );
  }
}

/// A single ink stroke: immutable samples + style metadata.
class Stroke {
  Stroke({
    required List<StrokeSample> samples,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    this.pressureEnabled = true,
  }) : samples = List.unmodifiable(samples);

  final List<StrokeSample> samples;
  final Color color;
  final double strokeWidth;
  final DrawTool tool;

  /// When false, rendering uses uniform pressure (e.g. 0.5) — Wave C will toggle from UI.
  final bool pressureEnabled;

  Map<String, dynamic> toJson() {
    return {
      'samples': samples.map((s) => s.toJson()).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'tool': tool.name,
      'pressureEnabled': pressureEnabled,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    final tool = parseDrawTool(json['tool']);

    if (json['samples'] != null) {
      final list = json['samples'] as List;
      return Stroke(
        samples: list
            .map((e) => StrokeSample.fromJson(e as Map<String, dynamic>))
            .toList(),
        color: Color(json['color'] as int),
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        tool: tool,
        pressureEnabled: json['pressureEnabled'] as bool? ?? true,
      );
    }

    // Legacy: `points` only, no per-sample pressure.
    final points = json['points'] as List;
    return Stroke(
      samples: points
          .map(
            (p) => StrokeSample(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
              null,
            ),
          )
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      tool: tool,
      pressureEnabled: false,
    );
  }
}
