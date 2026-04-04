import 'dart:async';
import 'dart:math' as math;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../appflowy/appflowy_document_controller.dart';
import '../appflowy/appflowy_editor_support.dart';
import '../appflowy/slote_block_component_builders.dart';
import '../appflowy/slote_caret_metrics.dart';
import '../appflowy/slote_end_of_paragraph_caret_height.dart';
import '../appflowy/slote_outline.dart';
import '../appflowy/slote_text_span_decorator.dart';
import 'slote_default_format_toolbar.dart';
import 'slote_toolbar_layout.dart';

/// Scaffold shell for the Slote AppFlowy editor: [EditorStyle] defaults,
/// [AppFlowyEditor], outline drawer / sheet, and [FormatToolbar].
///
/// Call [SloteRichTextEditorScaffoldState.showOutline] from a
/// [GlobalKey<SloteRichTextEditorScaffoldState>] to mirror the built-in outline
/// button behavior (wide: open end drawer; narrow: bottom sheet).
class SloteRichTextEditorScaffold extends StatefulWidget {
  const SloteRichTextEditorScaffold({
    super.key,
    required this.controller,
    required this.outline,
    required this.appBar,
    this.scaffoldKey,
    this.outlineWideBreakpoint = 600,
    this.editorStyleBreakpoint = 600,
    this.toolbarLayout = SloteToolbarLayout.verticalScroll,
    this.onInsertImageUrl,
    this.outlineTitleTextStyle,
    this.outlineEmptyTextStyle,
    this.outlineEntryTextStyle,
    this.blockComponentBuilders,
  });

  final RichTextEditorController controller;
  final List<SloteOutlineEntry> outline;
  final PreferredSizeWidget appBar;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Viewport width at or above which outline lives in the end drawer.
  final double outlineWideBreakpoint;

  /// Viewport width at or above which [EditorStyle.desktop] is used.
  final double editorStyleBreakpoint;
  final SloteToolbarLayout toolbarLayout;

  final Future<String?> Function(BuildContext context)? onInsertImageUrl;

  final TextStyle? outlineTitleTextStyle;
  final TextStyle? outlineEmptyTextStyle;
  final TextStyle? outlineEntryTextStyle;

  final Map<String, BlockComponentBuilder>? blockComponentBuilders;

  @override
  State<SloteRichTextEditorScaffold> createState() =>
      SloteRichTextEditorScaffoldState();
}

class SloteRichTextEditorScaffoldState extends State<SloteRichTextEditorScaffold> {
  late final Listenable _formatBarListenable;

  @override
  void initState() {
    super.initState();
    _formatBarListenable = Listenable.merge([
      widget.controller.editorState.selectionNotifier,
      widget.controller.editorState.toggledStyleNotifier,
      widget.controller.undoRedoListenable,
    ]);
  }

  /// Opens the outline drawer (wide) or bottom sheet (narrow).
  void showOutline() {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= widget.outlineWideBreakpoint) {
      widget.scaffoldKey?.currentState?.openEndDrawer();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Outline',
                    style:
                        widget.outlineTitleTextStyle ??
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: _SloteOutlineListBody(
                    entries: widget.outline,
                    emptyTextStyle: widget.outlineEmptyTextStyle,
                    entryTextStyle: widget.outlineEntryTextStyle,
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

  Future<void> _jumpToOutlineEntry(SloteOutlineEntry entry) async {
    final es = widget.controller.editorState;
    es.scrollService?.jumpTo(entry.path.first);
    await es.updateSelectionWithReason(
      Selection.collapsed(Position(path: entry.path, offset: 0)),
      reason: SelectionUpdateReason.uiEvent,
      extraInfo: const {'selectionExtraInfoDisableToolbar': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.controller.editorState;
    final wideChrome =
        MediaQuery.sizeOf(context).width >= widget.editorStyleBreakpoint;
    final editorStyle =
        (wideChrome ? EditorStyle.desktop() : EditorStyle.mobile()).copyWith(
          textSpanDecorator: sloteTextSpanDecoratorForAttribute,
          caretMetrics: sloteCaretMetrics,
          endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
          endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
        );

    final wideOutline =
        MediaQuery.sizeOf(context).width >= widget.outlineWideBreakpoint;
    final builders =
        widget.blockComponentBuilders ?? sloteRichTextBlockComponentBuilders;

    return Scaffold(
      key: widget.scaffoldKey,
      endDrawer: wideOutline
          ? Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Outline',
                        style:
                            widget.outlineTitleTextStyle ??
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Expanded(
                      child: _SloteOutlineListBody(
                        entries: widget.outline,
                        emptyTextStyle: widget.outlineEmptyTextStyle,
                        entryTextStyle: widget.outlineEntryTextStyle,
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
      appBar: widget.appBar,
      body: SafeArea(
        child: AppFlowyEditor(
          editorState: es,
          editorStyle: editorStyle,
          blockComponentBuilders: builders,
          commandShortcutEvents:
              standardCommandShortcutsWithSloteInlineHandlers(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FormatToolbar(
          editorState: es,
          listenable: _formatBarListenable,
          layout: widget.toolbarLayout,
          onInsertImageUrl: widget.onInsertImageUrl,
        ),
      ),
    );
  }
}

class _SloteOutlineListBody extends StatelessWidget {
  const _SloteOutlineListBody({
    required this.entries,
    required this.onEntryTap,
    this.emptyTextStyle,
    this.entryTextStyle,
  });

  final List<SloteOutlineEntry> entries;
  final ValueChanged<SloteOutlineEntry> onEntryTap;
  final TextStyle? emptyTextStyle;
  final TextStyle? entryTextStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No headings yet',
            style:
                emptyTextStyle ??
                theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
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
          title: Text(
            e.title,
            style:
                entryTextStyle ??
                theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
          ),
          onTap: () => onEntryTap(e),
        );
      },
    );
  }
}
