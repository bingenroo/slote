// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'boundary_manager.dart';
import 'dart:developer';

class TransformAwareScrollbar extends StatelessWidget {
  final Matrix4 transform;
  final BoundaryManager boundaryManager;
  final bool isVisible;

  const TransformAwareScrollbar({
    super.key,
    required this.transform,
    required this.boundaryManager,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final scrollPosition = boundaryManager.getScrollPosition(transform);
    final scrollExtent = boundaryManager.getScrollExtent(transform);

    // Always show for debugging - comment out later
    // if (scrollExtent >= 1.0) return const SizedBox.shrink();

    return Positioned(
      right: 4,
      top: 0,
      bottom: 0,
      child: Container(
        width: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          // Add background for debugging
          color: Colors.red.withAlpha(26), // Temporary - remove later
        ),
        child: FractionallySizedBox(
          alignment: Alignment.topCenter,
          heightFactor: scrollExtent,
          child: Transform.translate(
            offset: Offset(
              0,
              scrollPosition *
                  (boundaryManager.viewportSize.height * (1 - scrollExtent)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(204),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
