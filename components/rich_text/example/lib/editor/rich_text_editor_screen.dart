import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

import 'document_json_log.dart';

/// Editor page using [SloteRichTextEditorScaffold]: same shell as the main app
/// (outline, [FormatToolbar], [AppFlowyEditor] defaults), plus JSON logging.
class RichTextEditorScreen extends StatefulWidget {
  const RichTextEditorScreen({super.key});

  @override
  State<RichTextEditorScreen> createState() => _RichTextEditorScreenState();
}

class _RichTextEditorScreenState extends State<RichTextEditorScreen> {
  static const double _kOutlineWideBreakpoint = 600;

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<SloteRichTextEditorScaffoldState> _editorShellKey =
      GlobalKey<SloteRichTextEditorScaffoldState>();

  late final RichTextEditorController _controller;

  List<SloteOutlineEntry> _outline = const [];

  @override
  void initState() {
    super.initState();
    final initial = jsonDecode(_seedDocumentJson) as Map<String, dynamic>;
    _controller = RichTextEditorController.fromJson(
      initial,
      onDocumentJsonChanged: (json) {
        unawaited(appendRichTextDocumentJsonLog(json));
      },
      onDebouncedDocumentChanged: _refreshOutline,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshOutline();
    });
  }

  void _refreshOutline() {
    if (!mounted) return;
    final next = sloteCollectOutlineEntries(_controller.editorState.document);
    setState(() => _outline = next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SloteRichTextEditorScaffold(
      key: _editorShellKey,
      scaffoldKey: _scaffoldKey,
      controller: _controller,
      outline: _outline,
      outlineWideBreakpoint: _kOutlineWideBreakpoint,
      editorStyleBreakpoint: _kOutlineWideBreakpoint,
      toolbarLayout: SloteToolbarLayout.verticalScroll,
      appBar: AppBar(
        title: const Text('Rich text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: 'Outline',
            onPressed: () => _editorShellKey.currentState?.showOutline(),
          ),
        ],
      ),
    );
  }
}
