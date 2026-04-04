import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Heading [TextStyle] per level for [HeadingBlockComponentBuilder].
///
/// **H1–H3** match AppFlowy’s stock
/// [HeadingBlockComponentBuilder] sizes (32 / 28 / 24, bold). AppFlowy uses
/// **18px for H4, H5, and H6**, which makes lower levels hard to tell apart; we
/// use **20 / 17 / 15** so the ladder stays obvious down to small headings.
///
/// [height] is set to **1.0** so it overrides [TextStyleConfiguration.lineHeight]
/// on body text: [TextSpan.updateTextStyle] merges with `height: other.height`,
/// and `null` would keep the paragraph multiplier (e.g. 1.5), inflating the
/// line box and the IME caret on heading blocks.
TextStyle sloteHeadingTextStyleForLevel(int level) {
  final lv = level.clamp(1, 6);
  const sizes = <double>[32, 28, 24, 20, 17, 15];
  return TextStyle(
    fontSize: sizes[lv - 1],
    fontWeight: FontWeight.bold,
    height: 1.0,
  );
}

/// [standardBlockComponentBuilderMap] with a [HeadingBlockComponentBuilder]
/// that applies [sloteHeadingTextStyleForLevel].
final Map<String, BlockComponentBuilder> sloteRichTextBlockComponentBuilders = {
  ...standardBlockComponentBuilderMap,
  HeadingBlockKeys.type: HeadingBlockComponentBuilder(
    configuration: standardBlockComponentConfiguration.copyWith(
      placeholderText: (node) =>
          'Heading ${node.attributes[HeadingBlockKeys.level]}',
    ),
    textStyleBuilder: sloteHeadingTextStyleForLevel,
  ),
};
