import 'package:flutter/material.dart';

/// Rich text editor widget for Word-style formatting
class RichTextEditor extends StatefulWidget {
  final String? initialText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const RichTextEditor({
    super.key,
    this.initialText,
    this.onChanged,
    this.controller,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TextEditingController(text: widget.initialText ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Start typing...',
      ),
    );
  }
}

