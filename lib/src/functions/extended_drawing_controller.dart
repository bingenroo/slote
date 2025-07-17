import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

class ExtendedDrawingController {
  final DrawingController _drawingController;

  ExtendedDrawingController(this._drawingController);

  /// Process eraser points and remove matching drawing data
  /// Returns the updated drawing data after erasing
  List<Map<String, dynamic>> processEraserPoints(
    List<String> newPoints,
    double tolerance,
  ) {
    try {
      log(
        'Processing ${newPoints.length} eraser points with tolerance $tolerance',
      );

      // Get current drawing data from the controller
      final List<Map<String, dynamic>> currentDrawingData =
          _drawingController.getJsonList();

      if (currentDrawingData.isEmpty) {
        log('No drawing data to process');
        return [];
      }

      // log('Current drawing data has ${currentDrawingData.length} strokes');
      // log(currentDrawingData.toString());

      // Convert string points to Offset objects
      final List<Offset> eraserPoints = _parsePoints(newPoints);
      log('Parsed ${eraserPoints.length} eraser points');

      // Find matching strokes to remove
      final List<int> indicesToRemove = _findMatchingStrokes(
        currentDrawingData,
        eraserPoints,
        tolerance,
      );

      if (indicesToRemove.isNotEmpty) {
        log(
          'Removing ${indicesToRemove.length} strokes that match eraser area',
        );

        // Remove the matching strokes from the drawing controller

        _removeStrokesByIndices(indicesToRemove);

        // The drawing controller will automatically notify listeners when content changes

        // Return the updated drawing data
        return _drawingController.getJsonList();
      } else {
        log('No strokes match the eraser area');
        return currentDrawingData;
      }
    } catch (e) {
      log('Error processing eraser points: $e');
      return _drawingController.getJsonList();
    }
  }

  /// Parse string points to Offset objects
  List<Offset> _parsePoints(List<String> pointStrings) {
    final List<Offset> points = [];

    for (final String pointStr in pointStrings) {
      try {
        // Remove parentheses and split by comma
        final cleanStr = pointStr.replaceAll('(', '').replaceAll(')', '');
        final parts = cleanStr.split(',');

        if (parts.length == 2) {
          final double x = double.parse(parts[0].trim());
          final double y = double.parse(parts[1].trim());
          points.add(Offset(x, y));
        }
      } catch (e) {
        log('Error parsing point: $pointStr - $e');
      }
    }

    return points;
  }

  /// Find strokes that match the eraser points
  List<int> _findMatchingStrokes(
    List<Map<String, dynamic>> drawingData,
    List<Offset> eraserPoints,
    double tolerance,
  ) {
    final List<int> matchingIndices = [];

    for (int i = 0; i < drawingData.length; i++) {
      final Map<String, dynamic> stroke = drawingData[i];
      final String type = stroke['type'] as String;
      // log(stroke.toString());

      // Get points for this stroke based on its type
      final List<Offset> strokePoints = _getStrokePoints(stroke, type);
      // log(strokePoints.toString());

      // Check if any stroke points are within tolerance of eraser points
      if (_hasOverlap(strokePoints, eraserPoints, tolerance)) {
        matchingIndices.add(i);
        log('Stroke $i (type: $type) matches eraser area');
      } else {
        log('Stroke $i (type: $type) does NOT match eraser area');
      }
    }

    return matchingIndices;
  }

