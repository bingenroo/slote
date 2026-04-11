import 'package:flutter/material.dart';

import 'edge_overscroll.dart';

/// Authoritative translate-then-scale viewport state (matches
/// `Matrix4.identity()..translate(tx,ty)..scale(s)`).
///
/// Maps a content point **p** to viewport: `s * p + (tx, ty)`.
class ViewportScrollState {
  const ViewportScrollState({
    required this.scale,
    required this.translateX,
    required this.translateY,
  });

  final double scale;
  final double translateX;
  final double translateY;

  Matrix4 toMatrix() =>
      Matrix4.identity()..translate(translateX, translateY)..scale(scale);

  static ViewportScrollState fromMatrix(Matrix4 m) {
    return ViewportScrollState(
      scale: m.getMaxScaleOnAxis(),
      translateX: m.getTranslation().x,
      translateY: m.getTranslation().y,
    );
  }
}

/// Default maximum rubber-band pull past a hard scroll edge (per axis).
const double kDefaultMaxEdgeRubber = 56.0;

/// Content size, viewport size, and scale limits for scroll / clamp math.
class ViewportScrollGeometry {
  ViewportScrollGeometry({
    required this.contentSize,
    required this.viewportSize,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.maxEdgeRubber = kDefaultMaxEdgeRubber,
  });

  final Size contentSize;
  final Size viewportSize;
  final double minScale;
  final double maxScale;
  final double maxEdgeRubber;

  double scaledWidth(double s) => contentSize.width * s;
  double scaledHeight(double s) => contentSize.height * s;

  /// Hard translation bounds for X. When content fits, both are `0` (pinned top-left).
  (double minTx, double maxTx) hardBoundsX(double s) {
    final sw = scaledWidth(s);
    if (sw <= viewportSize.width) {
      return (0.0, 0.0);
    }
    return (viewportSize.width - sw, 0.0);
  }

  /// Hard translation bounds for Y.
  (double minTy, double maxTy) hardBoundsY(double s) {
    final sh = scaledHeight(s);
    if (sh <= viewportSize.height) {
      return (0.0, 0.0);
    }
    return (viewportSize.height - sh, 0.0);
  }

  ViewportScrollState constrainState(
    ViewportScrollState input, {
    bool rubberBand = false,
  }) {
    final s = input.scale.clamp(minScale, maxScale);
    final (minX, maxX) = hardBoundsX(s);
    final (minY, maxY) = hardBoundsY(s);
    double tx = input.translateX;
    double ty = input.translateY;
    if (rubberBand) {
      tx = applyAxisRubber(tx, minX, maxX, maxRubber: maxEdgeRubber);
      ty = applyAxisRubber(ty, minY, maxY, maxRubber: maxEdgeRubber);
    } else {
      tx = tx.clamp(minX, maxX);
      ty = ty.clamp(minY, maxY);
    }
    return ViewportScrollState(scale: s, translateX: tx, translateY: ty);
  }

  Matrix4 constrainMatrix(
    Matrix4 transform, {
    bool rubberBand = false,
  }) {
    return constrainState(
      ViewportScrollState.fromMatrix(transform),
      rubberBand: rubberBand,
    ).toMatrix();
  }

  /// Snap rubber-band back to hard edges (e.g. all pointers up).
  Matrix4 settleMatrix(Matrix4 transform) =>
      constrainMatrix(transform, rubberBand: false);

  double getScrollPosition(Matrix4 transform) {
    final t = ViewportScrollState.fromMatrix(transform);
    final sh = scaledHeight(t.scale);
    if (sh <= viewportSize.height) return 0.0;
    final scrollable = sh - viewportSize.height;
    if (scrollable.abs() < 1e-9) return 0.0;
    return (-t.translateY / scrollable).clamp(0.0, 1.0);
  }

  double getScrollExtent(Matrix4 transform) {
    final s = transform.getMaxScaleOnAxis();
    final sh = contentSize.height * s;
    if (sh <= 0) return 1.0;
    return (viewportSize.height / sh).clamp(0.0, 1.0);
  }

  double getScrollPositionX(Matrix4 transform) {
    final t = ViewportScrollState.fromMatrix(transform);
    final sw = scaledWidth(t.scale);
    if (sw <= viewportSize.width) return 0.0;
    final scrollable = sw - viewportSize.width;
    if (scrollable.abs() < 1e-9) return 0.0;
    return (-t.translateX / scrollable).clamp(0.0, 1.0);
  }

  double getScrollExtentX(Matrix4 transform) {
    final s = transform.getMaxScaleOnAxis();
    final sw = contentSize.width * s;
    if (sw <= 0) return 1.0;
    return (viewportSize.width / sw).clamp(0.0, 1.0);
  }

  Matrix4 transformForScrollPosition(
    double scale,
    double scrollX,
    double scrollY,
  ) {
    final constrainedScale = scale.clamp(minScale, maxScale);
    final (minX, maxX) = hardBoundsX(constrainedScale);
    final (minY, maxY) = hardBoundsY(constrainedScale);
    final sx = scrollX.clamp(0.0, 1.0);
    final sy = scrollY.clamp(0.0, 1.0);
    final tx = minX == maxX ? 0.0 : maxX + sx * (minX - maxX);
    final ty = minY == maxY ? 0.0 : maxY + sy * (minY - maxY);
    return ViewportScrollState(
      scale: constrainedScale,
      translateX: tx,
      translateY: ty,
    ).toMatrix();
  }
}
