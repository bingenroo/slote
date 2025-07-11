import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExtendedDrawingController extends DrawingController {
  ExtendedDrawingController({super.config, super.content});

  void removeLastContent() {
    final history = getHistory;
    if (history.isNotEmpty &&
        currentIndex > 0 &&
        currentIndex <= history.length) {
      history.removeAt(currentIndex - 1);
      // Adjust currentIndex if needed
      // If currentIndex > history.length, set it to history.length
      if (currentIndex > history.length) {
        // ignore: invalid_use_of_protected_member
        super.drawConfig.value =
            super.drawConfig.value.copyWith(); // or update as needed
      }
      cachedImage = null;
      notifyListeners();
    }
  }

  void removeContentAtPixel(Offset pixel, {double tolerance = 2.0}) {
    final history = getHistory;
    if (history.isEmpty) return;

    // Get the drawing data as JSON
    final List<dynamic> drawingJson = getJsonList();
    int? matchIndex;

    bool isWithinTolerance(Offset a, Offset b) => (a - b).distance <= tolerance;

    // Helper functions for each stroke type
    bool strokeContainsPixel(Map<String, dynamic> item) {
      final String type = item['type'] as String;
      switch (type) {
        case 'StraightLine':
          final startPoint = item['startPoint'] as Map<String, dynamic>;
          final endPoint = item['endPoint'] as Map<String, dynamic>;
          final start = Offset(
            startPoint['dx'] as double,
            startPoint['dy'] as double,
          );
          final end = Offset(
            endPoint['dx'] as double,
            endPoint['dy'] as double,
          );
          final distance = (end - start).distance;
          final steps = distance.round();
          for (int i = 0; i <= steps; i++) {
            final t = steps > 0 ? i / steps : 0.0;
            final point = Offset.lerp(start, end, t)!;
            if (isWithinTolerance(point, pixel)) {
              return true;
            }
          }
          return false;
        case 'SimpleLine':
          final path = item['path'] as Map<String, dynamic>;
          final steps = path['steps'] as List<dynamic>;
          for (final step in steps) {
            if (step is Map<String, dynamic> &&
                (step['type'] == 'moveTo' || step['type'] == 'lineTo')) {
              final x = step['x'] as double;
              final y = step['y'] as double;
              if (isWithinTolerance(Offset(x, y), pixel)) {
                return true;
              }
            }
          }
          return false;
        case 'Rectangle':
          final rect = item['rect'] as Map<String, dynamic>;
          final left = rect['left'] as double;
          final top = rect['top'] as double;
          final right = rect['right'] as double;
          final bottom = rect['bottom'] as double;
          // Check border pixels only (as in pixel_detector)
          for (double x = left; x <= right; x++) {
            if (isWithinTolerance(Offset(x, top), pixel) ||
                isWithinTolerance(Offset(x, bottom), pixel)) {
              return true;
            }
          }
          for (double y = top; y <= bottom; y++) {
            if (isWithinTolerance(Offset(left, y), pixel) ||
                isWithinTolerance(Offset(right, y), pixel)) {
              return true;
            }
          }
          return false;
        case 'Circle':
          final center = item['center'] as Map<String, dynamic>;
          final radius = item['radius'] as double;
          final centerPoint = Offset(
            center['dx'] as double,
            center['dy'] as double,
          );
          for (int angle = 0; angle < 360; angle++) {
            final radians = angle * (3.14159 / 180);
            final x = centerPoint.dx + radius * math.cos(radians);
            final y = centerPoint.dy + radius * math.sin(radians);
            if (isWithinTolerance(Offset(x, y), pixel)) return true;
          }
          return false;
        default:
          return false;
      }
    }

    for (int i = 0; i < drawingJson.length; i++) {
      final item = drawingJson[i];
      if (item is Map<String, dynamic> && strokeContainsPixel(item)) {
        matchIndex = i;
        break;
      }
    }

    if (matchIndex != null && matchIndex < history.length) {
      history.removeAt(matchIndex);
      cachedImage = null;
      notifyListeners();
    }
  }
}
