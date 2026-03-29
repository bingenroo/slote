/// Slote-defined inline attribute keys stored in AppFlowy delta attributes.
///
/// These are intentionally *not* part of `AppFlowyRichTextKeys` (package-owned).
library;

import 'package:appflowy_editor/appflowy_editor.dart';

/// Ensures Slote custom inline keys are allowed in [EditorState.toggledStyle] and
/// participate in [Delta.sliceAttributes] at offset 0.
///
/// AppFlowy’s IME insert path asserts that every [EditorState.toggledStyle] key is
/// listed in [AppFlowyRichTextKeys.supportToggled]; Slote’s superscript/subscript
/// keys are not there by default. This mutates the package lists once (idempotent).
///
/// Call from `RichTextEditorController` and from `sloteToggleSuperscript` /
/// `sloteToggleSubscript` (or once at app startup) so debug builds do not assert
/// when typing with a pending script style.
void ensureSloteAppFlowyRichTextKeysRegistered() {
  final toggled = AppFlowyRichTextKeys.supportToggled;
  final sliced = AppFlowyRichTextKeys.supportSliced;
  if (!toggled.contains(kSloteSuperscriptAttribute)) {
    toggled.add(kSloteSuperscriptAttribute);
  }
  if (!toggled.contains(kSloteSubscriptAttribute)) {
    toggled.add(kSloteSubscriptAttribute);
  }
  if (!sliced.contains(kSloteSuperscriptAttribute)) {
    sliced.add(kSloteSuperscriptAttribute);
  }
  if (!sliced.contains(kSloteSubscriptAttribute)) {
    sliced.add(kSloteSubscriptAttribute);
  }
}

/// Inline superscript attribute key.
///
/// Value convention: `true` when enabled, `null`/absent when cleared.
const String kSloteSuperscriptAttribute = 'slote_superscript';

/// Inline subscript attribute key.
///
/// Value convention: `true` when enabled, `null`/absent when cleared.
const String kSloteSubscriptAttribute = 'slote_subscript';

