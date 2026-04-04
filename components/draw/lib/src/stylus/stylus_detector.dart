import 'package:flutter/gestures.dart';

/// Detects stylus input
class StylusDetector {
  static bool isStylus(PointerEvent event) {
    // Check if the pointer is a stylus
    // This is a placeholder - actual implementation depends on platform
    return event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  static double? getPressure(PointerEvent event) {
    // Get pressure from stylus
    // This is a placeholder - actual implementation depends on platform
    if (isStylus(event)) {
      return event.pressure;
    }
    return null;
  }
}
