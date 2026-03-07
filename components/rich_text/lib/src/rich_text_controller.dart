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
    this.headerLevel,
    this.isBlockQuote = false,
    this.isCodeBlock = false,
    this.listType,
  });

  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isInlineCode;
  /// 1, 2, or 3 for H1/H2/H3; null for paragraph.
  final int? headerLevel;
  final bool isBlockQuote;
  final bool isCodeBlock;
  /// 'bullet' or 'ordered' for list; null for normal block.
  final String? listType;

  SelectionStyleState copyWith({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    bool? isInlineCode,
    int? headerLevel,
    bool? isBlockQuote,
    bool? isCodeBlock,
    String? listType,
  }) {
    return SelectionStyleState(
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      isInlineCode: isInlineCode ?? this.isInlineCode,
      headerLevel: headerLevel ?? this.headerLevel,
      isBlockQuote: isBlockQuote ?? this.isBlockQuote,
      isCodeBlock: isCodeBlock ?? this.isCodeBlock,
      listType: listType ?? this.listType,
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
      if (v == 'bullet' || v == 'ordered') listType = v;
    }
    return SelectionStyleState(
      isBold: attrs.containsKey(Attribute.bold.key),
      isItalic: attrs.containsKey(Attribute.italic.key),
      isUnderline: attrs.containsKey(Attribute.underline.key),
      isStrikethrough: attrs.containsKey(Attribute.strikeThrough.key),
      isInlineCode: attrs.containsKey(Attribute.inlineCode.key),
      headerLevel: headerLevel,
      isBlockQuote: attrs.containsKey(Attribute.blockQuote.key),
      isCodeBlock: attrs.containsKey(Attribute.codeBlock.key),
      listType: listType,
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

  /// Toggle bullet list. If current block is already bullet list, clears to paragraph.
  void toggleBulletList() => _toggleBlockAttribute(Attribute.ul);

  /// Toggle ordered list. If current block is already ordered list, clears to paragraph.
  void toggleOrderedList() => _toggleBlockAttribute(Attribute.ol);

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
  );

  static final MarkdownToDelta _markdownToDelta = MarkdownToDelta(
    markdownDocument: md.Document(),
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
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
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
