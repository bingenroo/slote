import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rich_text/rich_text.dart';
import 'package:shared/shared.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/services/slote_rich_text_storage.dart';
import 'package:theme/theme.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final LocalDBService _localDb = LocalDBService();

  Note? _currentNote;

  late final RichTextEditorController _richTextController;
  late final Listenable _formatBarListenable;

  List<SloteOutlineEntry> _outline = const [];

  // Cached state used by the persistence layer (so back navigation can flush).
  String _latestBodyJsonString = sloteEmptyDocumentJsonString();
  Timer? _titleSaveDebounceTimer;

  bool _suppressSaves = false;
  bool _saveAgain = false;
  Future<void>? _activeSaveLoop;

  static const Duration _kTitleSaveDebounce = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';

    _currentNote = widget.note;
    _latestBodyJsonString = widget.note == null
        ? sloteEmptyDocumentJsonString()
        : normalizeNoteBodyToDocumentJsonString(widget.note!.body);

    final initialJson = widget.note != null
        ? parseAppFlowyDocumentJsonOrEmpty(widget.note!.body)
        : Map<String, dynamic>.from(kSloteEmptyDocumentJson);

    _richTextController = RichTextEditorController.fromJson(
      initialJson,
      onDocumentJsonChanged: (json) {
        // `onDocumentJsonChanged` is already debounced by the controller.
        _latestBodyJsonString =
            normalizeNoteBodyToDocumentJsonString(jsonEncode(json));
        _requestSave();
      },
      onDebouncedDocumentChanged: _refreshOutline,
    );

    _titleController.addListener(_onTitleChanged);

    _formatBarListenable = Listenable.merge([
      _richTextController.editorState.selectionNotifier,
      _richTextController.editorState.toggledStyleNotifier,
      _richTextController.undoRedoListenable,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshOutline();
    });
  }

  void _refreshOutline() {
    if (!mounted) return;
    final next = sloteCollectOutlineEntries(
      _richTextController.editorState.document,
    );
    setState(() => _outline = next);
  }

  static const double _kOutlineWideBreakpoint = 600;

  Future<void> _jumpToOutlineEntry(SloteOutlineEntry entry) async {
    final es = _richTextController.editorState;
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
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _OutlineListBody(
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
    _suppressSaves = true;
    _titleSaveDebounceTimer?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _richTextController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    unawaited(_handleBackNavigationAsync());
  }

  Future<void> _handleBackNavigationAsync() async {
    await _flushLatestToDb();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onTitleChanged() {
    // Debounce title writes separately from rich-text writes.
    _titleSaveDebounceTimer?.cancel();
    _titleSaveDebounceTimer = Timer(_kTitleSaveDebounce, () {
      _requestSave();
    });
  }

  void _requestSave() {
    if (_suppressSaves || !mounted) return;
    _saveAgain = true;
    _activeSaveLoop ??= _saveLoop();
  }

  Future<void> _flushLatestToDb() async {
    if (_suppressSaves || !mounted) return;
    _saveAgain = true;
    _activeSaveLoop ??= _saveLoop();
    await _activeSaveLoop;
  }

  Future<void> _saveLoop() async {
    try {
      while (_saveAgain && !_suppressSaves) {
        _saveAgain = false;
        await _saveOnce();
      }
    } finally {
      _activeSaveLoop = null;
    }
  }

  Future<void> _saveOnce() async {
    if (_suppressSaves) return;

    final title = _titleController.text;
    final bodyJsonString = _latestBodyJsonString;

    final titleTrimmed = title.trim();
    final previewTrimmed =
        plainTextPreviewFromDocumentJsonString(bodyJsonString).trim();
    final hasMeaningfulContent =
        titleTrimmed.isNotEmpty || previewTrimmed.isNotEmpty;

    // For new notes, don't create a record until we have user content.
    if (_currentNote == null && !hasMeaningfulContent) return;

    final now = DateTime.now();

    if (_currentNote != null) {
      // Avoid unnecessary writes when nothing changed.
      if (_currentNote!.title == title &&
          _currentNote!.body == bodyJsonString) {
        return;
      }
      _currentNote = _currentNote!.copyWith(
        title: title,
        body: bodyJsonString,
        lastMod: now,
      );
    } else {
      _currentNote = Note(
        id: DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF,
        title: title,
        body: bodyJsonString,
        lastMod: now,
      );
    }

    await _localDb.saveNote(note: _currentNote!);
  }

  Future<void> _confirmDelete() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            widget.note == null ? 'Discard?' : 'Close note?',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(AnimationAssets.delete),
              Text(
                widget.note == null
                    ? 'Leave this screen? Nothing is saved yet.'
                    : 'Leave this screen? Changes are saved to the database.',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (widget.note == null && _currentNote != null) {
                  // Discard a newly-created draft by deleting it from DB.
                  _suppressSaves = true;
                  final activeSaveLoop = _activeSaveLoop;
                  if (activeSaveLoop != null) {
                    await activeSaveLoop;
                  }
                  await _localDb.deleteNote(id: _currentNote!.id);
                  _currentNote = null;
                }
                if (mounted) Navigator.pop(this.context);
              },
              child: const Text('Proceed'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorStyle = (MediaQuery.sizeOf(context).width >= 600
            ? EditorStyle.desktop()
            : EditorStyle.mobile())
        .copyWith(
          textSpanDecorator: sloteTextSpanDecoratorForAttribute,
          caretMetrics: sloteCaretMetrics,
          endOfParagraphCaretHeight: sloteEndOfParagraphCaretHeight,
          endOfParagraphCaretMetrics: sloteEndOfParagraphCaretMetrics,
        );
    final editorState = _richTextController.editorState;

    final wideOutline = MediaQuery.sizeOf(context).width >= _kOutlineWideBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
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
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _OutlineListBody(
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
        toolbarHeight: 52,
        leading: IconButton(
          onPressed: _handleBackNavigation,
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: TextField(
          controller: _titleController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'New Slote',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: AppThemeConfig.titleFontSize,
            color: Theme.of(context).colorScheme.onPrimary,
            decorationColor: Theme.of(context).colorScheme.onPrimary,
          ),
          cursorColor: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.listUl,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _showOutline,
            tooltip: 'Outline',
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.trash,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _confirmDelete,
            tooltip: 'Close',
          ),
        ],
      ),
      body: SafeArea(
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: editorStyle,
          blockComponentBuilders: sloteRichTextBlockComponentBuilders,
          commandShortcutEvents:
              standardCommandShortcutsWithSloteInlineHandlers(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomRichTextToolbar(
          editorState: editorState,
          listenable: _formatBarListenable,
          layout: SloteToolbarLayout.verticalScroll,
        ),
      ),
    );
  }
}

