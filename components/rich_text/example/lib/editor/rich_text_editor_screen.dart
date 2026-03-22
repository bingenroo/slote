import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'format_toolbar.dart';

/// Editor page: [EditorState] lifecycle, [AppFlowyEditor], and [FormatToolbar].
class RichTextEditorScreen extends StatefulWidget {
  const RichTextEditorScreen({super.key});

  @override
  State<RichTextEditorScreen> createState() => _RichTextEditorScreenState();
}

class _RichTextEditorScreenState extends State<RichTextEditorScreen> {
  static const _seedDocumentJson = r'''{
  "document": {
    "type": "page",
    "children": [
      {
        "type": "heading",
        "data": {
            "delta": [{ "insert": "Hello AppFlowy!!" }],
            "level": 1
        }
      }
    ]
  }
}''';

  final Map<String, Object> _initialDocument =
      Map<String, Object>.from(jsonDecode(_seedDocumentJson));

  late final EditorState _editorState;
  late final Listenable _formatBarListenable;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState(document: Document.fromJson(_initialDocument));
    _formatBarListenable = Listenable.merge([
      _editorState.selectionNotifier,
      _editorState.toggledStyleNotifier,
    ]);
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rich text')),
      body: Column(
        children: [
          Expanded(
            child: AppFlowyEditor(
              editorState: _editorState,
              editorStyle: const EditorStyle.mobile(),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: FormatToolbar(
              editorState: _editorState,
              listenable: _formatBarListenable,
            ),
          ),
        ],
      ),
    );
  }
}
