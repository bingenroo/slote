import 'dart:math';
import 'package:flutter/material.dart';

class SpatialIndex {
  final double cellSize;
  final Map<Point<int>, List<int>> grid = {};

  SpatialIndex(this.cellSize);

  void addStroke(int strokeId, Rect bounds) {
    final startCell = _pointToCell(bounds.topLeft);
    final endCell = _pointToCell(bounds.bottomRight);

    for (int x = startCell.x; x <= endCell.x; x++) {
      for (int y = startCell.y; y <= endCell.y; y++) {
        grid.putIfAbsent(Point(x, y), () => []).add(strokeId);
      }
    }
  }

  Point<int> _pointToCell(Offset point) {
    return Point((point.dx / cellSize).floor(), (point.dy / cellSize).floor());
  }

  List<int> getCandidates(Offset point, double radius) {
    final candidates = <int>{};
    final topLeft = _pointToCell(Offset(point.dx - radius, point.dy - radius));
    final bottomRight = _pointToCell(
      Offset(point.dx + radius, point.dy + radius),
    );

    for (int x = topLeft.x; x <= bottomRight.x; x++) {
      for (int y = topLeft.y; y <= bottomRight.y; y++) {
        grid[Point(x, y)]?.forEach(candidates.add);
      }
    }
    return candidates.toList();
  }

  void clear() {
    grid.clear();
  }
}