class _OutlineListBody extends StatelessWidget {
  const _OutlineListBody({
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
            style: GoogleFonts.poppins(
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
          title: Text(
            e.title,
            style: GoogleFonts.poppins(fontSize: 15),
          ),
          onTap: () => onEntryTap(e),
        );
      },
    );
  }
}

class _FontSizeMenu extends StatelessWidget {
  const _FontSizeMenu({required this.editorState, required this.enabled});

  final EditorState editorState;
  final bool enabled;

  static const List<double> _sizes = [12, 14, 16, 18, 24, 32];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double?>(
      enabled: enabled,
      tooltip: 'Font size',
      icon: const Icon(Icons.format_size),
      onOpened: () => keepEditorFocusNotifier.increase(),
      onCanceled: () => keepEditorFocusNotifier.decrease(),
      onSelected: (v) {
        unawaited(
          (() async {
            try {
              await sloteApplyFontSize(editorState, v);
            } finally {
              keepEditorFocusNotifier.decrease();
            }
          })(),
        );
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<double?>(
              value: null,
              child: Text('Default size'),
            ),
            const PopupMenuDivider(),
            ..._sizes.map(
              (s) => PopupMenuItem<double?>(
                value: s,
                child: Text('${s.toInt()}'),
              ),
            ),
          ],
    );
  }
}

class _FontFamilyMenu extends StatelessWidget {
  const _FontFamilyMenu({required this.editorState, required this.enabled});

  final EditorState editorState;
  final bool enabled;

