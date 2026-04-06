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
    this.bottomBar,
    this.isEditorInteractive = true,
    this.outlineTitleTextStyle,
    this.outlineEmptyTextStyle,
    this.outlineEntryTextStyle,
    this.blockComponentBuilders,
    this.bodyBuilder,
    this.bodyFooter,
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

  /// Optional override for the scaffold bottom bar (defaults to [FormatToolbar]).
  final Widget? bottomBar;

  /// When false, disables user interactions with the editor (caret/selection).
  ///
  /// Useful for modes like drawing where the editor should not steal gestures.
  final bool isEditorInteractive;

  final TextStyle? outlineTitleTextStyle;
  final TextStyle? outlineEmptyTextStyle;
  final TextStyle? outlineEntryTextStyle;

  final Map<String, BlockComponentBuilder>? blockComponentBuilders;

  /// Optional override for the entire scaffold body.
  ///
  /// The callback receives the default editor widget so note screens can wrap the
  /// editor (e.g. overlay a drawing layer, or mount a viewport) without
  /// re-implementing editor style/builder wiring.
  final Widget Function(BuildContext context, Widget editor)? bodyBuilder;

  /// Optional panel below the editor (e.g. drawing). Kept above the format toolbar.
  final Widget? bodyFooter;

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

  /// [AppFlowyEditor] default styles come from [EditorStyle.desktop]/[.mobile]
  /// (black text). Map cursor, selection, and base text from [Theme] so light /
  /// dark mode matches the host app.
  EditorStyle _editorStyleForTheme(BuildContext context, {required bool desktop}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectionTheme = theme.textSelectionTheme;
    final base = desktop ? EditorStyle.desktop() : EditorStyle.mobile();
    final body = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final baseTextStyle = base.textStyleConfiguration.text.merge(
      body.copyWith(
        color: body.color ?? scheme.onSurface,
        fontSize: body.fontSize ?? 16,
      ),
    );
    final cursor = selectionTheme.cursorColor ??
        selectionTheme.selectionHandleColor ??
        scheme.primary;
    final selectionColor =
        selectionTheme.selectionColor ??
        scheme.primary.withValues(alpha: 0.35);
    return base.copyWith(
      cursorColor: cursor,
      dragHandleColor: cursor,
      selectionColor: selectionColor,
      textStyleConfiguration: base.textStyleConfiguration.copyWith(
        text: baseTextStyle,
        href: base.textStyleConfiguration.href.copyWith(
          color: scheme.primary,
        ),
        code: base.textStyleConfiguration.code.copyWith(
          color: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        ),
        autoComplete: base.textStyleConfiguration.autoComplete.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      textSpanDecorator: sloteTextSpanDecoratorForAttribute,
      caretMetrics: sloteCaretMetrics,
      endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
      endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.controller.editorState;
    final wideChrome =
        MediaQuery.sizeOf(context).width >= widget.editorStyleBreakpoint;
    final editorStyle = _editorStyleForTheme(context, desktop: wideChrome);

    final wideOutline =
        MediaQuery.sizeOf(context).width >= widget.outlineWideBreakpoint;
    final builders =
        widget.blockComponentBuilders ?? sloteRichTextBlockComponentBuilders;

    final editor = AppFlowyEditor(
      editorState: es,
      editorStyle: editorStyle,
      blockComponentBuilders: builders,
      commandShortcutEvents: standardCommandShortcutsWithSloteInlineHandlers(),
    );

    final interactiveEditor = widget.isEditorInteractive
        ? editor
        : AbsorbPointer(
            absorbing: true,
            child: editor,
          );

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
        child: _buildBody(
          context,
          interactiveEditor,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: widget.bottomBar ??
            FormatToolbar(
              editorState: es,
              listenable: _formatBarListenable,
              layout: widget.toolbarLayout,
              onInsertImageUrl: widget.onInsertImageUrl,
            ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Widget editor) {
    final builder = widget.bodyBuilder;
    if (builder != null) return builder(context, editor);

    final footer = widget.bodyFooter;
    if (footer == null) return editor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: editor),
        footer,
      ],
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
