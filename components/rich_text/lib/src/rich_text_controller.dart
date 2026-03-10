import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// Style flags for the current selection/caret, used by the format toolbar.
class SelectionStyleState {
  const SelectionStyleState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isInlineCode = false,
    this.isSubscript = false,
    this.isSuperscript = false,
    this.headerLevel,
    this.isBlockQuote = false,
    this.isCodeBlock = false,
    this.listType,
    this.sizeLabel,
    this.alignment,
    this.indentLevel = 0,
  });

  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isInlineCode;
  final bool isSubscript;
  final bool isSuperscript;
  /// 1, 2, or 3 for H1/H2/H3; null for paragraph.
  final int? headerLevel;
  final bool isBlockQuote;
  final bool isCodeBlock;
  /// 'bullet', 'ordered', 'checked', or 'unchecked' for list; null for normal block.
  final String? listType;
  /// 'small', 'normal', 'large', 'huge' for font size.
  final String? sizeLabel;
  /// Current block alignment.
  final TextAlign? alignment;
  /// Current block indent level (0, 1, 2, 3).
  final int indentLevel;

  bool get isChecklist => listType == 'checked' || listType == 'unchecked';

  SelectionStyleState copyWith({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    bool? isInlineCode,
    bool? isSubscript,
    bool? isSuperscript,
    int? headerLevel,
    bool? isBlockQuote,
    bool? isCodeBlock,
    String? listType,
    String? sizeLabel,
    TextAlign? alignment,
    int? indentLevel,
  }) {
    return SelectionStyleState(
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      isInlineCode: isInlineCode ?? this.isInlineCode,
      isSubscript: isSubscript ?? this.isSubscript,
      isSuperscript: isSuperscript ?? this.isSuperscript,
      headerLevel: headerLevel ?? this.headerLevel,
      isBlockQuote: isBlockQuote ?? this.isBlockQuote,
      isCodeBlock: isCodeBlock ?? this.isCodeBlock,
      listType: listType ?? this.listType,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      alignment: alignment ?? this.alignment,
      indentLevel: indentLevel ?? this.indentLevel,
    );
  }
}

/// Controller for the WYSIWYG rich text editor.
///
/// Wraps [QuillController] and exposes:
/// - [markdown] / [loadMarkdown] for DB-ready serialization
/// - [selectionStyle] (listenable) for toolbar state
/// - Debounced [onMarkdownChanged] to avoid lag on every keystroke
class RichTextController extends ChangeNotifier {
  RichTextController({
    String? initialMarkdown,
    this.debounceMarkdownDuration = const Duration(milliseconds: 200),
    void Function(String markdown)? onMarkdownChanged,
  })  : _onMarkdownChanged = onMarkdownChanged,
        _quillController = _createController(initialMarkdown ?? '') {
    _quillController.addListener(_onQuillChanged);
  }

  final void Function(String)? _onMarkdownChanged;
  final Duration debounceMarkdownDuration;
  Timer? _markdownDebounce;
  String? _lastEmittedMarkdown;

  late final QuillController _quillController;

  /// The underlying Quill controller. Use for [QuillEditor] and formatting.
  QuillController get quillController => _quillController;