  static const List<String> _families = [
    'sans-serif',
    'serif',
    'monospace',
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      enabled: enabled,
      tooltip: 'Font family',
      icon: const Icon(Icons.font_download),
      onOpened: () => keepEditorFocusNotifier.increase(),
      onCanceled: () => keepEditorFocusNotifier.decrease(),
      onSelected: (v) {
        unawaited(
          (() async {
            try {
              await sloteApplyFontFamily(editorState, v);
            } finally {
              keepEditorFocusNotifier.decrease();
            }
          })(),
        );
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<String?>(
              value: null,
              child: Text('Default font'),
            ),
            const PopupMenuDivider(),
            ..._families.map(
              (f) => PopupMenuItem<String?>(
                value: f,
                child: Text(f),
              ),
            ),
          ],
    );
  }
}

class _BottomRichTextToolbar extends StatelessWidget {
  const _BottomRichTextToolbar({
    required this.editorState,
    required this.listenable,
    this.layout = SloteToolbarLayout.horizontalScroll,
  });

  final EditorState editorState;
  final Listenable listenable;
  final SloteToolbarLayout layout;

  // Keep vertical mode as a single visible bar; users swipe up/down within it.
  static const double _kVerticalToolbarHeight = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final sel = editorState.selection;
        final hasSelection = sel != null;
        final rangeSelection = sel != null && !sel.isCollapsed;
        final caretSelection = sel != null && sel.isCollapsed;

        final groups = <List<Widget>>[
          [
            _formatToggle(
              context: context,
              enabled: sloteEditorCanUndo(editorState),
              selected: false,
              icon: Icons.undo,
              tooltip: 'Undo',
              onPressed: () => sloteEditorUndo(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: sloteEditorCanRedo(editorState),
              selected: false,
              icon: Icons.redo,
              tooltip: 'Redo',
              onPressed: () => sloteEditorRedo(editorState),
            ),
          ],
          [
            _blockAlignmentGroup(
              context: context,
              enabled: hasSelection,
            ),
            SloteHeadingStyleToolbarMenu(
              editorState: editorState,
              enabled: sloteCanUseBlockHeadingControls(editorState),
            ),
          ],
          [
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.format_list_bulleted,
              tooltip: 'Bulleted list',
              onPressed: () => insertBulletedListAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered list',
              onPressed: () => insertNumberedListAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.check_box,
              tooltip: 'Checkbox',
              onPressed: () => insertCheckboxAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onPressed: () => insertQuoteAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.horizontal_rule,
              tooltip: 'Divider',
              onPressed: () => insertNodeAfterSelection(
                editorState,
                dividerNode(),
              ),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.code,
              tooltip: 'Code block',
              onPressed: () => insertCodeBlockAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.lightbulb_outline,
              tooltip: 'Callout',
              onPressed: () => insertCalloutAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.table_chart,
              tooltip: 'Table (2×2)',
              onPressed: () => insertTableAfterSelection(editorState),
            ),
            _formatToggle(
              context: context,
              enabled: caretSelection,
              selected: false,
              icon: Icons.image,
              tooltip: 'Image (URL)',
              onPressed: () async {
                final url = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Insert image URL'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'https://… or file://… or slote://…',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text),
                          child: const Text('Insert'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
                final trimmed = url?.trim();
                if (trimmed == null || trimmed.isEmpty) return;
                insertImageAfterSelection(editorState, url: trimmed);
              },
            ),
          ],
          [
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                AppFlowyRichTextKeys.bold,
              ),
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onPressed:
                  () => applyBiusToggle(
                    editorState,
                    AppFlowyRichTextKeys.bold,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                AppFlowyRichTextKeys.italic,
              ),
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onPressed:
                  () => applyBiusToggle(
                    editorState,
                    AppFlowyRichTextKeys.italic,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                AppFlowyRichTextKeys.underline,
              ),
              icon: Icons.format_underlined,
              tooltip: 'Underline',
              onPressed:
                  () => applyBiusToggle(
                    editorState,
                    AppFlowyRichTextKeys.underline,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                AppFlowyRichTextKeys.strikethrough,
              ),
              icon: Icons.strikethrough_s,
              tooltip: 'Strikethrough',
              onPressed:
                  () => applyBiusToggle(
                    editorState,
                    AppFlowyRichTextKeys.strikethrough,
                  ),
            ),
          ],
          [
            _formatToggle(
              context: context,
              enabled: rangeSelection,
              selected: sloteIsLinkActiveInSelection(editorState),
              icon: Icons.link,
              tooltip: 'Link',
              onPressed:
                  () => sloteShowLinkDialog(
                    editorState,
                    hostContext: context,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsHighlightActiveForToolbar(editorState),
              icon: Icons.highlight,
              tooltip: 'Highlight',
              onPressed:
                  () => showSloteColorFormatDrawer(
                    editorState,
                    hostContext: context,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsTextColorActiveForToolbar(editorState),
              icon: Icons.format_color_text,
              tooltip: 'Text color',
              onPressed:
                  () => showSloteColorFormatDrawer(
                    editorState,
                    hostContext: context,
                  ),
            ),
            _formatToggle(
              context: context,
              enabled: rangeSelection,
              selected: false,
              icon: Icons.format_clear,
              tooltip: 'Clear formatting',
              onPressed:
                  () => unawaited(sloteClearInlineFormatting(editorState)),
            ),
          ],
          [
            _FontSizeMenu(
              editorState: editorState,
              enabled: rangeSelection,
            ),
            _FontFamilyMenu(
              editorState: editorState,
              enabled: hasSelection,
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                kSloteSuperscriptAttribute,
              ),
              icon: Icons.superscript,
              tooltip: 'Superscript',
              onPressed: () =>
                  unawaited(sloteToggleSuperscript(editorState)),
            ),
            _formatToggle(
              context: context,
              enabled: hasSelection,
              selected: sloteIsFormatKeyActive(
                editorState,
                kSloteSubscriptAttribute,
              ),
              icon: Icons.subscript,
              tooltip: 'Subscript',
              onPressed: () =>
                  unawaited(sloteToggleSubscript(editorState)),
            ),
          ],
        ];

