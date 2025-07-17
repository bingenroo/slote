import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'spatial_index.dart';

class ExtendedDrawingController {
  final DrawingController _drawingController;
  final SpatialIndex _spatialIndex = SpatialIndex(50); // 50px grid
  List<Map<String, dynamic>> _strokes = [];

  ExtendedDrawingController(this._drawingController);

  void addNewStroke(Map<String, dynamic> stroke) {
    _strokes.add(stroke);
    final bounds = _calculateBounds(stroke);
    _spatialIndex.addStroke(_strokes.length - 1, bounds);
  }

  // Call this when the drawing changes
  void updateFromController() {
    initialize(_drawingController.getJsonList());
  }

  void initialize(List<Map<String, dynamic>> strokes) {
    _spatialIndex.clear();
    _strokes = strokes;
    for (int i = 0; i < strokes.length; i++) {
      final bounds = _calculateBounds(strokes[i]);
      _spatialIndex.addStroke(i, bounds);
    }
  }

  // In extended_drawing_controller.dart
  void trackNewStrokes(List<Map<String, dynamic>> currentStrokes) {
    // Compare with existing strokes to find new additions
    final newIndices = <int>[];
    for (int i = _strokes.length; i < currentStrokes.length; i++) {
      newIndices.add(i);
    }

    // Add new strokes to spatial index
    for (final index in newIndices) {
      final stroke = currentStrokes[index];
      _strokes.add(stroke);
      final bounds = _calculateBounds(stroke);
      _spatialIndex.addStroke(index, bounds);
    }
  }

  /// Process eraser points and remove matching drawing data
  /// Returns the updated drawing data after erasing
  List<Map<String, dynamic>> processEraserPoints(
    List<String> newPoints, {
    double eraserRadius = 16.0,
  }) {
    try {
      final List<Map<String, dynamic>> currentDrawingData =
          _drawingController.getJsonList();
      if (currentDrawingData.isEmpty) return [];
      final List<Offset> eraserPoints = _parsePoints(newPoints);
      // Find matching strokes using spatial index
      final indicesToRemove = _findMatchingStrokes(eraserPoints, eraserRadius);
      if (indicesToRemove.isNotEmpty) {
        _removeStrokesByIndices(indicesToRemove);
        initialize(_drawingController.getJsonList()); // Rebuild index
        return _drawingController.getJsonList();
      } else {
        return currentDrawingData;
      }
    } catch (e) {
      // log('Error processing eraser points: $e');
      return _drawingController.getJsonList();
    }
  }

  List<Offset> _parsePoints(List<String> pointStrings) {
    final List<Offset> points = [];
    for (final String pointStr in pointStrings) {
      try {
        final cleanStr = pointStr.replaceAll('(', '').replaceAll(')', '');
        final parts = cleanStr.split(',');
        if (parts.length == 2) {
          final double x = double.parse(parts[0].trim());
          final double y = double.parse(parts[1].trim());
          points.add(Offset(x, y));
        }
      } catch (_) {}
    }
    return points;
  }

  List<int> _findMatchingStrokes(List<Offset> eraserPath, double eraserRadius) {
    // log('Processing eraser at: ${eraserPath.last}');
    // log('Current strokes: ${_strokes.length}');
    // log(
    //   'Candidates found: ${_spatialIndex.getCandidates(eraserPath.last, eraserRadius).length}',
    // );
    final candidates = <int>{};
    for (final point in eraserPath) {
      candidates.addAll(_spatialIndex.getCandidates(point, eraserRadius));
    }
    return candidates
        .where(
          (i) => _strokeIntersectsEraser(_strokes[i], eraserPath, eraserRadius),
        )
        .toList();
  }

