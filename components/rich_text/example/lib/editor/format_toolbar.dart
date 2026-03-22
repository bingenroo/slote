import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

/// Fixed formatting bar: BIUS toggles, link, highlight, text color, clear.
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
                    enabled: hasSelection,
                    selected: isFormatKeyActive(
                      editorState,
                      AppFlowyRichTextKeys.bold,
                    ),
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onPressed: () =>
                        applyBiusToggle(editorState, AppFlowyRichTextKeys.bold),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: hasSelection,
                    selected: isFormatKeyActive(
                      editorState,
                      AppFlowyRichTextKeys.italic,
                    ),
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    onPressed: () => applyBiusToggle(
                      editorState,
                      AppFlowyRichTextKeys.italic,
                    ),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: hasSelection,
                    selected: isFormatKeyActive(
                      editorState,
                      AppFlowyRichTextKeys.underline,
                    ),
                    icon: Icons.format_underlined,
                    tooltip: 'Underline',
                    onPressed: () => applyBiusToggle(
                      editorState,
                      AppFlowyRichTextKeys.underline,
                    ),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: hasSelection,
                    selected: isFormatKeyActive(
                      editorState,
                      AppFlowyRichTextKeys.strikethrough,
                    ),
                    icon: Icons.strikethrough_s,
                    tooltip: 'Strikethrough',
                    onPressed: () => applyBiusToggle(
                      editorState,
                      AppFlowyRichTextKeys.strikethrough,
                    ),
                  ),
                  const VerticalDivider(width: 16),
                  // Link, highlight, text color, clear use [EditorState.formatDelta]
                  // / dialog helpers from `package:rich_text` (range selection only).
                  _formatToggle(
                    context: context,
                    enabled: rangeSelection,
                    selected: isLinkActiveInSelection(editorState),
                    icon: Icons.link,
                    tooltip: 'Link',
                    onPressed: () => sloteShowLinkDialog(editorState),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: rangeSelection,
                    selected: isHighlightActiveInSelection(editorState),
                    icon: Icons.highlight,
                    tooltip: 'Highlight',
                    onPressed: () =>
                        unawaited(sloteToggleHighlight(editorState)),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: rangeSelection,
                    selected:
                        isSloteSpikeTextColorActiveInSelection(editorState),
                    icon: Icons.format_color_text,
                    tooltip: 'Text color',
                    onPressed: () =>
                        unawaited(sloteToggleTextColor(editorState)),
                  ),
                  _formatToggle(
                    context: context,
                    enabled: rangeSelection,
                    selected: false,
                    icon: Icons.format_clear,
                    tooltip: 'Clear formatting',
                    onPressed: () =>
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

/// Whether [key] (an [AppFlowyRichTextKeys] partial style) reads as active.
bool isFormatKeyActive(EditorState editorState, String key) {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (selection.isCollapsed) {
    final toggled = editorState.toggledStyle;
    if (toggled.containsKey(key)) {
      return toggled[key] == true;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (delta == null || delta.isEmpty) {
      return false;
    }
    final atCaret = delta.sliceAttributes(selection.start.offset);
    return atCaret?[key] == true;
  }

  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes((attr) => attr[key] == true),
  );
}

/// Non-collapsed selection only; all runs carry `href`.
bool isLinkActiveInSelection(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return false;
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes(
          (attr) => attr[AppFlowyRichTextKeys.href] != null,
        ),
  );
}

/// Non-collapsed selection only; all runs have a highlight color.
bool isHighlightActiveInSelection(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return false;
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes(
          (attr) => attr[AppFlowyRichTextKeys.backgroundColor] != null,
        ),
  );
}

/// Non-collapsed selection only; all runs use [sloteSpikeTextColorHex].
bool isSloteSpikeTextColorActiveInSelection(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return false;
  final hex = sloteSpikeTextColorHex;
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes(
          (attr) => attr[AppFlowyRichTextKeys.textColor] == hex,
        ),
  );
}
