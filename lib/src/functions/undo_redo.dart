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
    if (oldState.text == newText) return;

    final newState = TextState(newText, newSelection);
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
    _externalController.text = state.text;

    // Use a post-frame callback to ensure the text is set before setting selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isUpdatingFromStack) return; // Safety check

      final textLength = _externalController.text.length;
      final selection = state.selection;

      // Ensure the selection is within bounds
      final safeStart = selection.start.clamp(0, textLength);
      final safeEnd = selection.end.clamp(0, textLength);

      _externalController.selection = TextSelection(
        baseOffset: safeStart,
        extentOffset: safeEnd,
      );
    });

    _lastState = state;
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
