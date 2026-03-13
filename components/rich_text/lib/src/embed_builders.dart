import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'rich_text_controller.dart';
import 'syntax_code_block.dart';

/// Type key for horizontal rule block embed (must match [horizontalRule] / markdown_quill).
const String horizontalRuleType = 'divider';

/// Horizontal rule (divider) block embed. Renders as a horizontal line with fixed weight.
///
/// Uses a fixed border instead of [Divider] so thickness is identical whether
/// the rule is at the start, middle, or end of a block.
class HorizontalRuleEmbedBuilder extends EmbedBuilder {
  const HorizontalRuleEmbedBuilder();

  /// Line thickness in logical pixels. Slightly above 1 so the rule is clearly
  /// visible on high-DPI screens without looking heavy.
  static const double _lineWeight = 1.5;

  @override
  String get key => horizontalRuleType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final color = Theme.of(context).dividerColor;
    // Minimal vertical padding so block spacing (from DefaultStyles) isn't doubled
    // and layout doesn't "bounce" when typing at the end of adjacent lines.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: _lineWeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: _lineWeight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Syntax-highlighted code block embed (from markdown ```lang ... ``` or toolbar).
class SyntaxCodeBlockEmbedBuilder extends EmbedBuilder {
  const SyntaxCodeBlockEmbedBuilder({
    this.onReplaceCodeBlock,
    this.controller,
    this.editorFocusRequester,
  });

  /// When set, the block footer shows a language dropdown; on change this is called to update the embed.
  final void Function(int embedOffset, String language, String code)? onReplaceCodeBlock;

  /// When set with [editorFocusRequester], selection is synced so only one cursor shows and arrow keys exit the block.
  final RichTextController? controller;

  /// When set with [controller], code block can request focus back to the editor when exiting with arrow keys.
  final EditorFocusRequester? editorFocusRequester;

  @override
  String get key => syntaxCodeBlockType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final value = embedContext.node.value;
    final data = _getEmbedData(value);
    final firstNewline = data.indexOf('\n');
    final language = firstNewline >= 0 ? data.substring(0, firstNewline).trim() : '';
    final code = firstNewline >= 0 ? data.substring(firstNewline + 1) : data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offset = embedContext.node.documentOffset;
    void onLanguageChanged(String newLanguage) {
      onReplaceCodeBlock?.call(offset, newLanguage, code);
    }
    void onCodeChanged(String newCode) {
      onReplaceCodeBlock?.call(offset, language, newCode);
    }

    final codeBlockWidget = SyntaxCodeBlockWidget(
      code: code,
      language: language,
      isDark: isDark,
      onLanguageChanged: onReplaceCodeBlock != null ? onLanguageChanged : null,
      onCodeChanged: onReplaceCodeBlock != null ? onCodeChanged : null,
      embedOffset: offset,
      onFocusGained: (controller != null && editorFocusRequester != null)
          ? () => controller!.moveSelectionTo(offset)
          : null,
      onExitUp: (controller != null && editorFocusRequester != null)
          ? () {
              controller!.moveSelectionTo(offset);
              editorFocusRequester!.requestFocus();
            }
          : null,
      onExitDown: (controller != null && editorFocusRequester != null)
          ? () {
              controller!.moveSelectionTo(offset + 1);
              editorFocusRequester!.requestFocus();
            }
          : null,
    );

    if (controller != null && editorFocusRequester != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _CodeBlockFocusSync(
          quillController: controller!.quillController,
          embedOffset: offset,
          code: code,
          language: language,
          isDark: isDark,
          onLanguageChanged: onReplaceCodeBlock != null ? onLanguageChanged : null,
          onCodeChanged: onReplaceCodeBlock != null ? onCodeChanged : null,
          onFocusGained: () => controller!.moveSelectionTo(offset),
          onExitUp: () {
            controller!.moveSelectionTo(offset);
            editorFocusRequester!.requestFocus();
          },
          onExitDown: () {
            controller!.moveSelectionTo(offset + 1);
            editorFocusRequester!.requestFocus();
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: codeBlockWidget,
    );
  }

  static String _getEmbedData(dynamic value) {
    if (value == null) return '';
    if (value is Map && value.containsKey('data')) return (value['data'] as String?) ?? '';
    try {
      if (value.data is String) return value.data as String;
    } catch (_) {}
    return '';
  }
}

/// Listens to Quill selection and hands focus to the code block when selection lands on the embed
/// (arrow down), so the editor doesn't replace the embed with selected text.
class _CodeBlockFocusSync extends StatefulWidget {
  const _CodeBlockFocusSync({
    required this.quillController,
    required this.embedOffset,
    required this.code,
    required this.language,
    required this.isDark,
    this.onLanguageChanged,
    this.onCodeChanged,
    required this.onFocusGained,
    required this.onExitUp,
    required this.onExitDown,
  });