  /// Current selection style (inline + block) for toolbar.
  SelectionStyleState get selectionStyle {
    final style = _quillController.getSelectionStyle();
    final attrs = style.attributes;
    int? headerLevel;
    final headerAttr = attrs[Attribute.header.key];
    if (headerAttr != null && headerAttr.value != null) {
      final v = headerAttr.value;
      if (v is int && v >= 1 && v <= 3) headerLevel = v;
    }
    String? listType;
    final listAttr = attrs[Attribute.list.key];
    if (listAttr != null && listAttr.value != null) {
      final v = listAttr.value.toString();
      if (v == 'bullet' || v == 'ordered' || v == 'checked' || v == 'unchecked') listType = v;
    }
    String? sizeLabel;
    final sizeAttr = attrs[Attribute.size.key];
    if (sizeAttr != null && sizeAttr.value != null) {
      final v = sizeAttr.value.toString();
      if (v == 'small' || v == 'large' || v == 'huge') sizeLabel = v;
    } else {
      sizeLabel = 'normal';
    }
    TextAlign? alignment;
    final alignAttr = attrs[Attribute.align.key];
    if (alignAttr != null && alignAttr.value != null) {
      switch (alignAttr.value.toString()) {
        case 'left':
          alignment = TextAlign.left;
          break;
        case 'center':
          alignment = TextAlign.center;
          break;
        case 'right':
          alignment = TextAlign.right;
          break;
        case 'justify':
          alignment = TextAlign.justify;
          break;
      }
    }
    int indentLevel = 0;
    final indentAttr = attrs[Attribute.indent.key];
    if (indentAttr != null && indentAttr.value != null && indentAttr.value is int) {
      indentLevel = indentAttr.value as int;
    }
    return SelectionStyleState(
      isBold: attrs.containsKey(Attribute.bold.key),
      isItalic: attrs.containsKey(Attribute.italic.key),
      isUnderline: attrs.containsKey(Attribute.underline.key),
      isStrikethrough: attrs.containsKey(Attribute.strikeThrough.key),
      isInlineCode: attrs.containsKey(Attribute.inlineCode.key),
      isSubscript: attrs[Attribute.script.key] == Attribute.subscript,
      isSuperscript: attrs[Attribute.script.key] == Attribute.superscript,
      headerLevel: headerLevel,
      isBlockQuote: attrs.containsKey(Attribute.blockQuote.key),
      isCodeBlock: attrs.containsKey(Attribute.codeBlock.key),
      listType: listType,
      sizeLabel: sizeLabel,
      alignment: alignment,
      indentLevel: indentLevel,
    );
  }

  /// Exposes a listenable for selection/style changes (e.g. toolbar rebuild).
  Listenable get selectionStyleListenable => _quillController;

  /// Export current document to markdown. Safe to call occasionally; do not
  /// call in build() or on every frame—use [onMarkdownChanged] (debounced) for
  /// persistence to avoid performance impact. Conversion runs only when this
  /// getter or the debounced callback is invoked.
  String get markdown {
    final delta = _quillController.document.toDelta();
    return _deltaToMarkdown.convert(delta);
  }

