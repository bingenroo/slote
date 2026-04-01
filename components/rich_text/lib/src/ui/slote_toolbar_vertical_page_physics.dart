import 'package:flutter/widgets.dart';

/// Scales pointer drag so more finger movement is needed for the same scroll
/// delta (less sensitive than 1:1).
class SloteScaledDragScrollPhysics extends ScrollPhysics {
  const SloteScaledDragScrollPhysics({
    super.parent,
    this.dragScale = 0.52,
  }) : assert(dragScale > 0 && dragScale <= 1);

  final double dragScale;

  @override
  SloteScaledDragScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SloteScaledDragScrollPhysics(
      parent: buildParent(ancestor),
      dragScale: dragScale,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * dragScale);
  }
}

/// [PageScrollPhysics] with damped flings so quick swipes advance fewer pages.
class SloteToolbarVerticalPagePhysics extends PageScrollPhysics {
  const SloteToolbarVerticalPagePhysics({
    super.parent,
    this.flingVelocityScale = 0.62,
  }) : assert(flingVelocityScale > 0 && flingVelocityScale <= 1);

  final double flingVelocityScale;

  @override
  SloteToolbarVerticalPagePhysics applyTo(ScrollPhysics? ancestor) {
    return SloteToolbarVerticalPagePhysics(
      parent: buildParent(ancestor),
      flingVelocityScale: flingVelocityScale,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return super.createBallisticSimulation(
      position,
      velocity * flingVelocityScale,
    );
  }
}
