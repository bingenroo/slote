import 'package:appflowy_editor/src/editor/command/transform.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/character_shortcut_event.dart';
import 'package:appflowy_editor/src/editor/util/platform_extension.dart';
import 'package:flutter/services.dart';

/// insert a new line block
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CharacterShortcutEvent insertNewLine = CharacterShortcutEvent(
  key: 'insert a new line',
  character: '\n',
  handler: _insertNewLineHandler,
);

CharacterShortcutEventHandler _insertNewLineHandler = (editorState) async {
  // on desktop or web, shift + enter to insert a '\n' character to the same line.
  // so, we should return the false to let the system handle it.
  if (PlatformExtension.isNotMobile &&
      HardwareKeyboard.instance.isShiftPressed) {
    return false;
  }

  var selection = editorState.selection?.normalized;
  if (selection == null) {
    return false;
  }

  // delete the selection
  await editorState.deleteSelection(selection);
  // Re-read selection: [selection.start] is stale after delete.
  selection = editorState.selection?.normalized;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  return editorState.insertNewLine(position: selection.start);
};
