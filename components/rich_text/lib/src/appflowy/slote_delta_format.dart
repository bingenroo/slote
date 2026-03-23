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
Future<void> sloteApplyHighlightColor(
  EditorState editorState,
  Selection selection,
  String? backgroundHex,
) async {
  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.backgroundColor: backgroundHex},
  );
}

/// Applies or clears text color (`font_color`) on [selection].
Future<void> sloteApplyTextColor(
  EditorState editorState,
  Selection selection,
  String? textColorHex,
) async {
  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.textColor: textColorHex},
  );
}
