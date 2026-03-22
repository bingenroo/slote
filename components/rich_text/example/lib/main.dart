import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Minimal demo matching the getting-started snippet from the
/// [AppFlowy Editor README](https://github.com/AppFlowy-IO/appflowy-editor).
void main() => runApp(const AppFlowyEditorExampleApp());

class AppFlowyEditorExampleApp extends StatelessWidget {
  const AppFlowyEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppFlowy Editor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [AppFlowyEditorLocalizations.delegate],
      home: const _EditorScreen(),
    );
  }
}

class _EditorScreen extends StatefulWidget {
  const _EditorScreen();

  @override
  State<_EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<_EditorScreen> {
  static const document = r'''{
  "document": {
    "type": "page",
    "children": [
      {
        "type": "heading",
        "data": {
            "delta": [{ "insert": "Hello AppFlowy!" }],
            "level": 1
        }
      }
    ]
  }
}''';
  final json = Map<String, Object>.from(jsonDecode(document));

  late final EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState(document: Document.fromJson(json));
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppFlowy Editor Example')),
      body: AppFlowyEditor(editorState: _editorState),
    );
  }
}
