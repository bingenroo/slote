import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// Low-level pointer math for [ZoomPanSurface].
///
/// All [Offset] positions are in the **same local space** as the pointer events
/// delivered to the surrounding [Listener] (viewport / surface coordinates), not
/// in the transformed child’s content space. [ZoomPanSurface] combines these
/// with [Matrix4] inverses to scale around a focal point.
class GestureHandler {
  final Map<int, Offset> _pointers = {};

  // Zoom state
  double? _initialScale;
  double? _initialDistance;
  Offset? _focalPoint;
  Matrix4? _initialTransform;

  // Pan: incremental deltas from last local position (1-finger scroll)
  Offset? _lastPanLocal;

  int get pointerCount => _pointers.length;

  /// Live pinch midpoint in listener-local space (null unless exactly 2 pointers).
  Offset? get pinchMidpointLocal {
    if (_pointers.length != 2) return null;
    final values = _pointers.values.toList(growable: false);
    return _midPoint(values[0], values[1]);
  }

  /// Distance between the two pointers in listener-local space.
  double? get pinchSpanLocal {
    if (_pointers.length != 2) return null;
    final values = _pointers.values.toList(growable: false);
    return _distance(values[0], values[1]);
  }

  void addPointer(int id, Offset position) {
    _pointers[id] = position;

    if (_pointers.length == 2) {
      _lastPanLocal = null;
      final positions = _pointers.values.toList();
      _initialDistance = _distance(positions[0], positions[1]);
      _focalPoint = _midPoint(positions[0], positions[1]);
    }

    if (_pointers.length == 1) {
      _lastPanLocal = position;
    }
  }

  void updatePointer(int id, Offset position) {
    if (!_pointers.containsKey(id)) return;
    _pointers[id] = position;
  }

  void removePointer(int id) {
    _pointers.remove(id);

    if (_pointers.length < 2) {
      _initialScale = null;
      _initialDistance = null;
      _focalPoint = null;
      _initialTransform = null;
    }

    if (_pointers.length == 1) {
      _lastPanLocal = _pointers.values.single;
    }

    if (_pointers.isEmpty) {
      _lastPanLocal = null;
    }
  }

  void initializeZoom(Matrix4 currentTransform) {
    if (_pointers.length == 2 && _initialScale == null) {
      _initialScale = currentTransform.getMaxScaleOnAxis();
      _initialTransform = Matrix4.copy(currentTransform);
    }
  }

  /// Delta in listener-local space since the last [consumePanDelta] / pointer add.
  Offset consumePanDelta(Offset currentLocal) {
    if (_pointers.length != 1 || _lastPanLocal == null) {
      return Offset.zero;
    }
    final d = currentLocal - _lastPanLocal!;
    _lastPanLocal = currentLocal;
    return d;
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

    final scaleRatio = currentDistance / _initialDistance!;

    final focalDelta = currentFocal - _focalPoint!;

    final Matrix4 result = Matrix4.copy(_initialTransform!);

    final Matrix4 inverse = Matrix4.inverted(_initialTransform!);
    final Vector3 focalInContent = inverse.transform3(
      Vector3(_focalPoint!.dx, _focalPoint!.dy, 0.0),
    );

    final Matrix4 zoomTransform =
        Matrix4.identity()
          ..translate(focalInContent.x, focalInContent.y)
          ..scale(scaleRatio)
          ..translate(-focalInContent.x, -focalInContent.y);

    result.multiply(zoomTransform);

    // Extract and rebuild as translate-then-scale so the focal delta is applied
    // in viewport space (not content space, which post-multiply would do).
    final t = result.getTranslation();
    final newScale = result.getMaxScaleOnAxis();
    return Matrix4.identity()
      ..translate(t.x + focalDelta.dx, t.y + focalDelta.dy)
      ..scale(newScale);
  }

  double _distance(Offset a, Offset b) => (a - b).distance;
  Offset _midPoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
}
