// Custom block syntax that parses fenced code (```lang ... ```) and produces
// an element with [syntaxCodeBlockType] and attributes {language, data}
// so [MarkdownToDelta] can convert it to our syntax-highlighted embed.

import 'package:markdown/markdown.dart';

import 'syntax_code_block.dart';

/// Same pattern as markdown's codeFencePattern (``` or ~~~ with optional info string).
final _codeFencePattern = RegExp(
  r'^([ ]{0,3})(?:(?<backtick>`{3,})(?<backtickInfo>[^`]*)|'
  r'(?<tilde>~{3,})(?<tildeInfo>.*))$',
);

/// Parses fenced code blocks and produces [syntaxCodeBlockType] element
/// with attributes so [customElementToEmbeddable] can create [SyntaxCodeBlockEmbed].
class FencedCodeToEmbedSyntax extends BlockSyntax {
  const FencedCodeToEmbedSyntax();

  @override
  RegExp get pattern => _codeFencePattern;

  @override
  Node? parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;

    final isBacktick = match.namedGroup('backtick') != null;
    final info = (match.namedGroup('backtickInfo') ?? match.namedGroup('tildeInfo') ?? '').trim();
    final language = info.split(' ').first;

    parser.advance();
    final codeLines = <String>[];
    final indentLen = match[1]?.length ?? 0;

    while (!parser.isDone) {
      final closeMatch = pattern.firstMatch(parser.current.content);
      final hasInfo = ((closeMatch?.namedGroup('backtickInfo') ?? closeMatch?.namedGroup('tildeInfo')) ?? '').trim().isNotEmpty;
      final sameFence = closeMatch != null &&
          ((isBacktick && closeMatch.namedGroup('backtick') != null) ||
              (!isBacktick && closeMatch.namedGroup('tilde') != null));
      if (sameFence && !hasInfo) {
        parser.advance();
        break;
      }
      var content = parser.current.content;
      if (indentLen > 0 && content.length >= indentLen) {
        content = content.substring(indentLen);
      }
      codeLines.add(content);
      parser.advance();
    }

    var code = codeLines.join('\n');
    if (code.isNotEmpty && !code.endsWith('\n')) {
      code = '$code\n';
    }

    final el = Element.empty(syntaxCodeBlockType);
    el.attributes['language'] = language;
    el.attributes['data'] = code;
    return el;
  }
}
