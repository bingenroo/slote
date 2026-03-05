import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  runApp(const RichTextExampleApp());
}

class RichTextExampleApp extends StatelessWidget {
  const RichTextExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rich Text Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _RichTextExampleScreen(),
    );
  }
}

class _RichTextExampleScreen extends StatefulWidget {
  const _RichTextExampleScreen();

  @override
  State<_RichTextExampleScreen> createState() => _RichTextExampleScreenState();
}

class _RichTextExampleScreenState extends State<_RichTextExampleScreen> {
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
    setState(() {});
  }

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
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
    final selection = _textController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text Example'),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: RichTextEditor(
                controller: _textController,
                onChanged: (text) {},
              ),
            ),
          ),
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
