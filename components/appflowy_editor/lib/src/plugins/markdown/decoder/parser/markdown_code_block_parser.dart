import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownCodeBlockParserV2 extends CustomMarkdownParser {
  const MarkdownCodeBlockParserV2();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) {
      return [];
    }

    if (element.tag != 'pre') {
      return [];
    }

    final children = element.children;
    if (children == null || children.isEmpty) {
      return [];
    }

    final code = children.first;
    if (code is! md.Element || code.tag != 'code') {
      return [];
    }

    String? language;
    if (code.attributes.containsKey('class')) {
      final classes = code.attributes['class']!.split(' ');
      final languageClass = classes.firstWhere(
        (c) => c.startsWith('language-'),
        orElse: () => '',
      );
      if (languageClass.isNotEmpty) {
        language = languageClass.substring('language-'.length);
      }
    }

    return [
      codeBlockNode(
        language: language,
        delta: Delta()..insert(code.textContent.trimRight()),
      ),
    ];
  }
}

