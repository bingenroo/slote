import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';

import 'slote_inline_attributes.dart';
import 'appflowy_undo_support.dart';

class _UndoRedoListenable extends ChangeNotifier {
  void signalHistoryMayHaveChanged() => notifyListeners();
}

/// Owns an [EditorState], listens to [EditorState.transactionStream], and
/// emits debounced canonical document JSON for persistence / preview / logging.
///
/// Call [dispose] to cancel the subscription, pending debounce timer,
/// [undoRedoListenable], and [EditorState.dispose].
class RichTextEditorController {
  RichTextEditorController({
    required Document document,
    this.onDocumentJsonChanged,
    this.debounce = const Duration(milliseconds: 200),
    int? maxHistoryItemSize,
    Duration minHistoryItemDuration = const Duration(milliseconds: 50),
  }) : _undoRedoListenable = _UndoRedoListenable(),
       editorState = EditorState(
         document: document,
         minHistoryItemDuration: minHistoryItemDuration,
         maxHistoryItemSize: maxHistoryItemSize,
       ) {
    editorState.selectionNotifier.addListener(_onSelectionChangedForSupSub);
    _subscription = editorState.transactionStream.listen(_onTransaction);
  }

  /// Builds from AppFlowy document JSON (same shape as [Document.toJson] /
  /// [Document.fromJson] input).
  factory RichTextEditorController.fromJson(
    Map<String, dynamic> documentJson, {
    void Function(Map<String, Object> json)? onDocumentJsonChanged,
    Duration debounce = const Duration(milliseconds: 200),
    int? maxHistoryItemSize,
    Duration minHistoryItemDuration = const Duration(milliseconds: 50),
  }) {
    return RichTextEditorController(
      document: Document.fromJson(documentJson),
      onDocumentJsonChanged: onDocumentJsonChanged,
      debounce: debounce,
      maxHistoryItemSize: maxHistoryItemSize,
      minHistoryItemDuration: minHistoryItemDuration,
    );
  }

  final EditorState editorState;

  final _UndoRedoListenable _undoRedoListenable;

  /// Notifies when [sloteEditorCanUndo] / [sloteEditorCanRedo] may have changed
  /// (after non–in-memory transactions only).
  Listenable get undoRedoListenable => _undoRedoListenable;

  /// Debounced snapshot of [EditorState.document] via [Document.toJson].
  final void Function(Map<String, Object> json)? onDocumentJsonChanged;

  final Duration debounce;

  StreamSubscription<EditorTransactionValue>? _subscription;
  Timer? _debounceTimer;

  bool _lastCanUndo = false;
  bool _lastCanRedo = false;

  bool _caretStyleSyncInFlight = false;

  void _onSelectionChangedForSupSub() {
    _syncCaretSupSubTypingStyle();
  }

  void _syncCaretSupSubTypingStyle() {
    if (_caretStyleSyncInFlight) return;
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    final toggled = editorState.toggledStyle;
    final currSup = toggled[kSloteSuperscriptAttribute] == true;
    final currSub = toggled[kSloteSubscriptAttribute] == true;

    bool desiredSup = false;
    bool desiredSub = false;
    try {
      if (delta != null && !delta.isEmpty) {
        final atCaret = delta.sliceAttributes(selection.start.offset);
        desiredSup = atCaret?[kSloteSuperscriptAttribute] == true;
        desiredSub = atCaret?[kSloteSubscriptAttribute] == true;
      }
    } catch (_) {
      // If AppFlowy reports an offset outside delta bounds, treat as baseline.
      desiredSup = false;
      desiredSub = false;
    }

    // Sup and sub are mutually exclusive; prefer superscript if corrupted.
    if (desiredSup) desiredSub = false;

    if (desiredSup == currSup && desiredSub == currSub) return;

    _caretStyleSyncInFlight = true;
    try {
      if (desiredSup) {
        if (currSub) editorState.toggleAttribute(kSloteSubscriptAttribute);
        if (!currSup) {
          editorState.toggleAttribute(kSloteSuperscriptAttribute);
        }
      } else if (desiredSub) {
        if (currSup) editorState.toggleAttribute(kSloteSuperscriptAttribute);
        if (!currSub) {
          editorState.toggleAttribute(kSloteSubscriptAttribute);
        }
      } else {
        if (currSup) editorState.toggleAttribute(kSloteSuperscriptAttribute);
        if (currSub) editorState.toggleAttribute(kSloteSubscriptAttribute);
      }
    } finally {
      _caretStyleSyncInFlight = false;
    }
  }

  void _onTransaction(EditorTransactionValue event) {
    final (time, _, options) = event;
    if (time != TransactionTime.after) return;
    if (options.inMemoryUpdate) return;
    // AppFlowy records undo *after* emitting `after` on [transactionStream];
    // defer reads so [undoManager] stacks match the new document state.
    scheduleMicrotask(_maybeNotifyUndoRedo);
    _scheduleDebouncedEmit();
  }

  void _maybeNotifyUndoRedo() {
    if (editorState.isDisposed) return;
    final canUndo = sloteEditorCanUndo(editorState);
    final canRedo = sloteEditorCanRedo(editorState);
    if (canUndo == _lastCanUndo && canRedo == _lastCanRedo) return;
    _lastCanUndo = canUndo;
    _lastCanRedo = canRedo;
    _undoRedoListenable.signalHistoryMayHaveChanged();
  }

  void _scheduleDebouncedEmit() {
    if (onDocumentJsonChanged == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _emitDocumentJson);
  }

  void _emitDocumentJson() {
    if (editorState.isDisposed) return;
    onDocumentJsonChanged?.call(editorState.document.toJson());
  }

  /// Emit [Document.toJson] immediately (cancels a pending debounced emit).
  void flushDocumentNotification() {
    _debounceTimer?.cancel();
    _emitDocumentJson();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    editorState.selectionNotifier.removeListener(_onSelectionChangedForSupSub);
    editorState.dispose();
    _undoRedoListenable.dispose();
  }
}