  final QuillController quillController;
  final int embedOffset;
  final String code;
  final String language;
  final bool isDark;
  final void Function(String newLanguage)? onLanguageChanged;
  final void Function(String newCode)? onCodeChanged;
  final VoidCallback onFocusGained;
  final VoidCallback onExitUp;
  final VoidCallback onExitDown;

  @override
  State<_CodeBlockFocusSync> createState() => _CodeBlockFocusSyncState();
}

class _CodeBlockFocusSyncState extends State<_CodeBlockFocusSync> {
  VoidCallback? _requestCodeBlockFocus;

  @override
  void initState() {
    super.initState();
    widget.quillController.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant _CodeBlockFocusSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quillController != widget.quillController ||
        oldWidget.embedOffset != widget.embedOffset) {
      oldWidget.quillController.removeListener(_onSelectionChanged);
      widget.quillController.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.quillController.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final sel = widget.quillController.selection;
    if (sel.isCollapsed && sel.start == widget.embedOffset && _requestCodeBlockFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestCodeBlockFocus?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SyntaxCodeBlockWidget(
      code: widget.code,
      language: widget.language,
      isDark: widget.isDark,
      onLanguageChanged: widget.onLanguageChanged,
      onCodeChanged: widget.onCodeChanged,
      embedOffset: widget.embedOffset,
      onFocusGained: widget.onFocusGained,
      onExitUp: widget.onExitUp,
      onExitDown: widget.onExitDown,
      registerRequestFocus: (fn) => _requestCodeBlockFocus = fn,
    );
  }
}

/// Table block embed. Renders markdown table data as a [Table] widget.
///
/// When [onReplaceTable] is non-null, cells are editable and changes are
/// written back via the callback. Otherwise cells are read-only text.
/// DISABLED: Commented out for now; uncomment block below and in
/// rich_text_editor_config.dart + format_toolbar.dart to re-enable.
/*
class TableEmbedBuilder extends EmbedBuilder {
  const TableEmbedBuilder({this.onReplaceTable});

  final void Function(int offset, String newMarkdown)? onReplaceTable;

  @override
  String get key => EmbeddableTable.tableType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final value = embedContext.node.value;
    final data = (value.data is String) ? (value.data as String) : '';
    final rows = _parseTableData(data);
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;
    final headerBg = theme.colorScheme.surfaceContainerHighest;
    final bodyBg = theme.colorScheme.surface;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    // Table always occupies full line so text never wraps around it.
    const bool isBlock = true;

    if (rows.isEmpty) {
      final editable = onReplaceTable != null && !embedContext.readOnly;
      if (editable) {
        // Embed stored without table data (e.g. serialization quirk). Show default
        // 2x2 editable grid so the user can fill it; persisting writes correct markdown.
        const defaultRows = [
          [' ', ' '],
          [' ', ' '],
        ];
        return _wrapIfBlock(
          isBlock,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isBlock ? 56 : 48,
              minWidth: isBlock ? 200 : 0,
            ),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _EditableTableContent(
                    initialRows: defaultRows,
                    embedOffset: embedContext.node.documentOffset,
                    borderColor: borderColor,
                    headerBg: headerBg,
                    bodyBg: bodyBg,
                    textStyle: textStyle!,
                    onReplaceTable: onReplaceTable!,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return _wrapIfBlock(
        isBlock,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bodyBg,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'Table (no rows)',
              style: textStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    final editable = onReplaceTable != null && !embedContext.readOnly;
    final tableContent = editable
        ? _EditableTableContent(
            initialRows: rows,
            embedOffset: embedContext.node.documentOffset,
            borderColor: borderColor,
            headerBg: headerBg,
            bodyBg: bodyBg,
            textStyle: textStyle!,
            onReplaceTable: onReplaceTable!,
          )
        : _buildStaticTable(
            rows: rows,
            borderColor: borderColor,
            headerBg: headerBg,
            bodyBg: bodyBg,
            textStyle: textStyle!,
          );

    return _wrapIfBlock(
      isBlock,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isBlock ? 56 : 48,
          minWidth: isBlock ? 200 : 0,
        ),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: tableContent,
            ),
          ),
        ),
      ),
    );
  }

  static Table _buildStaticTable({
    required List<List<String>> rows,
    required Color borderColor,
    required Color headerBg,
    required Color bodyBg,
    required TextStyle textStyle,
  }) {
    return Table(
      border: TableBorder.all(color: borderColor, width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(color: i == 0 ? headerBg : bodyBg),
            children: rows[i]
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        cell.isEmpty ? ' ' : cell,
                        style: textStyle.copyWith(
                          fontWeight: i == 0 ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _wrapIfBlock(bool isBlock, {required Widget child}) {
    if (!isBlock) return child;
    return SizedBox(width: double.infinity, child: child);
  }

  /// Parse markdown table string into rows of cell strings.
  static List<List<String>> _parseTableData(String data) {
    final normalized = data.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (lines.isEmpty) return [];
    final rows = <List<String>>[];
    final separatorCell = RegExp(r'^[\s\-]*$');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final cells = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (cells.isEmpty) continue;
      final isSeparatorRow = cells.every((c) => c.contains('-') && separatorCell.hasMatch(c));
      if (isSeparatorRow) continue;
      rows.add(cells);
    }
    return rows;
  }

  /// Convert rows back to markdown (header + separator + body).
  static String rowsToMarkdown(List<List<String>> rows) {
    if (rows.isEmpty) return '';
    final cols = rows.first.length;
    final sb = StringBuffer();
    sb.writeln('|${rows[0].map((c) => c.isEmpty ? ' ' : c).join('|')}|');
    sb.writeln('|${List.filled(cols, '---').join('|')}|');
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final padded = row.length >= cols ? row : [...row, ...List.filled(cols - row.length, ' ')];
      sb.writeln('|${padded.map((c) => c.isEmpty ? ' ' : c).join('|')}|');
    }
    return sb.toString();
  }
}

/// Editable table: TextField per cell, persists via [onReplaceTable] on unfocus.
class _EditableTableContent extends StatefulWidget {
  const _EditableTableContent({
    required this.initialRows,
    required this.embedOffset,
    required this.borderColor,
    required this.headerBg,
    required this.bodyBg,
    required this.textStyle,
    required this.onReplaceTable,
  });

  final List<List<String>> initialRows;
  final int embedOffset;
  final Color borderColor;
  final Color headerBg;
  final Color bodyBg;
  final TextStyle textStyle;
  final void Function(int offset, String newMarkdown) onReplaceTable;

  @override
  State<_EditableTableContent> createState() => _EditableTableContentState();
}

class _EditableTableContentState extends State<_EditableTableContent> {
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialRows
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
    _focusNodes = List.generate(
      widget.initialRows.length,
      (i) => List.generate(widget.initialRows[i].length, (_) => FocusNode()),
    );
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final c in row) c.dispose();
    }
    for (final row in _focusNodes) {
      for (final fn in row) fn.dispose();
    }
    super.dispose();
  }

  void _persistTable() {
    final rows = _controllers
        .map((row) => row.map((c) => c.text).toList())
        .toList();
    widget.onReplaceTable(widget.embedOffset, TableEmbedBuilder.rowsToMarkdown(rows));
  }

  bool _handleCellKeyEvent(int row, int col, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final rows = _controllers.length;
    final cols = _controllers[row].length;
    final controller = _controllers[row][col];
    final sel = controller.selection;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (sel.isCollapsed && sel.baseOffset == controller.text.length) {
        if (col + 1 < cols) {
          _focusNodes[row][col + 1].requestFocus();
          return true;
        }
        if (row + 1 < rows) {
          _focusNodes[row + 1][0].requestFocus();
          return true;
        }
      }
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (sel.isCollapsed && sel.baseOffset == 0) {
        if (col > 0) {
          _focusNodes[row][col - 1].requestFocus();
          return true;
        }
        if (row > 0) {
          final prevCols = _controllers[row - 1].length;
          _focusNodes[row - 1][prevCols - 1].requestFocus();
          return true;
        }
      }
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (row + 1 < rows) {
        final nextCols = _controllers[row + 1].length;
        final targetCol = col < nextCols ? col : nextCols - 1;
        _focusNodes[row + 1][targetCol].requestFocus();
        return true;
      }
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (row > 0) {
        final prevCols = _controllers[row - 1].length;
        final targetCol = col < prevCols ? col : prevCols - 1;
        _focusNodes[row - 1][targetCol].requestFocus();
        return true;
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: widget.borderColor, width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        for (var i = 0; i < _controllers.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == 0 ? widget.headerBg : widget.bodyBg,
            ),
            children: _controllers[i]
                .asMap()
                .entries
                .map(
                  (entry) {
                    final j = entry.key;
                    final controller = entry.value;
                    final focusNode = _focusNodes[i][j];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Focus(
                        focusNode: focusNode,
                        onKeyEvent: (FocusNode node, KeyEvent event) {
                          if (_handleCellKeyEvent(i, j, event)) {
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (context) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              ),
                              style: widget.textStyle.copyWith(
                                fontWeight: i == 0 ? FontWeight.w600 : null,
                              ),
                              onTapOutside: (_) => _persistTable(),
                              onSubmitted: (_) => _persistTable(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                )
                .toList(),
          ),
      ],
    );
  }
}
*/