  /// Load document from markdown (e.g. from DB). Replaces current content.
  void loadMarkdown(String markdown) {
    final delta = _markdownToDelta.convert(markdown);
    final doc = Document.fromDelta(delta);
    _quillController.document = doc;
    _quillController.updateSelection(
      TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    notifyListeners();
  }

  /// Toggle bold at current selection. Collapsed cursor: next typed text is bold.
  void toggleBold() => _toggleAttribute(Attribute.bold);

  /// Toggle italic at current selection.
  void toggleItalic() => _toggleAttribute(Attribute.italic);

  /// Toggle underline at current selection.
  void toggleUnderline() => _toggleAttribute(Attribute.underline);

  /// Toggle strikethrough at current selection.
  void toggleStrikethrough() => _toggleAttribute(Attribute.strikeThrough);

  /// Toggle subscript at current selection.
  void toggleSubscript() => _toggleScriptAttribute(Attribute.subscript);

  /// Toggle superscript at current selection.
  void toggleSuperscript() => _toggleScriptAttribute(Attribute.superscript);

  /// Toggle inline code at current selection.
  void toggleInlineCode() => _toggleAttribute(Attribute.inlineCode);

  /// Apply or clear heading level. [level] 1–3 for H1–H3, or null for paragraph.
  void applyHeader(int? level) {
    if (level == null) {
      _quillController.formatSelection(Attribute.header);
    } else if (level == 1) {
      _toggleBlockAttribute(Attribute.h1);
    } else if (level == 2) {
      _toggleBlockAttribute(Attribute.h2);
    } else if (level == 3) {
      _toggleBlockAttribute(Attribute.h3);
    }
  }

  /// Toggle blockquote at current line(s).
  void toggleBlockQuote() => _toggleBlockAttribute(Attribute.blockQuote);

  /// Toggle code block at current line(s).
  void toggleCodeBlock() => _toggleBlockAttribute(Attribute.codeBlock);

  /// Insert a horizontal rule (divider) on a new line at the end of the current block.
  /// The rule is always placed after the current paragraph with consistent weight.
  void insertHorizontalRule() {
    const dividerType = 'divider';
    final offset = _endOfCurrentBlock(_quillController.selection.start);
    _quillController.replaceText(offset, 0, '\n', null);
    _quillController.replaceText(
      offset + 1,
      0,
      BlockEmbed(dividerType, 'hr'),
      TextSelection.collapsed(offset: offset + 2),
    );
  }

  /// Insert a table with [columnCount] columns and [rowCount] rows (including header)
  /// on a new line at the end of the current block.
  /// [rowCount] and [columnCount] must be at least 1.
  void insertTableWithSize(int columnCount, int rowCount) {
    final cols = columnCount.clamp(1, 20);
    final rows = rowCount.clamp(1, 30);
    final tableMarkdown = _buildTableMarkdown(cols, rows);
    final offset = _endOfCurrentBlock(_quillController.selection.start);
    _quillController.replaceText(offset, 0, '\n', null);
    _quillController.replaceText(
      offset + 1,
      0,
      EmbeddableTable(tableMarkdown),
      TextSelection.collapsed(offset: offset + 2),
    );
    // Ensure a newline after the table so the embed is alone on its line.
    _quillController.replaceText(offset + 2, 0, '\n', null);
    final docLength = _quillController.document.length;
    final sel = (offset + 3).clamp(0, docLength);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: sel),
      ChangeSource.local,
    );
  }

  int _endOfCurrentBlock(int fromOffset) {
    final plain = _quillController.document.toPlainText();
    final nextNewline = plain.indexOf('\n', fromOffset);
    if (nextNewline == -1) return _quillController.document.length;
    return nextNewline;
  }

  static String _buildTableMarkdown(int cols, int rows) {
    final sb = StringBuffer();
    final headerCells = List.filled(cols, ' ');
    sb.writeln('|${headerCells.join('|')}|');
    sb.writeln('|${List.filled(cols, '---').join('|')}|');
    for (var r = 0; r < rows - 1; r++) {
      sb.writeln('|${List.filled(cols, ' ').join('|')}|');
    }
    return sb.toString();
  }

  /// Insert a 2×2 table at the end of the current block (convenience method).
  void insertTable() {
    insertTableWithSize(2, 2);
  }

  /// Replaces the table embed at [offset] with a new table whose markdown is [newMarkdown].
  /// Used when the user edits cell content in the table. [offset] should be the document
  /// offset of the embed (e.g. from selection when the table is focused).
  void replaceTableEmbedAt(int offset, String newMarkdown) {
    _quillController.replaceText(offset, 1, EmbeddableTable(newMarkdown), null);
  }

  /// Toggle bullet list. If current block is already bullet list, clears to paragraph.
  /// Only the list attribute is changed; existing line style (formatting, etc.) is preserved.
  void toggleBulletList() => _toggleBlockAttribute(Attribute.ul);

  /// Toggle ordered list. If current block is already ordered list, clears to paragraph.
  /// Only the list attribute is changed; existing line style is preserved.
  void toggleOrderedList() => _toggleBlockAttribute(Attribute.ol);

  /// Toggle checklist (todo list) at current line(s). New checklist items are unchecked by default.
  void toggleChecklist() {
    final style = _quillController.getSelectionStyle();
    final current = style.attributes[Attribute.list.key];
    final isChecklist = current != null &&
        (current.value == Attribute.checked.value ||
            current.value == Attribute.unchecked.value);
    if (isChecklist) {
      _quillController.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      _quillController.formatSelection(Attribute.unchecked);
    }
  }

  /// Apply block alignment.
  void applyAlignment(TextAlign align) {
    final attr = align == TextAlign.center
        ? Attribute.centerAlignment
        : align == TextAlign.right
            ? Attribute.rightAlignment
            : align == TextAlign.justify
                ? Attribute.justifyAlignment
                : Attribute.leftAlignment;
    _quillController.formatSelection(attr);
  }

  /// Apply font size: 'small', 'normal', 'large', or 'huge'.
  void applySize(String size) {
    if (size == 'normal') {
      _quillController.formatSelection(Attribute.clone(Attribute.size, null));
    } else if (size == 'small' || size == 'large' || size == 'huge') {
      _quillController.formatSelection(Attribute.clone(Attribute.size, size));
    }
  }

  /// Apply link to current selection. [url] must not be null or empty.
  void applyLink(String url) {
    if (url.trim().isEmpty) return;
    _quillController.formatSelection(Attribute.clone(Attribute.link, url.trim()));
  }

  /// Clear all formatting on the current selection.
  void clearFormatting() {
    final style = _quillController.getSelectionStyle();
    for (final attr in style.attributes.values) {
      _quillController.formatSelection(Attribute.clone(attr, null));
    }
  }

  /// Inserts a line break at the current selection and moves the cursor after it.
  ///
  /// Use for consistent Enter behavior:
  /// - At end of paragraph (cursor at [document.length] or end of block): creates
  ///   a new line below and moves the cursor there.
  /// - In the middle of a line: splits the line at the cursor; text after the
  ///   cursor moves to the new line and the cursor is placed at the start of
  ///   that new line.
  void insertLineBreak() {
    final sel = _quillController.selection;
    final offset = sel.baseOffset;
    final newOffset = offset + 1;
    _quillController.replaceText(
      offset,
      0,
      '\n',
      TextSelection.collapsed(offset: newOffset),
    );
    // Explicitly apply cursor so it stays correct (avoids cursor jumping after insert).
    _quillController.updateSelection(
      TextSelection.collapsed(offset: newOffset),
      ChangeSource.local,
    );
  }

  /// Increase indent of current block(s). Does nothing if already at max level.
  void increaseIndent() {
    final style = _quillController.getSelectionStyle();
    final current = style.attributes[Attribute.indent.key];
    int level = 0;
    if (current != null && current.value is int) {
      level = current.value as int;
    }
    if (level >= 3) return;
    _quillController.formatSelection(Attribute.getIndentLevel(level + 1));
  }

  /// Decrease indent of current block(s). Does nothing if already at 0.
  void decreaseIndent() {
    final style = _quillController.getSelectionStyle();
    final current = style.attributes[Attribute.indent.key];
    int level = 0;
    if (current != null && current.value is int) {
      level = current.value as int;
    }
    if (level <= 0) return;
    if (level == 1) {
      _quillController.formatSelection(Attribute.clone(Attribute.indent, null));
    } else {
      _quillController.formatSelection(Attribute.getIndentLevel(level - 1));
    }
  }

  void _toggleAttribute(Attribute attribute) {
    final style = _quillController.getSelectionStyle();
    final isActive = style.attributes.containsKey(attribute.key);
    _quillController.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleBlockAttribute(Attribute attribute) {
    final style = _quillController.getSelectionStyle();
    final current = style.attributes[attribute.key];
    final isActive = current != null &&
        (attribute.value == null || current.value == attribute.value);
    _quillController.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleScriptAttribute(Attribute scriptAttr) {
    final style = _quillController.getSelectionStyle();
    final current = style.attributes[Attribute.script.key];
    final isActive = current != null && current.value == scriptAttr.value;
    _quillController.formatSelection(
      isActive ? Attribute.clone(Attribute.script, null) : scriptAttr,
    );
  }

  void _onQuillChanged() {
    if (_onMarkdownChanged == null) return;
    _markdownDebounce?.cancel();
    _markdownDebounce = Timer(debounceMarkdownDuration, () {
      final current = markdown;
      if (current != _lastEmittedMarkdown) {
        _lastEmittedMarkdown = current;
        // ignore: unnecessary_non_null_assertion - timer can fire after dispose
        _onMarkdownChanged!(current);
      }
    });
  }

  static final DeltaToMarkdown _deltaToMarkdown = DeltaToMarkdown(
    customTextAttrsHandlers: {
      Attribute.underline.key: CustomAttributeHandler(
        beforeContent: (attr, node, out) => out.write('__'),
        afterContent: (attr, node, out) => out.write('__'),
      ),
    },
    customEmbedHandlers: {
      EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
    },
  );

  /// Markdown document that parses table syntax into [EmbeddableTable] elements
  /// so [MarkdownToDelta] can produce table embeds when loading/pasting.
  static final md.Document _markdownDocument = md.Document(
        blockSyntaxes: [
          const EmbeddableTableSyntax(),
        ],
      );

  static final MarkdownToDelta _markdownToDelta = MarkdownToDelta(
        markdownDocument: _markdownDocument,
        customElementToEmbeddable: {
          EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
        },
      );

  static QuillController _createController(String initialMarkdown) {
    Delta delta;
    if (initialMarkdown.trim().isEmpty) {
      delta = Delta()..insert('\n');
    } else {
      delta = _markdownToDelta.convert(initialMarkdown);
      if (delta.isEmpty) delta = Delta()..insert('\n');
    }
    final document = Document.fromDelta(delta);
    final endOffset = document.length;
    return QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: endOffset),
    );
  }

  @override
  void dispose() {
    _markdownDebounce?.cancel();
    _quillController.removeListener(_onQuillChanged);
    _quillController.dispose();
    super.dispose();
  }
}
