import 'dart:async';
import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rich_text/rich_text.dart';
import 'package:shared/shared.dart';
import 'package:slote/src/model/note.dart';
import 'package:theme/theme.dart';

/// Minimal empty AppFlowy page document for new notes or bad payloads.
const Map<String, Object> _kEmptyAppFlowyDocumentJson = {
  'document': {
    'type': 'page',
    'children': [
      {
        'type': 'paragraph',
        'data': {
          'delta': [
            {'insert': ' '},
          ],
        },
      },
    ],
  },
};

Map<String, dynamic> _documentJsonFromNoteBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> &&
        decoded['document'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    // ignore
  }
  return Map<String, dynamic>.from(_kEmptyAppFlowyDocumentJson);
}

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();

  late final RichTextEditorController _richTextController;
  late final Listenable _formatBarListenable;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';

    final initialJson =
        widget.note != null
            ? _documentJsonFromNoteBody(widget.note!.body)
            : Map<String, dynamic>.from(_kEmptyAppFlowyDocumentJson);

    _richTextController = RichTextEditorController.fromJson(initialJson);

    _formatBarListenable = Listenable.merge([
      _richTextController.editorState.selectionNotifier,
      _richTextController.editorState.toggledStyleNotifier,
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _richTextController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    Navigator.pop(context);
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
                    : 'Leave this screen? Changes are not saved to the database yet.',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
        .copyWith(textSpanDecorator: sloteTextSpanDecoratorForAttribute);
    final editorState = _richTextController.editorState;

    return Scaffold(
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
          commandShortcutEvents:
              standardCommandShortcutsWithSloteInlineHandlers(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomRichTextToolbar(
          editorState: editorState,
          listenable: _formatBarListenable,
        ),
      ),
    );
  }
}

class _BottomRichTextToolbar extends StatelessWidget {
  const _BottomRichTextToolbar({
    required this.editorState,
    required this.listenable,
  });

  final EditorState editorState;
  final Listenable listenable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final sel = editorState.selection;
        final hasSelection = sel != null;
        final rangeSelection = sel != null && !sel.isCollapsed;

        return Material(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  Padding(
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
                  ),
                  SloteHeadingStyleToolbarMenu(
                    editorState: editorState,
                    enabled: sloteCanUseBlockHeadingControls(editorState),
                  ),
                  Padding(
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
                  ),
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
                        () =>
                            unawaited(sloteClearInlineFormatting(editorState)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
