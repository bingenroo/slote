import 'package:flutter/material.dart';
import 'package:slote_rich_text/slote_rich_text.dart';

class TestRichTextScreen extends StatefulWidget {
  const TestRichTextScreen({super.key});

  @override
  State<TestRichTextScreen> createState() => _TestRichTextScreenState();
}

class _TestRichTextScreenState extends State<TestRichTextScreen> {
  late TextEditingController _textController;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'Start typing here to test rich text formatting...\n\n'
          'Select text and use the toolbar to apply formatting.',
    );
    _textController.addListener(_updateFormatting);
  }

  @override
  void dispose() {
    _textController.removeListener(_updateFormatting);
    _textController.dispose();
    super.dispose();
  }

  void _updateFormatting() {
    // In a real implementation, this would check the current selection's formatting
    // For now, we'll just update based on toolbar state
    setState(() {});
  }

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
    // In a real implementation, this would apply formatting to selected text
    _applyFormatting();
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
    _applyFormatting();
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
    _applyFormatting();
  }

  void _applyFormatting() {
    // In a real implementation, this would apply formatting to the selected text
    // For now, we'll just show the state change
    final selection = _textController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      // Formatting would be applied here
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slote Rich Text Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _textController.clear();
            },
            tooltip: 'Clear Text',
          ),
        ],
      ),
      body: Column(
        children: [
          // Format toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: FormatToolbar(
              onBold: _toggleBold,
              onItalic: _toggleItalic,
              onUnderline: _toggleUnderline,
              isBold: _isBold,
              isItalic: _isItalic,
              isUnderline: _isUnderline,
            ),
          ),
          // Text editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: RichTextEditor(
                controller: _textController,
                onChanged: (text) {
                  // Handle text changes
                },
              ),
            ),
          ),
          // Info bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Characters: ${_textController.text.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Words: ${_textController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Selection: ${_textController.selection.isCollapsed ? "None" : "${_textController.selection.start}-${_textController.selection.end}"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
