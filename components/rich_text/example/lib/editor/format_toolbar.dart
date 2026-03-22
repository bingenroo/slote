import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

/// Fixed BIUS bar using [EditorState.toggleAttribute] (same entry point as
/// AppFlowy’s format toolbar / markdown commands).
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
        final selection = editorState.selection;
        final enabled = selection != null;
        return Material(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _formatToggle(
                  context: context,
                  enabled: enabled,
                  attributeKey: AppFlowyRichTextKeys.bold,
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                ),
                _formatToggle(
                  context: context,
                  enabled: enabled,
                  attributeKey: AppFlowyRichTextKeys.italic,
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                ),
                _formatToggle(
                  context: context,
                  enabled: enabled,
                  attributeKey: AppFlowyRichTextKeys.underline,
                  icon: Icons.format_underlined,
                  tooltip: 'Underline',
                ),
                _formatToggle(
                  context: context,
                  enabled: enabled,
                  attributeKey: AppFlowyRichTextKeys.strikethrough,
                  icon: Icons.strikethrough_s,
                  tooltip: 'Strikethrough',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Strong selected vs idle styling — default [IconButton] M3 theming is easy
  /// to miss when `isSelected` is true.
  Widget _formatToggle({
    required BuildContext context,
    required bool enabled,
    required String attributeKey,
    required IconData icon,
    required String tooltip,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final active = isFormatKeyActive(editorState, attributeKey);

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
      isSelected: active,
      style: style,
      onPressed: enabled
          ? () => applyBiusToggle(editorState, attributeKey)
          : null,
      icon: Icon(icon),
    );
  }
}

/// Whether [key] (an [AppFlowyRichTextKeys] partial style) reads as active.
///
/// - **Range:** same as AppFlowy’s format toolbar — all selected runs carry the
///   attribute.
/// - **Collapsed caret:** use [Delta.sliceAttributes] at the offset (AppFlowy’s
///   default slice rules: index 0 uses the next char, else the previous). If the
///   user has an explicit “next typed” override from [EditorState.toggleAttribute],
///   [EditorState.toggledStyle] wins until the selection moves.
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