        return Material(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: layout == SloteToolbarLayout.verticalScroll ? 2 : 4,
            ),
            child:
                layout == SloteToolbarLayout.verticalScroll
                    ? _buildVertical(groups, scheme)
                    : _buildHorizontal(groups, scheme),
          ),
        );
      },
    );
  }

  Widget _buildHorizontal(List<List<Widget>> groups, ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            ...groups[i],
            if (i != groups.length - 1) _groupDivider(scheme),
          ],
        ],
      ),
    );
  }

  Widget _buildVertical(List<List<Widget>> groups, ColorScheme scheme) {
    // One group per "page": snaps to nearest row (like iOS alarm wheel) with
    // inertial fling + optional edge bounce.
    return SizedBox(
      height: _kVerticalToolbarHeight,
      child: ClipRect(
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: groups.length,
          physics: const SloteToolbarVerticalPagePhysics(
            parent: BouncingScrollPhysics(
              parent: SloteScaledDragScrollPhysics(),
            ),
          ),
          padEnds: false,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: groups[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _groupDivider(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 1,
            height: 24,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockAlignmentGroup({
    required BuildContext context,
    required bool enabled,
  }) {
    final active = sloteBlockAlignmentInSelection(editorState);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.left,
          icon: Icons.format_align_left,
          tooltip: 'Align left',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(
              editorState,
              SloteBlockAlignment.left,
            ),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.center,
          icon: Icons.format_align_center,
          tooltip: 'Align center',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(
              editorState,
              SloteBlockAlignment.center,
            ),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.right,
          icon: Icons.format_align_right,
          tooltip: 'Align right',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(
              editorState,
              SloteBlockAlignment.right,
            ),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.justify,
          icon: Icons.format_align_justify,
          tooltip: 'Justify',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(
              editorState,
              SloteBlockAlignment.justify,
            ),
          ),
        ),
      ],
    );
  }

  Widget _formatToggle({
    required BuildContext context,
    required bool enabled,
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled) return null;
        if (states.contains(WidgetState.selected)) {
          return scheme.primaryContainer;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimaryContainer;
        }
        return scheme.onSurfaceVariant;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: style,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
    );
  }
}
