import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'rich_text_controller.dart';

/// Format toolbar: +, Bold, Underline, Italic, Other dropdown, Font size,
/// Paragraph/H1/H2/H3 dropdown, Checklist, Bullet, Numbered, Link,
/// Alignment, Clear formatting, Indent/Outdent.
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({
    super.key,
    required this.controller,
  });

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
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _moreMarkdownButton(context, color, controller),
              const _ToolbarDivider(),
              _toolbarBtn(context, color, style.isBold, LucideIcons.bold, 'Bold', controller.toggleBold),
              _toolbarBtn(context, color, style.isUnderline, LucideIcons.underline, 'Underline', controller.toggleUnderline),
              _toolbarBtn(context, color, style.isItalic, LucideIcons.italic, 'Italic', controller.toggleItalic),
              _otherDropdown(context, color, style, controller),
              _fontSizeDropdown(context, color, style, controller),
              _headingDropdown(context, color, style, controller),
              _toolbarBtn(context, color, style.isChecklist, LucideIcons.listChecks, 'Checklist', controller.toggleChecklist),
              _toolbarBtn(context, color, style.listType == 'bullet', LucideIcons.list, 'Bullet list', controller.toggleBulletList),
              _toolbarBtn(context, color, style.listType == 'ordered', LucideIcons.listOrdered, 'Numbered list', controller.toggleOrderedList),
              _linkButton(context, color, controller),
              _alignmentButtons(context, color, style, controller),
              _toolbarBtn(context, color, false, LucideIcons.eraser, 'Clear formatting', controller.clearFormatting),
              const _ToolbarDivider(),
              _toolbarBtn(context, color, false, LucideIcons.indent, 'Indent (Tab)', controller.increaseIndent),
              _toolbarBtn(context, color, false, LucideIcons.outdent, 'Outdent', controller.decreaseIndent),
            ],
          ),
        );
      },
    );
  }

  Widget _moreMarkdownButton(BuildContext context, Color color, RichTextController controller) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Insert block',
      icon: Icon(LucideIcons.plus, size: 22, color: theme.colorScheme.onSurface),
      onSelected: (value) {
        switch (value) {
          case 'codeblock':
            controller.insertSyntaxCodeBlock();
            break;
          case 'horizontalrule':
            controller.insertHorizontalRule();
            break;
          // case 'table':
          //   _showTableSizeDialog(context, controller);
          //   break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'codeblock', child: Text('Code block')),
        const PopupMenuItem(value: 'horizontalrule', child: Text('Horizontal line')),
        // const PopupMenuItem(value: 'table', child: Text('Table')),
      ],
    );
  }

  // Table insert dialog – disabled for now; uncomment when re-enabling table.
  // ignore: unused_element
  Future<void> _showTableSizeDialog(BuildContext context, RichTextController controller) async {
    const maxCols = 7;
    const maxRows = 5;
    int selectedCols = 2;
    int selectedRows = 2;

    final result = await showDialog<(int, int)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Insert table'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select size',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Table(
                    children: [
                      for (var r = 0; r < maxRows; r++)
                        TableRow(
                          children: [
                            for (var c = 0; c < maxCols; c++)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCols = c + 1;
                                    selectedRows = r + 1;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: (c < selectedCols && r < selectedRows)
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '$selectedCols × $selectedRows',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop((selectedCols, selectedRows)),
                child: const Text('Insert'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && context.mounted) {
      controller.insertTableWithSize(result.$1, result.$2);
    }
  }

  Widget _otherDropdown(BuildContext context, Color color, SelectionStyleState style, RichTextController controller) {
    return PopupMenuButton<String>(
      tooltip: 'More formatting',
      icon: Icon(LucideIcons.moreHorizontal, size: 22),
      onSelected: (value) {
        switch (value) {
          case 'strikethrough':
            controller.toggleStrikethrough();
            break;
          case 'inlinecode':
            controller.toggleInlineCode();
            break;
          case 'subscript':
            controller.toggleSubscript();
            break;
          case 'superscript':
            controller.toggleSuperscript();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'strikethrough',
          child: Row(
            children: [
              Icon(LucideIcons.strikethrough, size: 20, color: style.isStrikethrough ? color : null),
              const SizedBox(width: 8),
              const Text('Strikethrough'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'inlinecode',
          child: Row(
            children: [
              Icon(LucideIcons.code, size: 20, color: style.isInlineCode ? color : null),
              const SizedBox(width: 8),
              const Text('Inline code'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'subscript',
          child: Row(
            children: [
              Icon(LucideIcons.subscript, size: 20, color: style.isSubscript ? color : null),
              const SizedBox(width: 8),
              const Text('Subscript'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'superscript',
          child: Row(
            children: [
              Icon(LucideIcons.superscript, size: 20, color: style.isSuperscript ? color : null),
              const SizedBox(width: 8),
              const Text('Superscript'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fontSizeDropdown(BuildContext context, Color color, SelectionStyleState style, RichTextController controller) {
    // Map flutter_quill size keys to exact pixel values (match DefaultStyles)
    const sizeToPx = {'small': 10, 'normal': 16, 'large': 18, 'huge': 22};
    const sizes = ['small', 'normal', 'large', 'huge'];
    final current = style.sizeLabel ?? 'normal';
    final currentPx = sizeToPx[current] ?? 16;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<String>(
        tooltip: 'Font size',
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${currentPx}px', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            Icon(LucideIcons.chevronDown, size: 16),
          ],
        ),
        onSelected: (value) => controller.applySize(value),
        itemBuilder: (context) => sizes
            .map((s) => PopupMenuItem(
                  value: s,
                  child: Text('${sizeToPx[s]}px', style: TextStyle(fontWeight: s == current ? FontWeight.bold : null)),
                ))
            .toList(),
      ),
    );
  }

  Widget _headingDropdown(BuildContext context, Color color, SelectionStyleState style, RichTextController controller) {
    final label = style.headerLevel != null ? 'H${style.headerLevel}' : 'Paragraph';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<int?>(
        tooltip: 'Paragraph / Heading',
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.type, size: 18, color: style.headerLevel != null ? color : null),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                label,
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(LucideIcons.chevronDown, size: 16),
          ],
        ),
        onSelected: (level) => controller.applyHeader(level),
        itemBuilder: (context) => [
          PopupMenuItem(value: null, child: Text('Paragraph', style: TextStyle(fontWeight: style.headerLevel == null ? FontWeight.bold : null))),
          PopupMenuItem(value: 1, child: Text('Heading 1', style: TextStyle(fontWeight: style.headerLevel == 1 ? FontWeight.bold : null, fontSize: 18))),
          PopupMenuItem(value: 2, child: Text('Heading 2', style: TextStyle(fontWeight: style.headerLevel == 2 ? FontWeight.bold : null, fontSize: 16))),
          PopupMenuItem(value: 3, child: Text('Heading 3', style: TextStyle(fontWeight: style.headerLevel == 3 ? FontWeight.bold : null, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _linkButton(BuildContext context, Color color, RichTextController controller) {
    return Tooltip(
      message: 'Insert link',
      child: IconButton(
        icon: Icon(LucideIcons.link, size: 20),
        onPressed: () => _showLinkDialog(context, controller),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(32, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context, RichTextController controller) async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert link'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(urlController.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    urlController.dispose();
    if (result != null && result.isNotEmpty) {
      controller.applyLink(result);
    }
  }

  Widget _alignmentButtons(BuildContext context, Color color, SelectionStyleState style, RichTextController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toolbarBtn(
          context,
          color,
          style.alignment == TextAlign.left,
          LucideIcons.alignLeft,
          'Align left',
          () => controller.applyAlignment(TextAlign.left),
        ),
        _toolbarBtn(
          context,
          color,
          style.alignment == TextAlign.center,
          LucideIcons.alignCenter,
          'Align center',
          () => controller.applyAlignment(TextAlign.center),
        ),
        _toolbarBtn(
          context,
          color,
          style.alignment == TextAlign.right,
          LucideIcons.alignRight,
          'Align right',
          () => controller.applyAlignment(TextAlign.right),
        ),
      ],
    );
  }
}

Widget _toolbarBtn(
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
      icon: Icon(icon, color: isActive ? activeColor : null, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}
