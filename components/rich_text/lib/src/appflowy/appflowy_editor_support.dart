/// Slote helpers for [AppFlowyEditor] composition: inline formatting, command
/// shortcuts, and related glue.
///
/// Today: BIUS toggles and keyboard parity with the toolbar. Per
/// `docs/ROADMAP.md`, this module can grow with extended inline styles (Wave B),
/// or split into e.g. `appflowy_blocks.dart` / `appflowy_history.dart` when
/// block builders or undo/redo chrome land (Waves C / listeners table).
library;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

// --- Inline formatting (toolbar, tests, custom shortcuts) --------------------

/// Shared BIUS entry point for toolbar buttons, tests, and custom shortcuts.
///
/// Matches AppFlowy’s built-in markdown command handlers: they call
/// [EditorState.toggleAttribute] when the selection is non-null.
void applyBiusToggle(EditorState editorState, String attributeKey) {
  editorState.toggleAttribute(attributeKey);
}

/// BIUS command-shortcut handler: same [EditorState.toggleAttribute] path as
/// [applyBiusToggle], with the same **null selection → ignored** behavior as
/// AppFlowy’s `toggleBoldCommand` / `toggleItalicCommand` / etc.
KeyEventResult applyBiusFromShortcut(
  EditorState editorState,
  String attributeKey,
) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }
  editorState.toggleAttribute(attributeKey);
  return KeyEventResult.handled;
}

// --- Command shortcuts -------------------------------------------------------

const _biusCommandKeys = {
  'toggle bold',
  'toggle italic',
  'toggle underline',
  'toggle strikethrough',
};

CommandShortcutEvent _shortcutWithSharedHandler(
  CommandShortcutEvent base,
  String attributeKey,
) {
  return base.copyWith(
    handler: (editorState) =>
        applyBiusFromShortcut(editorState, attributeKey),
  );
}

/// Lazily-built map: standard BIUS command keys → shortcuts whose handlers use
/// [applyBiusFromShortcut] (same formatting path as [applyBiusToggle]).
Map<String, CommandShortcutEvent> _sloteBiusReplacements() => {
      'toggle bold': _shortcutWithSharedHandler(
        toggleBoldCommand,
        AppFlowyRichTextKeys.bold,
      ),
      'toggle italic': _shortcutWithSharedHandler(
        toggleItalicCommand,
        AppFlowyRichTextKeys.italic,
      ),
      'toggle underline': _shortcutWithSharedHandler(
        toggleUnderlineCommand,
        AppFlowyRichTextKeys.underline,
      ),
      'toggle strikethrough': _shortcutWithSharedHandler(
        toggleStrikethroughCommand,
        AppFlowyRichTextKeys.strikethrough,
      ),
    };

/// [standardCommandShortcutEvents] with BIUS bindings replaced so handlers go
/// through [applyBiusFromShortcut] — parity with the BIUS toolbar using
/// [applyBiusToggle] (both end at [EditorState.toggleAttribute]).
List<CommandShortcutEvent> standardCommandShortcutsWithSharedBius() {
  final repl = _sloteBiusReplacements();
  return standardCommandShortcutEvents
      .map((e) => repl[e.key] ?? e)
      .toList(growable: false);
}

/// Whether [key] is one of the four BIUS command shortcut keys (for tests/docs).
bool isBiusCommandShortcutKey(String key) => _biusCommandKeys.contains(key);