  bool _strokeIntersectsEraser(
    Map<String, dynamic> stroke,
    List<Offset> eraserPath,
    double eraserRadius,
  ) {
    switch (stroke['type']) {
      case 'StraightLine':
        final start = _parseOffset(stroke['startPoint']);
        final end = _parseOffset(stroke['endPoint']);
        return _lineIntersects(start, end, eraserPath, eraserRadius);
      case 'SimpleLine':
        final path = stroke['path'];
        if (path is Map<String, dynamic>) {
          final steps = path['steps'];
          if (steps != null && steps is List) {
            for (int i = 1; i < steps.length; i++) {
              final p1 = _parseOffsetFromStep(steps[i - 1]);
              final p2 = _parseOffsetFromStep(steps[i]);
              if (_lineIntersects(p1, p2, eraserPath, eraserRadius)) {
                return true;
              }
            }
          }
        }
        return false;
      case 'Rectangle':
        final start = _parseOffset(stroke['startPoint']);
        final end = _parseOffset(stroke['endPoint']);
        final corners = [
          start,
          Offset(end.dx, start.dy),
          end,
          Offset(start.dx, end.dy),
        ];
        for (int i = 0; i < 4; i++) {
          if (_lineIntersects(
            corners[i],
            corners[(i + 1) % 4],
            eraserPath,
            eraserRadius,
          ))
            return true;
        }
        return false;
      case 'Circle':
        final center = _parseOffset(stroke['center']);
        final r = (stroke['radius'] ?? 0);
        final double radiusValue = (r is num) ? r.toDouble() : 0.0;
        for (final e in eraserPath) {
          if ((center - e).distance <= radiusValue + eraserRadius) return true;
        }
        return false;
      default:
        return false;
    }
  }

  bool _lineIntersects(
    Offset p1,
    Offset p2,
    List<Offset> eraserPath,
    double radius,
  ) {
    for (final center in eraserPath) {
      if (_circleIntersectsLine(center, radius, p1, p2)) return true;
    }
    return false;
  }

  bool _circleIntersectsLine(
    Offset center,
    double radius,
    Offset p1,
    Offset p2,
  ) {
    final lineVec = p2 - p1;
    final toCenter = center - p1;
    final lineLength = lineVec.distance;
    if (lineLength == 0) return (center - p1).distance <= radius;
    final norm = lineVec / lineLength;
    final proj = toCenter.dx * norm.dx + toCenter.dy * norm.dy;
    final closest = proj.clamp(0, lineLength);
    final closestPoint =
        p1 + norm * (closest is double ? closest : closest.toDouble());
    return (center - closestPoint).distance <= radius;
  }

  Offset _parseOffset(Map? map) {
    if (map == null) return Offset.zero;
    final dx = map['dx'] ?? 0.0;
    final dy = map['dy'] ?? 0.0;
    return Offset(dx.toDouble(), dy.toDouble());
  }

  Offset _parseOffsetFromStep(Map? step) {
    if (step == null) return Offset.zero;
    final x = step['x'] ?? 0.0;
    final y = step['y'] ?? 0.0;
    return Offset(x.toDouble(), y.toDouble());
  }

  Rect _calculateBounds(Map<String, dynamic> stroke) {
    switch (stroke['type']) {
      case 'StraightLine':
        final start = _parseOffset(stroke['startPoint']);
        final end = _parseOffset(stroke['endPoint']);
        return Rect.fromPoints(start, end);
      case 'SimpleLine':
        final path = stroke['path'];
        if (path is Map<String, dynamic>) {
          final steps = path['steps'];
          if (steps != null && steps is List && steps.isNotEmpty) {
            double minX = double.infinity,
                minY = double.infinity,
                maxX = -double.infinity,
                maxY = -double.infinity;
            for (final step in steps) {
              final o = _parseOffsetFromStep(step);
              minX = math.min(minX, o.dx);
              minY = math.min(minY, o.dy);
              maxX = math.max(maxX, o.dx);
              maxY = math.max(maxY, o.dy);
            }
            return Rect.fromLTRB(minX, minY, maxX, maxY);
          }
        }
        return Rect.zero;
      case 'Rectangle':
        final start = _parseOffset(stroke['startPoint']);
        final end = _parseOffset(stroke['endPoint']);
        return Rect.fromPoints(start, end);
      case 'Circle':
        final center = _parseOffset(stroke['center']);
        final r = (stroke['radius'] ?? 0);
        final double radiusValue = (r is num) ? r.toDouble() : 0.0;
        return Rect.fromCircle(center: center, radius: radiusValue);
      default:
        return Rect.zero;
    }
  }

  void _removeStrokesByIndices(List<int> indicesToRemove) {
    indicesToRemove.sort((a, b) => b.compareTo(a));
    final List<PaintContent> history = List.from(_drawingController.getHistory);

    for (final index in indicesToRemove) {
      if (index < history.length) history.removeAt(index);
    }

    _drawingController.clear();
    if (history.isNotEmpty) _drawingController.addContents(history);

    // Rebuild spatial index with current data
    initialize(_drawingController.getJsonList());
  }
}
