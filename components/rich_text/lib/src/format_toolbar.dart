import 'package:flutter/material.dart';

import 'rich_text_controller.dart';

/// Format toolbar that reflects current selection style and toggles formatting
/// without stacking markers (second click removes format).
///
/// Includes full Markdown-style options: bold, italic, underline, strikethrough,
/// inline code, headings (H1–H3), blockquote, code block, bullet and ordered lists.
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({
    super.key,
    required this.controller,
  });

  /// Controller that provides selection style and toggle actions.
  final RichTextController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.selectionStyleListenable,
      builder: (context, _) {
        final style = controller.selectionStyle;
        final theme = Theme.of(context);
        final color = theme.colorScheme.primary;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(context, color, style.isBold, Icons.format_bold, 'Bold', controller.toggleBold),
              _btn(context, color, style.isItalic, Icons.format_italic, 'Italic', controller.toggleItalic),
              _btn(context, color, style.isUnderline, Icons.format_underlined, 'Underline', controller.toggleUnderline),
              _btn(context, color, style.isStrikethrough, Icons.format_strikethrough, 'Strikethrough', controller.toggleStrikethrough),
              _btn(context, color, style.isInlineCode, Icons.code, 'Inline code', controller.toggleInlineCode),
              const _ToolbarDivider(),
              _btn(context, color, style.headerLevel == 1, Icons.title, 'Heading 1', () => controller.applyHeader(1)),
              _btn(context, color, style.headerLevel == 2, Icons.text_fields, 'Heading 2', () => controller.applyHeader(2)),
              _btn(context, color, style.headerLevel == 3, Icons.format_size, 'Heading 3', () => controller.applyHeader(3)),
              _btn(context, color, style.headerLevel == null && !style.isBlockQuote && !style.isCodeBlock && style.listType == null, Icons.short_text, 'Paragraph', () => controller.applyHeader(null)),
              const _ToolbarDivider(),
              _btn(context, color, style.isBlockQuote, Icons.format_quote, 'Blockquote', controller.toggleBlockQuote),
              _btn(context, color, style.isCodeBlock, Icons.data_object, 'Code block', controller.toggleCodeBlock),
              _btn(context, color, style.listType == 'bullet', Icons.format_list_bulleted, 'Bullet list', controller.toggleBulletList),
              _btn(context, color, style.listType == 'ordered', Icons.format_list_numbered, 'Numbered list', controller.toggleOrderedList),
            ],
          ),
        );
      },
    );
  }
}

Widget _btn(
  BuildContext context,
  Color activeColor,
  bool isActive,
  IconData icon,
  String tooltip,
  VoidCallback onPressed,
) {
  return Tooltip(
    message: tooltip,
    child: IconButton(
      icon: Icon(icon, color: isActive ? activeColor : null, size: 22),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(40, 40),
      ),
    ),
  );
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}
