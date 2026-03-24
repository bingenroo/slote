import 'dart:convert';

/// Canonical blank AppFlowy document used for note body storage.
const Map<String, Object> kSloteEmptyDocumentJson = {
  'document': {
    'type': 'page',
    'children': [
      {
        'type': 'paragraph',
        'data': {
          'delta': [
            {'insert': ' '},
          ],
        },
      },
    ],
  },
};

String sloteEmptyDocumentJsonString() => jsonEncode(kSloteEmptyDocumentJson);

/// Returns true when [body] parses to an AppFlowy `Document.toJson`-shaped map.
bool looksLikeAppFlowyDocumentJson(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return false;
    return decoded['document'] is Map<String, dynamic>;
  } catch (_) {
    return false;
  }
}

/// Parses [body] into an AppFlowy document json map, or returns an empty
/// document when parsing fails or shape is invalid.
Map<String, dynamic> parseAppFlowyDocumentJsonOrEmpty(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> &&
        decoded['document'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    // Fall through to empty document.
  }
  return Map<String, dynamic>.from(kSloteEmptyDocumentJson);
}

/// Produces a normalized AppFlowy json string for storage.
String normalizeNoteBodyToDocumentJsonString(String body) {
  return jsonEncode(parseAppFlowyDocumentJsonOrEmpty(body));
}

/// Best-effort plain-text preview extractor for note cards.
String plainTextPreviewFromDocumentJsonString(String body) {
  final doc = parseAppFlowyDocumentJsonOrEmpty(body);
  final document = doc['document'];
  if (document is! Map<String, dynamic>) return '';
  final children = document['children'];
  if (children is! List) return '';

  final lines = <String>[];
  for (final child in children) {
    if (child is! Map) continue;
    final data = child['data'];
    if (data is! Map) continue;
    final delta = data['delta'];
    if (delta is! List) continue;

    final buffer = StringBuffer();
    for (final op in delta) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is String) {
        buffer.write(insert);
      }
    }

    final line = buffer.toString().replaceAll('\n', ' ').trim();
    if (line.isNotEmpty) {
      lines.add(line);
    }
  }

  return lines.join(' ').trim();
}
