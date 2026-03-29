import 'package:appflowy_editor/appflowy_editor.dart';

/// Whether [key] (e.g. a [AppFlowyRichTextKeys] partial style or Slote custom
/// bool attribute) reads as active for toolbar / shortcuts.
///
/// Collapsed carets use [EditorState.toggledStyle] and slice attributes at the
/// caret; non-collapsed ranges use [EditorState.getNodesInSelection].
bool sloteIsFormatKeyActive(EditorState editorState, String key) {
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

/// Non-collapsed selection only: all runs carry `href`.
bool sloteIsLinkActiveInSelection(EditorState editorState) {
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

/// Highlight (`backgroundColor`) active for toolbar indicator: pending toggled
/// style at a collapsed caret, or full-range highlight when expanded.
bool sloteIsHighlightActiveForToolbar(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) return false;
  final bg = AppFlowyRichTextKeys.backgroundColor;

  if (selection.isCollapsed) {
    final toggled = editorState.toggledStyle;
    if (toggled.containsKey(bg)) {
      return toggled[bg] != null;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (delta == null || delta.isEmpty) return false;
    final atCaret = delta.sliceAttributes(selection.start.offset);
    return atCaret?[bg] != null;
  }

  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes(
          (attr) => attr[bg] != null,
        ),
  );
}

/// Text color active: pending toggled color at caret, or uniform non-null
/// `font_color` across a range.
bool sloteIsTextColorActiveForToolbar(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) return false;
  final colorKey = AppFlowyRichTextKeys.textColor;

  if (selection.isCollapsed) {
    final toggled = editorState.toggledStyle;
    if (toggled.containsKey(colorKey)) {
      return toggled[colorKey] != null;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (delta == null || delta.isEmpty) return false;
    final atCaret = delta.sliceAttributes(selection.start.offset);
    return atCaret?[colorKey] != null;
  }

  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(
    selection,
    (delta) =>
        delta.isNotEmpty &&
        delta.everyAttributes(
          (attr) => attr[colorKey] != null,
        ),
  );
}
