import 'package:flutter/material.dart';

import 'viewport_scroll_state.dart';

/// Clamps zoom/pan transforms to content and viewport, with optional edge rubber-band.
///
/// Delegates math to [ViewportScrollGeometry]. Replaces the previous “undersized page”
/// vertical slack band with **pinned top-left** (tx/ty = 0) when content fits.
class BoundaryManager {
  BoundaryManager({
    required Size contentSize,
    required Size viewportSize,
    double minScale = 0.5,
    double maxScale = 3.0,
    double maxEdgeRubber = kDefaultMaxEdgeRubber,
  }) : _geometry = ViewportScrollGeometry(
         contentSize: contentSize,
         viewportSize: viewportSize,
         minScale: minScale,
         maxScale: maxScale,
         maxEdgeRubber: maxEdgeRubber,
       );

  final ViewportScrollGeometry _geometry;

  Size get contentSize => _geometry.contentSize;
  Size get viewportSize => _geometry.viewportSize;

  ViewportScrollGeometry get geometry => _geometry;

  /// Hard clamp only (e.g. wheel, scrollbar, settle after gesture).
  Matrix4 settle(Matrix4 transform) => _geometry.settleMatrix(transform);

  /// [rubberBand] uses edge resistance past hard scroll limits (touch pan / pinch).
  Matrix4 constrain(Matrix4 transform, {bool rubberBand = false}) {
    return _geometry.constrainMatrix(transform, rubberBand: rubberBand);
  }

  double getScrollPosition(Matrix4 transform) =>
      _geometry.getScrollPosition(transform);

  double getScrollExtent(Matrix4 transform) =>
      _geometry.getScrollExtent(transform);

  double getScrollPositionX(Matrix4 transform) =>
      _geometry.getScrollPositionX(transform);

  double getScrollExtentX(Matrix4 transform) =>
      _geometry.getScrollExtentX(transform);

  Matrix4 transformForScrollPosition(
    double scale,
    double scrollX,
    double scrollY,
  ) {
    return _geometry.transformForScrollPosition(scale, scrollX, scrollY);
  }
}
