import 'dart:developer';
import 'package:flutter/material.dart';

class PixelDetector extends StatefulWidget {
  final double eraserRadius;
  final double tolerance;
  final BoxConstraints? constraints;
  final Function(List<String>)? onDragComplete;
  final Function(List<String>)? onDrag;
  const PixelDetector({
    Key? key,
    this.eraserRadius = 16.0,
    this.tolerance = 20.0, // slightly larger than eraser
    this.constraints,
    this.onDragComplete,
    this.onDrag,
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
        if (widget.onDrag != null) {
          final points = getLoggedPoints();
          widget.onDrag!(points);
        }
      },
      onPointerUp: (event) {
        setState(() {
          _isPointerDown = false;
        });
        if (_currentDragLogged.isNotEmpty) {
          _loggedAreas.add(_currentDragLogged);
          // log('Logged drag: ${_currentDragLogged.length} points');

          // Get logged points and pass to callback
          final points = getLoggedPoints();
          widget.onDragComplete?.call(points);
          clearLoggedPoints();
        }
      },
      onPointerCancel: (event) {
        setState(() {
          _isPointerDown = false;
        });
        if (_currentDragLogged.isNotEmpty) {
          _loggedAreas.add(_currentDragLogged);
          // log('Logged drag (cancel): ${_currentDragLogged.length} points');

          // Get logged points and pass to callback
          final points = getLoggedPoints();
          widget.onDragComplete?.call(points);
          clearLoggedPoints();
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
    // final double r = widget.eraserRadius + widget.tolerance; // not eraserRadius + tolerance
    final double r = widget.eraserRadius; // not eraserRadius + tolerance
    final int step = 2; // or 1 for best match
    int newPointsCount = 0;

    for (double dx = -r; dx <= r; dx += step) {
      for (double dy = -r; dy <= r; dy += step) {
        if (dx * dx + dy * dy <= r * r) {
          final point = Offset(center.dx + dx, center.dy + dy);
          // Only log if not already logged in this drag
          if (!_currentDragLogged.contains(point)) {
            _currentDragLogged.add(point);
            newPointsCount++;
            // Log only once per drag for each point
          }
        }
      }
    }

    if (newPointsCount > 0) {
      // log(
      //   'Eraser at: (${center.dx.toStringAsFixed(1)}, ${center.dy.toStringAsFixed(1)}) - logged $newPointsCount new area points',
      // );
    }
  }

  /// Get all logged points as strings
  List<String> getLoggedPoints() {
    return _currentDragLogged
        .map(
          (point) =>
              '(${point.dx.toStringAsFixed(1)}, ${point.dy.toStringAsFixed(1)})',
        )
        .toList();
  }

  /// Clear logged points
  void clearLoggedPoints() {
    _currentDragLogged.clear();
    _loggedAreas.clear();
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
          ..color = Colors.black.withAlpha(128)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.radius != radius;
  }
}
