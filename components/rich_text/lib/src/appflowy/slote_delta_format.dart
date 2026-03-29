import 'package:appflowy_editor/appflowy_editor.dart';

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
