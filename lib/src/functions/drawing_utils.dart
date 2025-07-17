import 'package:flutter_drawing_board/paint_contents.dart';
import 'dart:developer';

/// Converts a list of JSON maps to a list of PaintContent objects.
List<PaintContent> paintContentsFromJson(List<dynamic> jsonData) {
  final List<PaintContent> contents = [];

  for (final dynamic item in jsonData) {
    if (item is Map<String, dynamic>) {
      final String type = item['type'] as String? ?? '';
      try {
        switch (type) {
          case 'StraightLine':
            contents.add(StraightLine.fromJson(item));
            break;
          case 'SimpleLine':
            contents.add(SimpleLine.fromJson(item));
            break;
          case 'Rectangle':
            contents.add(Rectangle.fromJson(item));
            break;
          case 'Circle':
            contents.add(Circle.fromJson(item));
            break;
          case 'Eraser':
            contents.add(Eraser.fromJson(item));
            break;
          default:
            log('Unknown drawing type: $type');
            break;
        }
      } catch (e) {
        // log('Error parsing drawing content: $e');
        continue;
      }
    }
  }
  return contents;
}
