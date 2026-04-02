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
    ensureSloteAppFlowyRichTextKeysRegistered();
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
    // If the user explicitly toggled sup/sub at a collapsed caret, respect that
    // intent. The IME insert path merges slice attrs then `toggledStyle`, and
    // our toggle helpers rely on explicit `false` to override a script slice.
    //
    // AppFlowy clears `toggledStyle` after applying a transaction; in that case
    // this guard is false and we restore from slice attrs for continued typing.
    if (toggled.containsKey(kSloteSuperscriptAttribute) ||
        toggled.containsKey(kSloteSubscriptAttribute)) {
      return;
    }
    final currSup = toggled[kSloteSuperscriptAttribute] == true;
    final currSub = toggled[kSloteSubscriptAttribute] == true;

    bool desiredSup = false;
    bool desiredSub = false;
    try {
      if (delta != null && delta.isNotEmpty) {
        // Delta.sliceAttributes(k): for k>=1 it returns attributes for plain char (k-1).
        // For a collapsed caret, prefer the style of the *following* character.
        final plainLen = delta.toPlainText().length;
        final o = selection.start.offset.clamp(0, plainLen);
        final sliceProbe =
            o >= plainLen ? plainLen : (o + 1).clamp(0, plainLen);

        final atCaret = delta.sliceAttributes(sliceProbe);
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

    if (kDebugMode) {
      debugPrint(
        'DBG-SUPSUB-SYNC offset=${selection.start.offset} '
        'currSup=$currSup currSub=$currSub desiredSup=$desiredSup desiredSub=$desiredSub',
      );
    }

    if (desiredSup == currSup && desiredSub == currSub) return;

    // Do not use [EditorState.toggleAttribute] for a collapsed caret here.
    // After each keystroke, [EditorState.selection] clears [toggledStyle]; this
    // sync restores script keys from [Delta.sliceAttributes]. Stock
    // `toggleAttribute` for a collapsed selection *without* the key in
    // [toggledStyle] inspects the previous character and sets the pending key to
    // the *opposite* of that slice (toggle off when the run already has the
    // attribute). That leaves `slote_subscript: false` in [toggledStyle], and
    // [Transaction.insertText] merges with `addAll(toggledAttributes)`, which
    // strips subscript/superscript on the next typed character.
    _caretStyleSyncInFlight = true;
    try {
      editorState.updateToggledStyle(
        kSloteSuperscriptAttribute,
        desiredSup,
      );
      editorState.updateToggledStyle(
        kSloteSubscriptAttribute,
        desiredSub,
      );
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
