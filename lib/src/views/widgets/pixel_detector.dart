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
    this.onElementRemoved,
  });

  final Widget child;
  final Function(Offset pixel)? onPixelTouched;
  final String? drawingData; // JSON string from the note
  final Function(Map<String, dynamic> element)? onElementRemoved;

  @override
  State<PixelDetector> createState() => _PixelDetectorState();
}

class _PixelDetectorState extends State<PixelDetector> {
  final List<Offset> touchedPixels = [];
  List<Offset> drawingPixels = []; // Pixels from the stored drawing data

  @override
  void initState() {
    super.initState();
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
      // Debug print the drawing data
      // log('[PixelDetector] Drawing data: ${widget.drawingData!}');

      for (final dynamic item in drawingJson) {
        if (item is Map<String, dynamic>) {
          final String type = item['type'] as String;

          if (type == 'NoOp') continue; // Ignore NoOp types

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
            default:
              log('Unknown drawing type for pixel extraction: $type');
          }
        }
      }

      log(
        'Extracted  [32m${drawingPixels.length} [0m pixels from drawing data',
      );
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
    final path = data['path'] as Map<String, dynamic>;
    final steps = path['steps'] as List<dynamic>;

    for (final step in steps) {
      if (step is Map<String, dynamic> &&
          (step['type'] == 'moveTo' || step['type'] == 'lineTo')) {
        final x = step['x'] as double;
        final y = step['y'] as double;
        final pixelOffset = Offset(x.round().toDouble(), y.round().toDouble());

        if (!drawingPixels.contains(pixelOffset)) {
          drawingPixels.add(pixelOffset);
        }
      }
    }
  }

  void _extractRectanglePixels(Map<String, dynamic> data) {
    final rect = data['rect'] as Map<String, dynamic>;
    final left = rect['left'] as double;
    final top = rect['top'] as double;
    final right = rect['right'] as double;
    final bottom = rect['bottom'] as double;

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
    final center = data['center'] as Map<String, dynamic>;
    final radius = data['radius'] as double;

    final centerPoint = Offset(center['dx'] as double, center['dy'] as double);

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

  bool _isWithinTolerance(Offset a, Offset b, {double tolerance = 2.0}) {
    return (a - b).distance <= tolerance;
  }

  Offset? _capturePixel(Offset point) {
    final pixelX = point.dx.round();
    final pixelY = point.dy.round();
    final pixelOffset = Offset(pixelX.toDouble(), pixelY.toDouble());

    if (touchedPixels.isEmpty || touchedPixels.last != pixelOffset) {
      touchedPixels.add(pixelOffset);

      // Use tolerance when checking if this pixel exists in the drawing data
      final isDrawingPixel = drawingPixels.any(
        (drawPixel) => _isWithinTolerance(drawPixel, pixelOffset),
      );

      if (isDrawingPixel) {
        log(
          'Touched Pixel: x= [36m$pixelX [0m, y= [36m$pixelY [0m (DRAWING PIXEL)',
        );
      }
      // else {
      //   log('Touched Pixel: x=$pixelX, y=$pixelY (EMPTY SPACE)');
      // }

      widget.onPixelTouched?.call(pixelOffset);
      return pixelOffset;
    }
    return null;
  }

  void _handlePanStart(DragStartDetails details) {
    _capturePixel(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _capturePixel(details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    log('Touch ended - Total unique pixels:  [33m${touchedPixels.length} [0m');
  }

  void _handleTap(TapDownDetails details) {
    _capturePixel(details.localPosition);
    // log('Single tap at pixel: x=${details.localPosition.dx.round()}, y=${details.localPosition.dy.round()}');
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
