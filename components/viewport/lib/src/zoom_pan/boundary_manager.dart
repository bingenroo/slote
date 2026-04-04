import 'dart:math' as math;
import 'package:flutter/material.dart';

/// When scaled content is **shorter** than the viewport, Y translation is
/// clamped to this band so the user can nudge content slightly instead of
/// locking to a single row (horizontal small content is **centered** instead).
const double kVerticalOverscrollSlack = 50.0;

class BoundaryManager {
  final Size contentSize;
  final Size viewportSize;
  final double minScale;
  final double maxScale;

  BoundaryManager({
    required this.contentSize,
    required this.viewportSize,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  });

  /// Returns a new matrix with **uniform scale** and **translation** only.
  ///
  /// Any rotation or skew in [transform] is discarded; scale is taken from
  /// [Matrix4.getMaxScaleOnAxis]. This matches [ZoomPanSurface]’s translate+scale
  /// navigation model.
  Matrix4 constrain(Matrix4 transform) {
    // Extract current values
    final scale = transform.getMaxScaleOnAxis();
    final translation = transform.getTranslation();

    // Constrain scale
    final constrainedScale = scale.clamp(minScale, maxScale);

    // Calculate scaled content size
    final scaledWidth = contentSize.width * constrainedScale;
    final scaledHeight = contentSize.height * constrainedScale;

    // Constrain translation
    double constrainedX = translation.x;
    double constrainedY = translation.y;

    // Horizontal constraints
    if (scaledWidth <= viewportSize.width) {
      // Content smaller than viewport - center it
      constrainedX = (viewportSize.width - scaledWidth) / 2;
    } else {
      constrainedX = constrainedX.clamp(viewportSize.width - scaledWidth, 0.0);
    }

    // Vertical constraints
    if (scaledHeight <= viewportSize.height) {
      constrainedY = constrainedY.clamp(
        -kVerticalOverscrollSlack,
        kVerticalOverscrollSlack,
      );
    } else {
      // Content larger than viewport - prevent over-pan
      final minY = viewportSize.height - scaledHeight;
      final maxY = 0.0;
      constrainedY = constrainedY.clamp(minY, maxY);
    }

    // Create constrained transform
    final result =
        Matrix4.identity()
          ..translate(constrainedX, constrainedY)
          ..scale(constrainedScale);

    return result;
  }

  // Helper method to get scroll position (0.0 to 1.0)
  double getScrollPosition(Matrix4 transform) {
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();
    final scaledHeight = contentSize.height * scale;

    if (scaledHeight <= viewportSize.height) return 0.0;

    // Convert transform Y to scroll position (0 to 1)
    return (-translation.y) / (scaledHeight - viewportSize.height);
  }

  // Helper method to get scroll extent (visible portion ratio)
  double getScrollExtent(Matrix4 transform) {
    final scale = transform.getMaxScaleOnAxis();
    return math.min(1.0, viewportSize.height / (contentSize.height * scale));
  }

  /// Horizontal scroll position (0.0 to 1.0).
  double getScrollPositionX(Matrix4 transform) {
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();
    final scaledWidth = contentSize.width * scale;

    if (scaledWidth <= viewportSize.width) return 0.0;

    return (-translation.x) / (scaledWidth - viewportSize.width);
  }

  /// Horizontal scroll extent (visible portion ratio).
  double getScrollExtentX(Matrix4 transform) {
    final scale = transform.getMaxScaleOnAxis();
    return math.min(1.0, viewportSize.width / (contentSize.width * scale));
  }

  /// Build a transform with the given scale and scroll positions (0.0 to 1.0).
  /// Used by scrollbar drag to set pan from thumb position.
  Matrix4 transformForScrollPosition(double scale, double scrollX, double scrollY) {
    final constrainedScale = scale.clamp(minScale, maxScale);
    final scaledWidth = contentSize.width * constrainedScale;
    final scaledHeight = contentSize.height * constrainedScale;

    double tx;
    double ty;

    if (scaledWidth <= viewportSize.width) {
      tx = (viewportSize.width - scaledWidth) / 2;
    } else {
      final scrollableWidth = scaledWidth - viewportSize.width;
      tx = -scrollX.clamp(0.0, 1.0) * scrollableWidth;
    }

    if (scaledHeight <= viewportSize.height) {
      ty = ((viewportSize.height - scaledHeight) / 2).clamp(
        -kVerticalOverscrollSlack,
        kVerticalOverscrollSlack,
      );
    } else {
      final scrollableHeight = scaledHeight - viewportSize.height;
      ty = -scrollY.clamp(0.0, 1.0) * scrollableHeight;
    }

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(constrainedScale);
  }
}

