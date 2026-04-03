import 'dart:async';
import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

import 'document_json_log.dart';
import 'format_toolbar.dart';

/// Editor page: [RichTextEditorController], [AppFlowyEditor], [FormatToolbar],
/// and debounced document JSON appended to a log (see [appendRichTextDocumentJsonLog]).
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

  late final RichTextEditorController _controller;
  late final Listenable _formatBarListenable;
  @override
  void initState() {
    super.initState();
    final initial =
        jsonDecode(_seedDocumentJson) as Map<String, dynamic>;
    _controller = RichTextEditorController.fromJson(
      initial,
      onDocumentJsonChanged: (json) {
        unawaited(appendRichTextDocumentJsonLog(json));
      },
    );
    _formatBarListenable = Listenable.merge([
      _controller.editorState.selectionNotifier,
      _controller.editorState.toggledStyleNotifier,
      _controller.undoRedoListenable,
    ]);

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final es = _controller.editorState;
    final useDesktopChrome =
        MediaQuery.sizeOf(context).width >= 600;
    final editorStyle =
        (useDesktopChrome ? EditorStyle.desktop() : EditorStyle.mobile())
            .copyWith(
      textSpanDecorator: sloteTextSpanDecoratorForAttribute,
      caretMetrics: sloteCaretMetrics,
      endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
      endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich text'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AppFlowyEditor(
              editorState: es,
              editorStyle: editorStyle,
              commandShortcutEvents:
                  standardCommandShortcutsWithSloteInlineHandlers(),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: FormatToolbar(
              editorState: es,
              listenable: _formatBarListenable,
              layout: SloteToolbarLayout.verticalScroll,
            ),
          ),
        ],
      ),
    );
  }
}
