import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:convert';
import 'dart:math' as math;

/// Simple pixel detector that only logs touched pixels
class PixelDetector extends StatefulWidget {
  const PixelDetector({
    super.key,
    required this.child,
    this.onPixelTouched,
    this.drawingData,
  });

  final Widget child;
  final Function(Offset pixel)? onPixelTouched;
  final String? drawingData; // JSON string from the note

  @override
  State<PixelDetector> createState() => _PixelDetectorState();
}

class _PixelDetectorState extends State<PixelDetector> {
  final List<Offset> touchedPixels = [];
  List<Offset> drawingPixels = []; // Pixels from the stored drawing data

  @override
  void initState() {
    super.initState();
    // Log the initial drawing data
    if (widget.drawingData != null && widget.drawingData!.isNotEmpty) {
      log('Initial drawing data JSON: ${widget.drawingData}');
    } else {
      log('No initial drawing data provided');
    }
    _extractDrawingPixels();
  }

  @override
  void didUpdateWidget(PixelDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawingData != widget.drawingData) {
      _extractDrawingPixels();
    }
  }

  void _extractDrawingPixels() {
    drawingPixels.clear();

    if (widget.drawingData == null || widget.drawingData!.isEmpty) {
      return;
    }

    try {
      final List<dynamic> drawingJson = json.decode(widget.drawingData!);

      for (final dynamic item in drawingJson) {
        if (item is Map<String, dynamic>) {
          final String type = item['type'] as String;

          switch (type) {
            case 'StraightLine':
              _extractStraightLinePixels(item);
              break;
            case 'SimpleLine':
              _extractSimpleLinePixels(item);
              break;
            case 'Rectangle':
              _extractRectanglePixels(item);
              break;
            case 'Circle':
              _extractCirclePixels(item);
              break;
            // Note: Skip Eraser as it removes pixels rather than adds them
            default:
              log('Unknown drawing type for pixel extraction: $type');
          }
        }
      }

      log('Extracted ${drawingPixels.length} pixels from drawing data');
    } catch (e) {
      log('Error extracting drawing pixels: $e');
    }
  }

  void _extractStraightLinePixels(Map<String, dynamic> data) {
    final startPoint = data['startPoint'] as Map<String, dynamic>;
    final endPoint = data['endPoint'] as Map<String, dynamic>;

    final start = Offset(
      startPoint['dx'] as double,
      startPoint['dy'] as double,
    );
    final end = Offset(endPoint['dx'] as double, endPoint['dy'] as double);

    // Simple line interpolation - you might want to make this more sophisticated
    final distance = (end - start).distance;
    final steps = distance.round();

    for (int i = 0; i <= steps; i++) {
      final t = steps > 0 ? i / steps : 0.0;
      final point = Offset.lerp(start, end, t)!;
      final pixelOffset = Offset(
        point.dx.round().toDouble(),
        point.dy.round().toDouble(),
      );

      if (!drawingPixels.contains(pixelOffset)) {
        drawingPixels.add(pixelOffset);
      }
    }
  }

  void _extractSimpleLinePixels(Map<String, dynamic> data) {
    final path = data['path'] as List<dynamic>;

    for (final point in path) {
      if (point is Map<String, dynamic>) {
        final offset = Offset(point['dx'] as double, point['dy'] as double);
        final pixelOffset = Offset(
          offset.dx.round().toDouble(),
          offset.dy.round().toDouble(),
        );

        if (!drawingPixels.contains(pixelOffset)) {
          drawingPixels.add(pixelOffset);
        }
      }
    }
  }

  void _extractRectanglePixels(Map<String, dynamic> data) {
    // Extract rectangle outline pixels
    final rect = data['rect'] as Map<String, dynamic>;
    final left = rect['left'] as double;
    final top = rect['top'] as double;
    final right = rect['right'] as double;
    final bottom = rect['bottom'] as double;

    // Add rectangle outline pixels
    for (double x = left; x <= right; x++) {
      drawingPixels.add(Offset(x.round().toDouble(), top.round().toDouble()));
      drawingPixels.add(
        Offset(x.round().toDouble(), bottom.round().toDouble()),
      );
    }

    for (double y = top; y <= bottom; y++) {
      drawingPixels.add(Offset(left.round().toDouble(), y.round().toDouble()));
      drawingPixels.add(Offset(right.round().toDouble(), y.round().toDouble()));
    }
  }

  void _extractCirclePixels(Map<String, dynamic> data) {
    // Extract circle outline pixels
    final center = data['center'] as Map<String, dynamic>;
    final radius = data['radius'] as double;

    final centerPoint = Offset(center['dx'] as double, center['dy'] as double);

    // Simple circle pixel extraction using trigonometry
    for (int angle = 0; angle < 360; angle++) {
      final radians = angle * (3.14159 / 180);
      final x = centerPoint.dx + radius * cos(radians);
      final y = centerPoint.dy + radius * sin(radians);
      final pixelOffset = Offset(x.round().toDouble(), y.round().toDouble());

      if (!drawingPixels.contains(pixelOffset)) {
        drawingPixels.add(pixelOffset);
      }
    }
  }

  double cos(double radians) => math.cos(radians);
  double sin(double radians) => math.sin(radians);

  void _capturePixel(Offset point) {
    // Round to actual pixel coordinates
    final pixelX = point.dx.round();
    final pixelY = point.dy.round();
    final pixelOffset = Offset(pixelX.toDouble(), pixelY.toDouble());

    // Avoid duplicate consecutive pixels
    if (touchedPixels.isEmpty || touchedPixels.last != pixelOffset) {
      touchedPixels.add(pixelOffset);

      // Check if this pixel exists in the drawing data
      final isDrawingPixel = drawingPixels.contains(pixelOffset);

      // Log the touched pixel
      log(
        'Touched Pixel: x=$pixelX, y=$pixelY ${isDrawingPixel ? "(DRAWING PIXEL)" : "(EMPTY SPACE)"}',
      );
      log('Total pixels touched: ${touchedPixels.length}');

      // Callback if provided
      widget.onPixelTouched?.call(pixelOffset);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _capturePixel(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _capturePixel(details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    log('Touch ended - Total unique pixels: ${touchedPixels.length}');
  }

  void _handleTap(TapDownDetails details) {
    _capturePixel(details.localPosition);
    log(
      'Single tap at pixel: x=${details.localPosition.dx.round()}, y=${details.localPosition.dy.round()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: widget.child,
    );
  }
}

/// Extension methods for easy usage
extension PixelDetectorExtension on Widget {
  Widget withPixelDetection({
    Function(Offset pixel)? onPixelTouched,
    String? drawingData,
  }) {
    return PixelDetector(
      onPixelTouched: onPixelTouched,
      drawingData: drawingData,
      child: this,
    );
  }
}
