import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

/// Fixed formatting bar: BIUS, heading/body, link, colors, clear, fonts, sup/sub.
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({
    super.key,
    required this.editorState,
    required this.listenable,
  });

  final EditorState editorState;
  final Listenable listenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  _groupDivider(scheme),
                  _blockAlignmentGroup(
                    context: context,
                    enabled: hasSelection,
                  ),
                  _groupDivider(scheme),
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
                  _groupDivider(scheme),
                  SloteHeadingStyleToolbarMenu(
                    editorState: editorState,
                    enabled: sloteCanUseBlockHeadingControls(editorState),
                  ),
                  _groupDivider(scheme),
                  // Link needs a range; other inline actions work at caret via
                  // toggledStyle / formatDelta.
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
                    onPressed:
                        () => unawaited(sloteToggleSuperscript(editorState)),
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
                    onPressed:
                        () => unawaited(sloteToggleSubscript(editorState)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            sloteApplyBlockAlignment(editorState, SloteBlockAlignment.left),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.center,
          icon: Icons.format_align_center,
          tooltip: 'Align center',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(editorState, SloteBlockAlignment.center),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.right,
          icon: Icons.format_align_right,
          tooltip: 'Align right',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(editorState, SloteBlockAlignment.right),
          ),
        ),
        _formatToggle(
          context: context,
          enabled: enabled,
          selected: active == SloteBlockAlignment.justify,
          icon: Icons.format_align_justify,
          tooltip: 'Justify',
          onPressed: () => unawaited(
            sloteApplyBlockAlignment(editorState, SloteBlockAlignment.justify),
          ),
        ),
      ],
    );
  }

  /// Separator between toolbar groups. [VerticalDivider] is often invisible
  /// here: low contrast on [ColorScheme.surfaceContainerLow] and weak height
  /// constraints in a horizontal [SingleChildScrollView] + [Row].
  Widget _groupDivider(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 1,
            height: 24,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Single styling for all format [IconButton]s (BIUS toggles and extended
  /// inline actions).
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
              (s) =>
                  PopupMenuItem<double?>(value: s, child: Text('${s.toInt()}')),
            ),
          ],
    );
  }
}

class _FontFamilyMenu extends StatelessWidget {
  const _FontFamilyMenu({required this.editorState, required this.enabled});

  final EditorState editorState;
  final bool enabled;

  static const List<String> _families = ['sans-serif', 'serif', 'monospace'];

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
              (f) => PopupMenuItem<String?>(value: f, child: Text(f)),
            ),
          ],
    );
  }
}
