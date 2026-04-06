import 'package:appflowy_editor/appflowy_editor.dart';

// Stores pending typing style for the "no caret yet" state.
//
// We cannot rely on `EditorState.toggledStyle` because AppFlowy clears it on any
// selection change (including when the caret is first planted). We also cannot
// rely on `selectionExtraInfo` because AppFlowy may overwrite it during
// selection updates.
//
// `Expando` safely attaches data to an object without manual lifecycle hooks.
final Expando<Map<String, dynamic>> _slotePendingTypingStyle =
    Expando<Map<String, dynamic>>('slotePendingTypingStyle');

void sloteRememberPendingTypingStyle(
  EditorState editorState,
  String attributeKey,
  dynamic value,
) {
  final pending = _slotePendingTypingStyle[editorState] ?? <String, dynamic>{};
  pending[attributeKey] = value;
  _slotePendingTypingStyle[editorState] = pending;
}

Map<String, dynamic>? sloteTakePendingTypingStyle(EditorState editorState) {
  final pending = _slotePendingTypingStyle[editorState];
  if (pending == null || pending.isEmpty) return null;
  _slotePendingTypingStyle[editorState] = <String, dynamic>{};
  return Map<String, dynamic>.from(pending);
}

/// Applies or clears `href` on [selection] (non-collapsed).
Future<void> sloteApplyLinkHref(
  EditorState editorState,
  Selection selection,
  String? href,
) async {
  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.href: href},
  );
}

/// Applies or clears highlight (`backgroundColor`) on [selection].
///
/// Collapsed [selection] updates [EditorState.toggledStyle] so the next insert
/// picks up the highlight (or explicit clear).
Future<void> sloteApplyHighlightColor(
  EditorState editorState,
  Selection selection,
  String? backgroundHex,
) async {
  if (selection.isCollapsed) {
    editorState.updateToggledStyle(
      AppFlowyRichTextKeys.backgroundColor,
      backgroundHex,
    );
    return;
  }
  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.backgroundColor: backgroundHex},
  );
}

/// Applies or clears text color (`font_color`) on [selection].
///
/// Collapsed [selection] updates [EditorState.toggledStyle] for the next insert.
Future<void> sloteApplyTextColor(
  EditorState editorState,
  Selection selection,
  String? textColorHex,
) async {
  if (selection.isCollapsed) {
    editorState.updateToggledStyle(
      AppFlowyRichTextKeys.textColor,
      textColorHex,
    );
    return;
  }
  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.textColor: textColorHex},
  );
}
