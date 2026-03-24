import 'package:appflowy_editor/appflowy_editor.dart';

/// Whether [EditorState.undoManager] can undo (AppFlowy transaction history).
bool sloteEditorCanUndo(EditorState editorState) =>
    editorState.undoManager.undoStack.isNonEmpty;

/// Whether [EditorState.undoManager] can redo.
bool sloteEditorCanRedo(EditorState editorState) =>
    editorState.undoManager.redoStack.isNonEmpty;

/// Undo the last user edit via AppFlowy history (same stack as keyboard shortcuts).
void sloteEditorUndo(EditorState editorState) => editorState.undoManager.undo();

/// Redo via AppFlowy history.
void sloteEditorRedo(EditorState editorState) => editorState.undoManager.redo();
