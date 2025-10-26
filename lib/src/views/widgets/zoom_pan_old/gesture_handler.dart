// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:developer';

class GestureHandler {
  final Map<int, Offset> _pointers = {};

  // Zoom state
  double? _initialScale;
  double? _initialDistance;
  Offset? _focalPoint;
  Matrix4? _initialTransform;

  // Pan state for 1-finger scrolling
  Offset? _initialPanPosition;
  Matrix4? _initialPanTransform;

  int get pointerCount => _pointers.length;

  void addPointer(int id, Offset position) {
    _pointers[id] = position;

    // Initialize zoom if we have 2 pointers
    if (_pointers.length == 2) {
      final positions = _pointers.values.toList();
      _initialDistance = _distance(positions[0], positions[1]);
      _focalPoint = _midPoint(positions[0], positions[1]);
    }

    // Initialize pan if we have 1 pointer
    if (_pointers.length == 1) {
      _initialPanPosition = position;
    }
  }

  void updatePointer(int id, Offset position) {
    if (!_pointers.containsKey(id)) return;
    _pointers[id] = position;
  }

  void removePointer(int id) {
    _pointers.remove(id);

    // Reset zoom state if we have less than 2 pointers
    if (_pointers.length < 2) {
      _initialScale = null;
      _initialDistance = null;
      _focalPoint = null;
      _initialTransform = null;
    }

    // Reset pan state if no pointers
    if (_pointers.isEmpty) {
      _initialPanPosition = null;
      _initialPanTransform = null;
    }
  }

  void initializeZoom(Matrix4 currentTransform) {
    if (_pointers.length == 2 && _initialScale == null) {
      _initialScale = currentTransform.getMaxScaleOnAxis();
      _initialTransform = Matrix4.copy(currentTransform);
    }
  }

  void initializePan(Matrix4 currentTransform) {
    if (_pointers.length == 1 && _initialPanTransform == null) {
      _initialPanTransform = Matrix4.copy(currentTransform);
    }
  }

  void resetPanState(Matrix4 currentTransform) {
    if (_pointers.length == 1) {
      log('=== RESET PAN STATE ===');
      log('Before reset - Initial pan position: $_initialPanPosition');
      log(
        'Before reset - Initial pan transform Y: ${_initialPanTransform?.getTranslation().y}',
      );
      log('Current pointer position: ${_pointers.values.first}');
      log('New transform Y: ${currentTransform.getTranslation().y}');

      // Reset the initial pan state to current position and transform
      _initialPanPosition = _pointers.values.first;
      _initialPanTransform = Matrix4.copy(currentTransform);

      log('After reset - Initial pan position: $_initialPanPosition');
      log(
        'After reset - Initial pan transform Y: ${_initialPanTransform?.getTranslation().y}',
      );
      log('=======================');
    }
  }

  // Nnew method for 1-finger panning
  Matrix4? calculatePanTransform() {
    if (_pointers.length != 1 ||
        _initialPanPosition == null ||
        _initialPanTransform == null) {
      return null;
    }

    final currentPosition = _pointers.values.first;
    final delta = currentPosition - _initialPanPosition!;

    // Add logging for pan calculation
    if ((delta.dy).abs() > 1.0) {
      // Only log significant movements
      log('=== PAN CALCULATION ===');
      log('Current position: $currentPosition');
      log('Initial position: $_initialPanPosition');
      log('Delta: $delta');
      log('Initial transform Y: ${_initialPanTransform!.getTranslation().y}');
    }

    // Create pan transformation
    final Matrix4 result = Matrix4.copy(_initialPanTransform!);
    result.translate(delta.dx, delta.dy);

    if ((delta.dy).abs() > 1.0) {
      log('Result transform Y: ${result.getTranslation().y}');
      log('=======================');
    }

    return result;
  }

  Matrix4? calculateZoomTransform() {
    if (_pointers.length != 2 ||
        _initialDistance == null ||
        _initialScale == null ||
        _focalPoint == null ||
        _initialTransform == null) {
      return null;
    }

    final positions = _pointers.values.toList();
    final currentDistance = _distance(positions[0], positions[1]);
    final currentFocal = _midPoint(positions[0], positions[1]);

    // Calculate scale change
    final scaleRatio = currentDistance / _initialDistance!;
    // final newScale = _initialScale! * scaleRatio;

    // Calculate focal point movement
    final focalDelta = currentFocal - _focalPoint!;

    // Apply zoom around focal point
    final Matrix4 result = Matrix4.copy(_initialTransform!);

    // Convert focal point to content coordinates using initial transform
    final Matrix4 inverse = Matrix4.inverted(_initialTransform!);
    final Vector3 focalInContent = inverse.transform3(
      Vector3(_focalPoint!.dx, _focalPoint!.dy, 0.0),
    );

    // Create zoom transformation
    final Matrix4 zoomTransform =
        Matrix4.identity()
          ..translate(focalInContent.x, focalInContent.y)
          ..scale(scaleRatio)
          ..translate(-focalInContent.x, -focalInContent.y);

    // Apply zoom
    result.multiply(zoomTransform);

    // Apply focal point movement
    result.translate(focalDelta.dx, focalDelta.dy);

    return result;
  }

  double _distance(Offset a, Offset b) => (a - b).distance;
  Offset _midPoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
}
