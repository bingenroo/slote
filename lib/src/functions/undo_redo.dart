import 'package:flutter/material.dart';
import 'package:value_notifier_tools/value_notifier_tools.dart';
import 'dart:async';
import 'package:scribble/scribble.dart';

class NoteState {
  final String text;
  final TextSelection textSelection;
  final Sketch scribbleSketch;

  NoteState({
    required this.text,
    required this.textSelection,
    required this.scribbleSketch,
  });

  NoteState copyWith({
    String? text,
    TextSelection? textSelection,
    Sketch? scribbleSketch,
  }) {
    return NoteState(
      text: text ?? this.text,
      textSelection: textSelection ?? this.textSelection,
      scribbleSketch: scribbleSketch ?? this.scribbleSketch,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteState &&
        other.text == text &&
        other.textSelection == textSelection &&
        other.scribbleSketch.toString() == scribbleSketch.toString();
  }

  @override
  int get hashCode => Object.hash(text, textSelection, scribbleSketch);
}

class UnifiedUndoRedoController extends HistoryValueNotifier<NoteState> {
  final TextEditingController _textController;
  final ScribbleNotifier _scribbleNotifier;

  bool _isUpdatingFromHistory = false;
  bool _isInitialState = true;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  UnifiedUndoRedoController({
    required TextEditingController textController,
    required ScribbleNotifier scribbleNotifier,
    int? maxHistoryLength,
  }) : _textController = textController,
       _scribbleNotifier = scribbleNotifier,
       super(
         NoteState(
           text: textController.text,
           textSelection: textController.selection,
           scribbleSketch: scribbleNotifier.currentSketch,
         ),
       ) {
    // Set max history length if provided
    if (maxHistoryLength != null) {
      this.maxHistoryLength = maxHistoryLength;
    }

    // Add listeners
    _textController.addListener(_onTextChanged);
    _scribbleNotifier.addListener(_onDrawingChanged);
  }

  TextEditingController get textController => _textController;
  ScribbleNotifier get scribbleNotifier => _scribbleNotifier;

  void initializeWithCurrentState() {
    final currentState = NoteState(
      text: _textController.text,
      textSelection: _textController.selection,
      scribbleSketch: _scribbleNotifier.currentSketch,
    );

    // Set initial state without adding to history
    // Use the value setter directly to avoid adding to history
    _isUpdatingFromHistory = true;
    value = currentState;
    _isUpdatingFromHistory = false;
    _isInitialState = false;
  }

  void _onTextChanged() {
    if (_isUpdatingFromHistory) return;

    final newText = _textController.text;
    final newSelection = _textController.selection;
    final currentState = value;

    // Skip if this is the initial state setup
    if (_isInitialState) {
      _isInitialState = false;
      return;
    }

    // Skip if text hasn't actually changed
    if (currentState.text == newText) {
      return;
    }

    // Capture selection at the current cursor position
    final capturedSelection =
        newSelection.isValid
            ? newSelection
            : TextSelection.collapsed(offset: newText.length);

    final newState = currentState.copyWith(
      text: newText,
      textSelection: capturedSelection,
    );

    _pendingState = newState;
    _startDebounceTimer();
  }

  void _onDrawingChanged() {
    if (_isUpdatingFromHistory) return;

    final newScribbleSketch = _scribbleNotifier.currentSketch;
    final currentState = value;

    // Skip if drawing hasn't actually changed
    if (currentState.scribbleSketch.toString() ==
        newScribbleSketch.toString()) {
      return;
    }

    final newState = currentState.copyWith(scribbleSketch: newScribbleSketch);
    _pendingState = newState;
    _startDebounceTimer();
  }

  NoteState? _pendingState;

  void _startDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _addPendingStateToHistory();
    });
  }

  void _addPendingStateToHistory() {
    if (_pendingState != null) {
      final newState = _pendingState!;

      // Add to history
      value = newState;
      _pendingState = null;
    }
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // If there are pending changes, add them immediately
    if (_pendingState != null) {
      _addPendingStateToHistory();
    }
  }

  NoteState transformHistoryState(NoteState newState, NoteState currentState) {
    // Apply the state changes
    _isUpdatingFromHistory = true;

    // Update text controller
    final textLength = newState.text.length;
    final restoredSelection = newState.textSelection;

    // Ensure we don't go beyond text bounds
    final safeStart = restoredSelection.start.clamp(0, textLength);
    final safeEnd = restoredSelection.end.clamp(safeStart, textLength);

    final newSelection = TextSelection(
      baseOffset: safeStart,
      extentOffset: safeEnd,
    );

    _textController.value = TextEditingValue(
      text: newState.text,
      selection: newSelection,
    );

    // Update drawing by restoring the sketch
    _restoreScribbleSketch(newState.scribbleSketch);

    _isUpdatingFromHistory = false;
    return newState;
  }

  void _restoreScribbleSketch(Sketch sketch) {
    _scribbleNotifier.setSketch(sketch: sketch, addToUndoHistory: false);
  }

  void clearHistory() {
    _cancelDebounce();
    // Clear the history by resetting to initial state
    final initialState = NoteState(
      text: _textController.text,
      textSelection: _textController.selection,
      scribbleSketch: _scribbleNotifier.currentSketch,
    );
    value = initialState;
  }

  void setText(String text) {
    _cancelDebounce();
    final newState = value.copyWith(
      text: text,
      textSelection: TextSelection.collapsed(offset: text.length),
    );
    // Set state without adding to history
    _isUpdatingFromHistory = true;
    value = newState;
    _isUpdatingFromHistory = false;
    _textController.text = text;
  }

  void clearDrawing() {
    _cancelDebounce();
    final newState = value.copyWith(
      scribbleSketch:
          _scribbleNotifier.currentSketch, // Use current empty sketch
    );
    // Set state without adding to history
    _isUpdatingFromHistory = true;
    value = newState;
    _isUpdatingFromHistory = false;
    _scribbleNotifier.clear();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _scribbleNotifier.removeListener(_onDrawingChanged);
    super.dispose();
  }
}
