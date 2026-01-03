import 'package:flutter/material.dart';

/// Handles pressure sensitivity for stylus
class PressureHandler {
  static double calculateStrokeWidth(
    double baseWidth,
    double? pressure,
  ) {
    if (pressure == null) return baseWidth;

    // Map pressure (0.0 to 1.0) to stroke width
    // Pressure typically ranges from 0.0 to 1.0
    final minWidth = baseWidth * 0.5;
    final maxWidth = baseWidth * 2.0;

    return minWidth + (pressure * (maxWidth - minWidth));
  }

  static bool shouldApplyPalmRejection(PointerEvent event) {
    // Determine if palm rejection should be applied
    // This is a placeholder - actual implementation depends on platform
    return event.kind == PointerDeviceKind.touch &&
        event.pressure < 0.1; // Low pressure might indicate palm
  }
}

