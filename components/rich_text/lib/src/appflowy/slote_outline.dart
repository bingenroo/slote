import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';

/// Placeholder title when a heading block has no visible text.
const String kSloteOutlineUntitled = 'Untitled';

/// One outline row: a heading block in document order with display metadata.
class SloteOutlineEntry {
  const SloteOutlineEntry({
    required this.path,
    required this.level,
    required this.title,
  });

  /// Node path for scrolling and selection (AppFlowy [Path]).
  final Path path;

  /// Heading level (1–5), aligned with [HeadingBlockKeys.level] in Slote.
  final int level;

  /// Plain text from the heading’s delta, trimmed; [kSloteOutlineUntitled] if empty.
  final String title;

  @override
  bool operator ==(Object other) {
    return other is SloteOutlineEntry &&
        other.level == level &&
        other.title == title &&
        listEquals(path, other.path);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(path), level, title);
}

/// Collects heading blocks in **visual order** for outline / TOC UI.
///
/// Uses [NodeIterator] from the document root. Only blocks with
/// [HeadingBlockKeys.type] are included; level is clamped to 1–5.
List<SloteOutlineEntry> sloteCollectOutlineEntries(Document document) {
  final result = <SloteOutlineEntry>[];
  final iterator = NodeIterator(document: document, startNode: document.root);
  while (iterator.moveNext()) {
    final node = iterator.current;
    if (node.type != HeadingBlockKeys.type) continue;

    final raw = node.attributes[HeadingBlockKeys.level];
    final level = raw is int ? raw.clamp(1, 5) : 1;

    final plain = node.delta?.toPlainText() ?? '';
    final trimmed = plain.trim();
    final title = trimmed.isEmpty ? kSloteOutlineUntitled : trimmed;

    result.add(
      SloteOutlineEntry(path: node.path, level: level, title: title),
    );
  }
  return result;
}
