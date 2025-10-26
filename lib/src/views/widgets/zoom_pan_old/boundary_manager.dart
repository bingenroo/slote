import 'dart:math' as math;
import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math_64.dart';
import 'dart:developer';

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

    // ADD COMPREHENSIVE DEBUGGING
    log('=== BOUNDARY MANAGER DEBUG ===');
    log('Content size: $contentSize');
    log('Viewport size: $viewportSize');
    log('Scale: $scale -> Constrained scale: $constrainedScale');
    log('Original translation: ${translation.x}, ${translation.y}');
    log('Scaled height: $scaledHeight');
    log(
      'scaledHeight <= viewportSize.height: ${scaledHeight <= viewportSize.height}',
    );

    // Horizontal constraints
    if (scaledWidth <= viewportSize.width) {
      // Content smaller than viewport - center it
      constrainedX = (viewportSize.width - scaledWidth) / 2;
      log('Horizontal: Centering (content smaller than viewport)');
    } else {
      // Content larger than viewport - prevent over-pan
      final oldX = constrainedX;
      constrainedX = constrainedX.clamp(viewportSize.width - scaledWidth, 0.0);
      log(
        'Horizontal: Clamping $oldX to range [${viewportSize.width - scaledWidth}, 0.0] = $constrainedX',
      );
    }

    // Vertical constraints
    if (scaledHeight <= viewportSize.height) {
      // Content smaller than viewport - allow some flexibility
      constrainedY = constrainedY.clamp(-50.0, 50.0); // Allow small over-scroll
    } else {
      // Content larger than viewport - prevent over-pan
      final minY = viewportSize.height - scaledHeight;
      final maxY = 0.0;
      constrainedY = constrainedY.clamp(minY, maxY);
    }

    log('Final constrained translation: $constrainedX, $constrainedY');
    log('===============================');

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
}
