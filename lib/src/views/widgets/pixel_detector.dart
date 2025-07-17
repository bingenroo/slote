import 'dart:developer';
import 'package:flutter/material.dart';

class PixelDetector extends StatefulWidget {
  final double eraserRadius;
  final double tolerance;
  final BoxConstraints? constraints;
  const PixelDetector({
    Key? key,
    this.eraserRadius = 16.0,
    this.tolerance = 20.0, // slightly larger than eraser
    this.constraints,
  }) : super(key: key);

  @override
  State<PixelDetector> createState() => _PixelDetectorState();
}

class _PixelDetectorState extends State<PixelDetector> {
  bool _isPointerDown = false;
  Offset? _pointerPosition;
  final List<Set<Offset>> _loggedAreas = [];
  Set<Offset> _currentDragLogged = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          _isPointerDown = true;
          _pointerPosition = event.localPosition;
          _currentDragLogged = {};
        });
        _logArea(event.localPosition);
      },
      onPointerMove: (event) {
        setState(() {
          _pointerPosition = event.localPosition;
        });
        _logArea(event.localPosition);
      },
      onPointerUp: (event) {
        setState(() {
          _isPointerDown = false;
        });
        if (_currentDragLogged.isNotEmpty) {
          _loggedAreas.add(_currentDragLogged);
          log('Logged drag: ${_currentDragLogged.length} points');
        }
      },
      onPointerCancel: (event) {
        setState(() {
          _isPointerDown = false;
        });
        if (_currentDragLogged.isNotEmpty) {
          _loggedAreas.add(_currentDragLogged);
          log('Logged drag (cancel): ${_currentDragLogged.length} points');
        }
      },
      child: CustomPaint(
        painter:
            _isPointerDown && _pointerPosition != null
                ? _EraserCursorPainter(
                  position: _pointerPosition!,
                  radius: widget.eraserRadius,
                )
                : null,
        child: Container(
          width: widget.constraints?.maxWidth,
          height: widget.constraints?.maxHeight,
          color: Colors.transparent,
        ),
      ),
    );
  }

  void _logArea(Offset center) {
    // Calculate all points within the eraser + tolerance circle
    final double r = widget.eraserRadius + widget.tolerance;
    final int step = 4; // pixel step for performance
    int newPointsCount = 0;
    final List<String> newPoints = [];

    for (double dx = -r; dx <= r; dx += step) {
      for (double dy = -r; dy <= r; dy += step) {
        if (dx * dx + dy * dy <= r * r) {
          final point = Offset(center.dx + dx, center.dy + dy);
          // Only log if not already logged in this drag
          if (!_currentDragLogged.contains(point)) {
            _currentDragLogged.add(point);
            newPointsCount++;
            newPoints.add(
              '(${point.dx.toStringAsFixed(1)}, ${point.dy.toStringAsFixed(1)})',
            );
            // Log only once per drag for each point
          }
        }
      }
    }

    if (newPointsCount > 0) {
      log(
        'Eraser at: (${center.dx.toStringAsFixed(1)}, ${center.dy.toStringAsFixed(1)}) - logged $newPointsCount new area points:',
      );
      log('Points: ${newPoints.join(', ')}');
    }
  }
}

class _EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double radius;
  _EraserCursorPainter({required this.position, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.orange.withAlpha(128)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.radius != radius;
  }
}
