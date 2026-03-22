import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'editor/rich_text_editor_screen.dart';

/// Root widget: theme, localization, and home screen.
///
/// Matches the getting-started direction from the
/// [AppFlowy Editor README](https://github.com/AppFlowy-IO/appflowy-editor).
class RichTextEditorApp extends StatelessWidget {
  const RichTextEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rich text',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [AppFlowyEditorLocalizations.delegate],
      home: const RichTextEditorScreen(),
    );
  }
}
