import 'package:flutter/material.dart';
import 'package:undo/undo.dart';
import 'dart:async';

class TextState {
  final String text;
  final TextSelection selection;

  TextState(this.text, this.selection);
}

class UndoRedoTextController extends ChangeNotifier {
  final TextEditingController _externalController;
  final ChangeStack _changeStack;
  bool _isUpdatingFromStack = false;
  bool _isInitialState = true;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 100);

  TextState _lastState = TextState(
    '',
    const TextSelection.collapsed(offset: 0),
  );
  TextState? _pendingState;

  UndoRedoTextController(this._changeStack, this._externalController) {
    _externalController.addListener(_onTextChanged);
    // Initialize with current text from external controller
    _lastState = TextState(
      _externalController.text,
      _externalController.selection,
    );
  }

  TextEditingController get textController => _externalController;
  String get currentText => _externalController.text;
  bool get canUndo => _changeStack.canUndo;
  bool get canRedo => _changeStack.canRedo;

  void undo() {
    if (_changeStack.canUndo) {
      _cancelDebounce();
      _changeStack.undo();
    }
  }

  void redo() {
    if (_changeStack.canRedo) {
      _cancelDebounce();
      _changeStack.redo();
    }
  }

  void _onTextChanged() {
    if (_isUpdatingFromStack) return;
    final newText = _externalController.text;
    final newSelection = _externalController.selection;
    final oldState = _lastState;

    // Skip adding to stack if this is the initial state setup
    if (_isInitialState) {
      _lastState = TextState(newText, newSelection);
      _isInitialState = false;
      return;
    }

    // Skip if text hasn't actually changed
    if (oldState.text == newText) {
      // Update selection even if text hasn't changed
      _lastState = TextState(newText, newSelection);
      return;
    }

    // Capture selection at the current cursor position (end of new text for typing)
    final capturedSelection =
        newSelection.isValid
            ? newSelection
            : TextSelection.collapsed(offset: newText.length);

    final newState = TextState(newText, capturedSelection);
    _pendingState = newState;

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _addToStack();
    });
  }

  void _addToStack() {
    if (_pendingState == null) return;

    final oldState = _lastState;
    final newState = _pendingState!;

    _changeStack.add(
      Change<TextState>(
        oldState,
        () => _updateTextFromStack(newState),
        (oldValue) => _updateTextFromStack(oldValue),
      ),
    );

    _lastState = newState;
    _pendingState = null;
    notifyListeners();
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // If there's a pending state, add it immediately
    if (_pendingState != null) {
      _addToStack();
    }
  }

  void _updateTextFromStack(TextState state) {
    _isUpdatingFromStack = true;

    final textLength = state.text.length;
    final restoredSelection = state.selection;

    // Ensure we don't go beyond text bounds
    final safeStart = restoredSelection.start.clamp(0, textLength);
    final safeEnd = restoredSelection.end.clamp(safeStart, textLength);

    final newSelection = TextSelection(
      baseOffset: safeStart,
      extentOffset: safeEnd,
    );

    // Set text and selection together using value setter to avoid the jump
    _externalController.value = TextEditingValue(
      text: state.text,
      selection: newSelection,
    );

    _lastState = TextState(state.text, newSelection);
    _isUpdatingFromStack = false;
    notifyListeners();
  }

  void clearHistory() {
    _cancelDebounce();
    _changeStack.clearHistory();
    notifyListeners();
  }

  void setText(String text) {
    _cancelDebounce();
    _externalController.text = text;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _externalController.removeListener(_onTextChanged);
    super.dispose();
  }
}
