import 'package:flutter/material.dart';

List<String> _splitSingleAsterisks(String text) {
  final result = <String>[];
  var start = 0;
  var i = 0;
  while (i < text.length) {
    if (text[i] == '*') {
      final isDouble = i + 1 < text.length && text[i + 1] == '*';
      if (!isDouble) {
        result.add(text.substring(start, i));
        start = i + 1;
        final end = text.indexOf('*', start);
        if (end == -1) {
          result.add(text.substring(start));
          return result;
        }
        result.add(text.substring(start, end));
        start = end + 1;
        i = end;
      } else {
        i++;
      }
    }
    i++;
  }
  result.add(text.substring(start));
  return result;
}

/// Parses markdown-style markers (** *, __) and returns a list of [TextSpan]s.
List<TextSpan> parseFormattedSpans(
  String text, {
  required TextStyle baseStyle,
  TextStyle? boldStyle,
  TextStyle? italicStyle,
  TextStyle? underlineStyle,
}) {
  final bold = boldStyle ?? baseStyle.copyWith(fontWeight: FontWeight.bold);
  final italic = italicStyle ?? baseStyle.copyWith(fontStyle: FontStyle.italic);
  final underline = underlineStyle ?? baseStyle.copyWith(decoration: TextDecoration.underline);
  final styles = <String, TextStyle>{
    'b': bold,
    'i': italic,
    'u': underline,
  };

  List<({String text, Set<String> flags})> segments = [(text: text, flags: <String>{})];

  void applyMarker(String marker, String flag) {
    final next = <({String text, Set<String> flags})>[];
    for (final seg in segments) {
      if (marker == '*') {
        final parts = _splitSingleAsterisks(seg.text);
        if (parts.length > 1) {
          for (var i = 0; i < parts.length; i++) {
            final newFlags = Set<String>.from(seg.flags);
            if (i.isOdd) newFlags.add(flag);
            next.add((text: parts[i], flags: newFlags));
          }
        } else {
          next.add(seg);
        }
      } else {
        final parts = seg.text.split(marker);
        if (parts.length.isOdd && parts.length > 1) {
          for (var i = 0; i < parts.length; i++) {
            final newFlags = Set<String>.from(seg.flags);
            if (i.isOdd) newFlags.add(flag);
            next.add((text: parts[i], flags: newFlags));
          }
        } else {
          next.add(seg);
        }
      }
    }
    segments = next;
  }

  applyMarker('**', 'b');
  applyMarker('__', 'u');
  applyMarker('*', 'i');

  return segments
      .where((s) => s.text.isNotEmpty)
      .map((s) {
        TextStyle segStyle = baseStyle;
        for (final flag in s.flags) {
          segStyle = segStyle.merge(styles[flag]);
        }
        return TextSpan(text: s.text, style: segStyle);
      })
      .toList();
}

/// Displays text with **bold**, *italic*, and __underline__ markers rendered as styles.
class FormattedText extends StatelessWidget {
  const FormattedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = parseFormattedSpans(text, baseStyle: baseStyle);
    if (spans.isEmpty) return const SizedBox.shrink();
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
