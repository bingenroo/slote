import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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
      localizationsDelegates: const [
        AppFlowyEditorLocalizations.delegate,
      ],
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
  late final EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState.blank(withInitialText: true);
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
