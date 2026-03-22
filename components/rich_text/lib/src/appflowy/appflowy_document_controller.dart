import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';

/// Owns an [EditorState], listens to [EditorState.transactionStream], and
/// emits debounced canonical document JSON for persistence / preview / logging.
///
/// Call [dispose] to cancel the subscription, pending debounce timer, and
/// [EditorState.dispose].
class RichTextEditorController {
  RichTextEditorController({
    required Document document,
    this.onDocumentJsonChanged,
    this.debounce = const Duration(milliseconds: 200),
  }) : editorState = EditorState(document: document) {
    _subscription = editorState.transactionStream.listen(_onTransaction);
  }

  /// Builds from AppFlowy document JSON (same shape as [Document.toJson] /
  /// [Document.fromJson] input).
  factory RichTextEditorController.fromJson(
    Map<String, dynamic> documentJson, {
    void Function(Map<String, Object> json)? onDocumentJsonChanged,
    Duration debounce = const Duration(milliseconds: 200),
  }) {
    return RichTextEditorController(
      document: Document.fromJson(documentJson),
      onDocumentJsonChanged: onDocumentJsonChanged,
      debounce: debounce,
    );
  }

  final EditorState editorState;

  /// Debounced snapshot of [EditorState.document] via [Document.toJson].
  final void Function(Map<String, Object> json)? onDocumentJsonChanged;

  final Duration debounce;

  StreamSubscription<EditorTransactionValue>? _subscription;
  Timer? _debounceTimer;

  void _onTransaction(EditorTransactionValue event) {
    final (time, _, options) = event;
    if (time != TransactionTime.after) return;
    if (options.inMemoryUpdate) return;
    _scheduleDebouncedEmit();
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
    editorState.dispose();
  }
}
