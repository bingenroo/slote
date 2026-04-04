import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

import 'document_json_log.dart';
import 'format_toolbar.dart';

/// Editor page: [RichTextEditorController], [AppFlowyEditor], [FormatToolbar],
/// outline/TOC (debounced via [RichTextEditorController.onDebouncedDocumentChanged]),
/// and debounced document JSON appended to a log (see [appendRichTextDocumentJsonLog]).
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

  late final RichTextEditorController _controller;
  late final Listenable _formatBarListenable;

  List<SloteOutlineEntry> _outline = const [];

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
      onDebouncedDocumentChanged: _refreshOutline,
    );
    _formatBarListenable = Listenable.merge([
      _controller.editorState.selectionNotifier,
      _controller.editorState.toggledStyleNotifier,
      _controller.undoRedoListenable,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshOutline();
    });
  }

  void _refreshOutline() {
    if (!mounted) return;
    final next = sloteCollectOutlineEntries(_controller.editorState.document);
    setState(() => _outline = next);
  }

  Future<void> _jumpToOutlineEntry(SloteOutlineEntry entry) async {
    final es = _controller.editorState;
    es.scrollService?.jumpTo(entry.path.first);
    await es.updateSelectionWithReason(
      Selection.collapsed(Position(path: entry.path, offset: 0)),
      reason: SelectionUpdateReason.uiEvent,
      extraInfo: const {'selectionExtraInfoDisableToolbar': true},
    );
  }

  void _showOutline() {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= _kOutlineWideBreakpoint) {
      _scaffoldKey.currentState?.openEndDrawer();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        // One bounded height for the whole sheet body so title + list never
        // exceed the modal (avoids Column overflow under the drag handle).
        final screenH = MediaQuery.sizeOf(sheetContext).height;
        final sheetBodyHeight = math.min(420.0, screenH * 0.5);
        return Padding(
          padding: EdgeInsets.only(
            bottom: math.max(
              8.0,
              MediaQuery.viewPaddingOf(sheetContext).bottom,
            ),
          ),
          child: SizedBox(
            height: sheetBodyHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Outline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _ExampleOutlineListBody(
                    entries: _outline,
                    onEntryTap: (e) {
                      Navigator.pop(sheetContext);
                      unawaited(_jumpToOutlineEntry(e));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        MediaQuery.sizeOf(context).width >= _kOutlineWideBreakpoint;
    final editorStyle =
        (useDesktopChrome ? EditorStyle.desktop() : EditorStyle.mobile())
            .copyWith(
      textSpanDecorator: sloteTextSpanDecoratorForAttribute,
      caretMetrics: sloteCaretMetrics,
      endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
      endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
    );
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: useDesktopChrome
          ? Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Outline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ExampleOutlineListBody(
                        entries: _outline,
                        onEntryTap: (e) {
                          Navigator.pop(context);
                          unawaited(_jumpToOutlineEntry(e));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: const Text('Rich text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: 'Outline',
            onPressed: _showOutline,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AppFlowyEditor(
              editorState: es,
              editorStyle: editorStyle,
              blockComponentBuilders: sloteRichTextBlockComponentBuilders,
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

class _ExampleOutlineListBody extends StatelessWidget {
  const _ExampleOutlineListBody({
    required this.entries,
    required this.onEntryTap,
  });

  final List<SloteOutlineEntry> entries;
  final ValueChanged<SloteOutlineEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No headings yet',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return ListTile(
          contentPadding: EdgeInsets.only(
            left: 16 + (e.level - 1) * 16,
            right: 16,
          ),
          title: Text(e.title, style: const TextStyle(fontSize: 15)),
          onTap: () => onEntryTap(e),
        );
      },
    );
  }
}
