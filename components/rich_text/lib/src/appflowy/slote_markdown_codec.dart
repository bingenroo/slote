library;

import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

import 'slote_callout_markdown.dart';
import 'slote_inline_attributes.dart';

/// Slote markdown import (string -> AppFlowy [Document]).
///
/// Notes:
/// - This relies on AppFlowy’s markdown decoder, which can parse HTML tags.
/// - We encode custom inline attributes using HTML tags + JSON-ish attribute values
///   so AppFlowy’s `DeltaMarkdownDecoder` can `jsonDecode` them.
Document sloteMarkdownToDocument(String markdown) {
  final normalized = markdown.replaceAllMapped(
    RegExp(
      r'<callout\b[^>]*kind="([^"]+)"[^>]*>([\s\S]*?)</callout>',
      caseSensitive: false,
    ),
    (m) {
      final kind = m.group(1) ?? 'info';
      final inner = (m.group(2) ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
      final text = inner.trimRight();
      return '[[slote_callout kind="$kind"]]$text';
    },
  );

  final doc = markdownToDocument(normalized);
  return _slotePostProcessCallouts(doc);
}

/// Slote markdown export (AppFlowy [Document] -> string).
///
/// Custom inline attributes are encoded as:
/// - superscript: `<sup slote_superscript="true">...</sup>`
/// - subscript: `<sub slote_subscript="true">...</sub>`
/// - font size/family: `<span font_size="14.0" font_family='"serif"'>...</span>`
String sloteDocumentToMarkdown(Document document) {
  return documentToMarkdown(
    document,
    customParsers: const [
      SloteCalloutNodeParser(),
      _SloteTextNodeParser(),
    ],
  );
}

Document _slotePostProcessCallouts(Document doc) {
  final out = Document.blank();
  final nodes = <Node>[];

  for (final node in doc.root.children) {
    if (node.type != ParagraphBlockKeys.type) {
      nodes.add(node);
      continue;
    }

    final text = node.delta?.toPlainText() ?? '';
    final match = RegExp(r'^\[\[slote_callout kind="([^"]+)"\]\](.*)$')
        .firstMatch(text);
    if (match == null) {
      nodes.add(node);
      continue;
    }

    final kind = match.group(1) ?? 'info';
    final body = (match.group(2) ?? '').trimRight();
    nodes.add(
      calloutNode(
        kind: kind,
        delta: Delta()..insert(body),
      ),
    );
  }

  if (nodes.isNotEmpty) {
    out.insert([0], nodes);
  }
  return out;
}

class _SloteTextNodeParser extends NodeParser {
  const _SloteTextNodeParser();

  @override
  String get id => ParagraphBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta ?? (Delta()..insert(''));
    final children = encoder?.convertNodes(node.children, withIndent: true);
    var markdown = _SloteDeltaMarkdownEncoder().convert(delta);
    if (markdown.isEmpty && children == null) {
      return '';
    } else if (node.findParent((e) => e.type == TableBlockKeys.type) == null) {
      markdown += '\n';
    }
    if (children != null && children.isNotEmpty) {
      markdown += children;
    }
    return markdown;
  }
}

class _SloteDeltaMarkdownEncoder extends Converter<Delta, String> {
  @override
  String convert(Delta input) {
    final buffer = StringBuffer();
    final iterator = input.iterator;
    while (iterator.moveNext()) {
      final op = iterator.current;
      if (op is! TextInsert) continue;

      final attributes = op.attributes;
      if (attributes == null) {
        buffer.write(op.text);
        continue;
      }

      final wrapped = _wrapCustomInlineAttributes(
        attributes,
        _encodeBuiltInInlineStyles(op),
      );
      buffer.write(wrapped);
    }
    return buffer.toString();
  }

  String _encodeBuiltInInlineStyles(TextInsert op) {
    final attributes = op.attributes;
    if (attributes == null) return op.text;

    final formula = attributes[BuiltInAttributeKey.formula] ?? '';
    final prefix = _prefixSyntax(attributes);
    final suffix = _suffixSyntax(attributes);
    final body = (formula is String && formula.isNotEmpty) ? formula : op.text;
    return '$prefix$body$suffix';
  }

  String _wrapCustomInlineAttributes(Attributes attributes, String inner) {
    final sb = StringBuffer();

    final isSup = attributes[kSloteSuperscriptAttribute] == true;
    final isSub = attributes[kSloteSubscriptAttribute] == true;

    final fontSize = attributes[AppFlowyRichTextKeys.fontSize];
    final fontFamily = attributes[AppFlowyRichTextKeys.fontFamily];

    final hasFont = fontSize != null || fontFamily != null;
    if (hasFont) {
      final attrs = <String>[];
      if (fontSize is num) {
        // Decoder expects JSON-ish numbers.
        attrs.add('${AppFlowyRichTextKeys.fontSize}="${fontSize.toDouble()}"');
      }
      if (fontFamily is String && fontFamily.isNotEmpty) {
        // Wrap JSON string using single quotes outside so the attribute value
        // includes double quotes and can be jsonDecoded as a string.
        attrs.add(
          "${AppFlowyRichTextKeys.fontFamily}='\"$fontFamily\"'",
        );
      }
      sb.write('<span ${attrs.join(' ')}>');
    }

    if (isSup) {
      sb.write('<sup $kSloteSuperscriptAttribute="true">');
    } else if (isSub) {
      sb.write('<sub $kSloteSubscriptAttribute="true">');
    }

    sb.write(inner);

    if (isSup) {
      sb.write('</sup>');
    } else if (isSub) {
      sb.write('</sub>');
    }

    if (hasFont) {
      sb.write('</span>');
    }

    return sb.toString();
  }

  String _prefixSyntax(Attributes attributes) {
    var syntax = '';

    if (attributes[BuiltInAttributeKey.bold] == true &&
        attributes[BuiltInAttributeKey.italic] == true) {
      syntax += '***';
    } else if (attributes[BuiltInAttributeKey.bold] == true) {
      syntax += '**';
    } else if (attributes[BuiltInAttributeKey.italic] == true) {
      syntax += '_';
    }

    if (attributes[BuiltInAttributeKey.strikethrough] == true) {
      syntax += '~~';
    }
    if (attributes[BuiltInAttributeKey.underline] == true) {
      syntax += '<u>';
    }
    if (attributes[BuiltInAttributeKey.code] == true) {
      syntax += '`';
    }

    if (attributes[BuiltInAttributeKey.href] != null) {
      syntax += '[';
    }

    if (attributes[BuiltInAttributeKey.formula] != null) {
      syntax += r'$';
    }

    return syntax;
  }

  String _suffixSyntax(Attributes attributes) {
    var syntax = '';

    if (attributes[BuiltInAttributeKey.href] != null) {
      syntax += '](${attributes[BuiltInAttributeKey.href]})';
    }

    if (attributes[BuiltInAttributeKey.code] == true) {
      syntax += '`';
    }

    if (attributes[BuiltInAttributeKey.underline] == true) {
      syntax += '</u>';
    }

    if (attributes[BuiltInAttributeKey.strikethrough] == true) {
      syntax += '~~';
    }

    if (attributes[BuiltInAttributeKey.bold] == true &&
        attributes[BuiltInAttributeKey.italic] == true) {
      syntax += '***';
    } else if (attributes[BuiltInAttributeKey.bold] == true) {
      syntax += '**';
    } else if (attributes[BuiltInAttributeKey.italic] == true) {
      syntax += '_';
    }

    if (attributes[BuiltInAttributeKey.formula] != null) {
      syntax += r'$';
    }

    return syntax;
  }
}

