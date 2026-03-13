import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'rich_text_controller.dart';

/// WYSIWYG rich text editor (no visible markdown markers).
///
/// Uses [RichTextController] for document and formatting. Collapsed cursor +
/// format button toggles style for subsequent typing (option A). Selection +
/// format button toggles style on the range (no stacking).
class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.scrollController,
    this.config = const QuillEditorConfig(),
    this.editorFocusRequester,
  });

  /// Rich text controller (markdown export, toolbar state, format toggles).
  final RichTextController controller;

  /// Optional focus node. One is created internally if null.
  final FocusNode? focusNode;

  /// Optional scroll controller for the editor scroll view.
  final ScrollController? scrollController;

  /// Editor configuration (e.g. placeholder, padding).
  final QuillEditorConfig config;

  /// When set, code blocks (and other embeds) can request focus back to this editor (e.g. arrow-key exit).
  final EditorFocusRequester? editorFocusRequester;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  bool _ownsFocusNode = false;
  bool _ownsScrollController = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
    widget.editorFocusRequester?.setRequestFocus(() {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
    // Re-sync selection after first layout so tap/click position and cursor stay aligned.
    // Without this, the first few interactions can use wrong offsets (cursor jumps / wrong line breaks).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final qc = widget.controller.quillController;
      final sel = qc.selection;
      if (sel.isValid) {
        qc.updateSelection(sel, ChangeSource.local);
      }
    });
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorFocusRequester != widget.editorFocusRequester) {
      widget.editorFocusRequester?.setRequestFocus(() {
        if (mounted) FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: widget.controller.quillController,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: widget.config,
    );
  }
}
