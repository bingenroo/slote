import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'embed_builders.dart';
import 'rich_text_controller.dart';

/// Builds [QuillEditorConfig] with Telegram-like code block styling,
/// distinct H1/H2/H3 headings, and optional Tab-to-indent for desktop/web.
///
/// Line breaks use the editor's default handling so the document stays in sync
/// with the platform text input (avoids assertion/crash on Enter).
QuillEditorConfig richTextEditorConfig(
  BuildContext context, {
  bool enableIndentOnTab = false,
  RichTextController? controller,
}) {
  final defaultStyles = DefaultStyles.getInstance(context);
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final textColor = theme.colorScheme.onSurface;

  // Base text style from theme (font identity + color). Used so attribute-only
  // inline styles set only their property and leave others null for merge.
  final baseStyle = theme.textTheme.bodyLarge!;
  final baseFontFamily = baseStyle.fontFamily;
  final baseFontSize = baseStyle.fontSize;

  // Telegram-like code block: dark background, monospace, left border
  final codeBlockBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D);
  final codeBlockTextColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFFE8E8E8);
  const baseHorizontalSpacing = HorizontalSpacing(0, 0);

  final codeStyle = DefaultTextBlockStyle(
    TextStyle(
      color: codeBlockTextColor,
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.4,
      decoration: TextDecoration.none,
    ),
    const HorizontalSpacing(12, 12),
    const VerticalSpacing(12, 12),
    VerticalSpacing.zero,
    BoxDecoration(
      color: codeBlockBg,
      borderRadius: BorderRadius.circular(4),
      border: Border(
        left: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 3,
        ),
      ),
    ),
  );

  // Inline code: VS Code–like chip (dark bg, muted text, rounded, subtle border feel)
  final inlineCodeBg = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE8E8E8);
  final inlineCodeTextColor = isDark ? const Color(0xFF999999) : const Color(0xFF555555);
  final inlineCodeStyle = InlineCodeStyle(
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: baseStyle.fontSize ?? 14,
      color: inlineCodeTextColor,
      decoration: TextDecoration.none,
    ),
    backgroundColor: inlineCodeBg,
    radius: const Radius.circular(6),
  );

  // Distinct H1 (largest), H2, H3
  final h1Style = DefaultTextBlockStyle(
    theme.textTheme.bodyLarge!.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textColor,
      height: 1.2,
      letterSpacing: -0.5,
      decoration: TextDecoration.none,
    ),
    baseHorizontalSpacing,
    const VerticalSpacing(12, 8),
    VerticalSpacing.zero,
    null,
  );
  final h2Style = DefaultTextBlockStyle(
    theme.textTheme.bodyLarge!.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: textColor,
      height: 1.25,
      letterSpacing: -0.3,
      decoration: TextDecoration.none,
    ),
    baseHorizontalSpacing,
    const VerticalSpacing(8, 6),
    VerticalSpacing.zero,
    null,
  );
  final h3Style = DefaultTextBlockStyle(
    theme.textTheme.bodyLarge!.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textColor,
      height: 1.3,
      letterSpacing: -0.2,
      decoration: TextDecoration.none,
    ),
    baseHorizontalSpacing,
    const VerticalSpacing(6, 4),
    VerticalSpacing.zero,
    null,
  );

  final customStyles = defaultStyles.merge(DefaultStyles(
    color: textColor,
    paragraph: DefaultTextBlockStyle(
      baseStyle.copyWith(
        color: textColor,
        decoration: TextDecoration.none,
      ),
      defaultStyles.paragraph!.horizontalSpacing,
      defaultStyles.paragraph!.verticalSpacing,
      defaultStyles.paragraph!.lineSpacing,
      defaultStyles.paragraph!.decoration,
    ),
    leading: defaultStyles.leading != null
        ? DefaultTextBlockStyle(
            defaultStyles.leading!.style.copyWith(color: textColor),
            defaultStyles.leading!.horizontalSpacing,
            defaultStyles.leading!.verticalSpacing,
            defaultStyles.leading!.lineSpacing,
            defaultStyles.leading!.decoration,
          )
        : null,
    lists: defaultStyles.lists != null
        ? DefaultListBlockStyle(
            // Use paragraph style so bullet/ordered/checklist lines match body text.
            baseStyle.copyWith(
              color: textColor,
              decoration: TextDecoration.none,
            ),
            defaultStyles.lists!.horizontalSpacing,
            defaultStyles.lists!.verticalSpacing,
            defaultStyles.lists!.lineSpacing,
            defaultStyles.lists!.decoration,
            defaultStyles.lists!.checkboxUIBuilder,
            indentWidthBuilder: defaultStyles.lists!.indentWidthBuilder,
            numberPointWidthBuilder: defaultStyles.lists!.numberPointWidthBuilder,
          )
        : null,
    // Attribute-only inline styles so TextStyle.merge preserves other attributes
    // (e.g. bold+italic+underline all visible). Only set the property each format
    // represents; leave fontWeight/fontStyle/decoration null on others.
    bold: TextStyle(
      fontFamily: baseFontFamily,
      fontSize: baseFontSize,
      fontWeight: FontWeight.w800,
      color: textColor,
      decoration: TextDecoration.none,
      letterSpacing: 0.5,
    ),
    italic: TextStyle(
      fontFamily: baseFontFamily,
      fontSize: baseFontSize,
      fontStyle: FontStyle.italic,
      color: textColor,
      decoration: TextDecoration.none,
    ),
    underline: TextStyle(
      fontFamily: baseFontFamily,
      fontSize: baseFontSize,
      color: textColor,
      decoration: TextDecoration.underline,
      decorationColor: textColor,
      decorationThickness: 1.0,
      decorationStyle: TextDecorationStyle.solid,
    ),
    strikeThrough: TextStyle(
      fontFamily: baseFontFamily,
      fontSize: baseFontSize,
      color: textColor,
      decoration: TextDecoration.lineThrough,
      decorationColor: textColor,
      decorationThickness: 1.0,
      decorationStyle: TextDecorationStyle.solid,
    ),
    link: TextStyle(
      fontFamily: baseFontFamily,
      fontSize: baseFontSize,
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
      decorationThickness: 1.0,
      decorationStyle: TextDecorationStyle.solid,
    ),
    h1: h1Style,
    h2: h2Style,
    h3: h3Style,
    code: codeStyle,
    inlineCode: inlineCodeStyle,
  ));

  return QuillEditorConfig(
    customStyles: customStyles,
    enableAlwaysIndentOnTab: enableIndentOnTab,
    embedBuilders: [
      const HorizontalRuleEmbedBuilder(),
      // Table disabled for now; code kept in embed_builders.dart for future use.
      // TableEmbedBuilder(
      //   onReplaceTable: controller != null
      //       ? (offset, newMarkdown) => controller!.replaceTableEmbedAt(offset, newMarkdown)
      //       : null,
      // ),
    ],
  );
}