  /// Get points from a stroke based on its type
  List<Offset> _getStrokePoints(Map<String, dynamic> stroke, String type) {
    final List<Offset> points = [];

    try {
      switch (type) {
        case 'SimpleLine':
          final path = stroke['path'];
          if (path is Map<String, dynamic>) {
            final steps = path['steps'];
            if (steps != null && steps is List) {
              for (final step in steps) {
                if (step is Map<String, dynamic>) {
                  final x = step['x'];
                  final y = step['y'];
                  if (x != null && y != null) {
                    points.add(Offset(x.toDouble(), y.toDouble()));
                  }
                }
              }
            }
          }
          break;

        case 'StraightLine':
          final startPoint = stroke['startPoint'];
          final endPoint = stroke['endPoint'];
          if (startPoint is Map<String, dynamic> &&
              endPoint is Map<String, dynamic>) {
            final startDx = startPoint['dx'];
            final startDy = startPoint['dy'];
            final endDx = endPoint['dx'];
            final endDy = endPoint['dy'];

            if (startDx != null &&
                startDy != null &&
                endDx != null &&
                endDy != null) {
              points.add(Offset(startDx.toDouble(), startDy.toDouble()));
              points.add(Offset(endDx.toDouble(), endDy.toDouble()));
            }
          }
          break;

        case 'Rectangle':
          final startPoint = stroke['startPoint'];
          final endPoint = stroke['endPoint'];
          if (startPoint is Map<String, dynamic> &&
              endPoint is Map<String, dynamic>) {
            final startDx = startPoint['dx'];
            final startDy = startPoint['dy'];
            final endDx = endPoint['dx'];
            final endDy = endPoint['dy'];

            if (startDx != null &&
                startDy != null &&
                endDx != null &&
                endDy != null) {
              final startX = startDx.toDouble();
              final startY = startDy.toDouble();
              final endX = endDx.toDouble();
              final endY = endDy.toDouble();

              // Add rectangle corner points
              points.add(Offset(startX, startY));
              points.add(Offset(endX, startY));
              points.add(Offset(endX, endY));
              points.add(Offset(startX, endY));
            }
          }
          break;

        case 'Circle':
          final center = stroke['center'];
          final radius = stroke['radius'];
          if (center is Map<String, dynamic> && radius != null) {
            final centerDx = center['dx'];
            final centerDy = center['dy'];

            if (centerDx != null && centerDy != null) {
              final centerX = centerDx.toDouble();
              final centerY = centerDy.toDouble();
              final radiusValue = radius.toDouble();

              // Add points around the circle perimeter
              for (int i = 0; i < 16; i++) {
                final double angle = (2 * math.pi * i) / 16;
                final double x = centerX + radiusValue * math.cos(angle);
                final double y = centerY + radiusValue * math.sin(angle);
                points.add(Offset(x, y));
              }
            }
          }
          break;

        default:
          log('Unknown stroke type: $type');
      }
    } catch (e) {
      log('Error getting stroke points for type $type: $e');
    }

    return points;
  }

  /// Check if stroke points overlap with eraser points
  bool _hasOverlap(
    List<Offset> strokePoints,
    List<Offset> eraserPoints,
    double tolerance,
  ) {
    if (strokePoints.isEmpty) {
      log('No stroke points to check for overlap.');
    }
    if (eraserPoints.isEmpty) {
      log('No eraser points to check for overlap.');
    }
    for (final Offset strokePoint in strokePoints) {
      for (final Offset eraserPoint in eraserPoints) {
        final double distance = (strokePoint - eraserPoint).distance;
        if (distance <= tolerance) {
          log(
            'Overlap found: strokePoint=$strokePoint, eraserPoint=$eraserPoint, distance=$distance',
          );
          return true;
        }
      }
    }
    log('No overlap found for this stroke.');
    return false;
  }

  /// Remove strokes by their indices from the drawing controller
  void _removeStrokesByIndices(List<int> indicesToRemove) {
    // Sort indices in descending order to avoid index shifting issues
    indicesToRemove.sort((a, b) => b.compareTo(a));

    // Make a copy of the current history
    final List<PaintContent> history = List<PaintContent>.from(
      _drawingController.getHistory,
    );

    // Remove strokes from history
    for (final int index in indicesToRemove) {
      if (index < history.length) {
        history.removeAt(index);
      }
    }

    // Clear and rebuild the drawing controller
    _drawingController.clear();
    if (history.isNotEmpty) {
      _drawingController.addContents(history);
    }
  }
}
