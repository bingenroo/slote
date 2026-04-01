import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

class SloteCalloutMarkdownParserV2 extends CustomMarkdownParser {
  const SloteCalloutMarkdownParserV2();

  static final RegExp _kCalloutRegex =
      RegExp(r'<callout\b([^>]*)>([\s\S]*?)</callout>', caseSensitive: false);
  static final RegExp _kKindAttrRegex =
      RegExp(r'\bkind\s*=\s*"([^"]*)"', caseSensitive: false);

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    // HTML blocks sometimes come through as non-Element nodes (e.g. HtmlBlock),
    // so we handle both parsed elements and raw HTML payloads.
    if (element is md.Element) {
      md.Element? calloutEl;
      if (element.tag == 'callout') {
        calloutEl = element;
      } else if (element.tag == 'p') {
        final children = element.children;
        if (children != null &&
            children.length == 1 &&
            children.first is md.Element &&
            (children.first as md.Element).tag == 'callout') {
          calloutEl = children.first as md.Element;
        }
      }
      if (calloutEl == null) return [];

      final kind = calloutEl.attributes['kind'] ?? 'info';
      final text = calloutEl.textContent;
      return [
        calloutNode(
          kind: kind,
          delta: Delta()..insert(text.trimRight()),
        ),
      ];
    }

    // Some markdown parses raw HTML blocks as text nodes.
    if (element is md.Text) {
      return _tryParseCalloutHtml(element.text);
    }

    // Fallback: if any non-Element node's textContent contains a callout tag,
    // try parsing it directly. This covers markdown node types that are neither
    // [md.Text] nor expose HtmlBlock lines.
    final content = element.textContent;
    if (content.contains('<callout')) {
      final parsed = _tryParseCalloutHtml(content);
      if (parsed.isNotEmpty) return parsed;
    }

    final typeName = element.runtimeType.toString();
    if (typeName != 'HtmlBlock') return [];
    final dyn = element as dynamic;
    final lines = dyn.lines;
    final html =
        (lines is List ? lines.join('\n') : dyn.text?.toString()) ??
        element.textContent;

    return _tryParseCalloutHtml(html);
  }

  List<Node> _tryParseCalloutHtml(String raw) {
    final m = _kCalloutRegex.firstMatch(raw);
    if (m == null) return [];
    final attrsRaw = m.group(1) ?? '';
    final bodyRaw = m.group(2) ?? '';
    final kind =
        _kKindAttrRegex.firstMatch(attrsRaw)?.group(1)?.trim() ?? 'info';
    final inner = bodyRaw.replaceAll(RegExp(r'<[^>]+>'), '');
    final text = inner.trimRight();
    return [
      calloutNode(
        kind: kind,
        delta: Delta()..insert(text),
      ),
    ];
  }
}

class SloteCalloutNodeParser extends NodeParser {
  const SloteCalloutNodeParser();

  @override
  String get id => CalloutBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    assert(node.type == CalloutBlockKeys.type);
    final delta = node.delta ?? (Delta()..insert(''));
    final kind = node.attributes[CalloutBlockKeys.kind] ?? 'info';
    final body = DeltaMarkdownEncoder().convert(delta);
    final escapedKind = kind.toString().replaceAll('"', '&quot;');
    final result = '<callout kind="$escapedKind">$body</callout>';
    final suffix = node.next == null ? '' : '\n';
    return '$result$suffix';
  }
}

