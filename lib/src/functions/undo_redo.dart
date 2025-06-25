import 'package:flutter/material.dart';
import 'package:undo/undo.dart';

class TextState {
  final String text;
  final TextSelection selection;

  TextState(this.text, this.selection);
}

class UndoRedoTextController extends ChangeNotifier {
  final TextEditingController _externalController;
  final ChangeStack _changeStack;
  bool _isUpdatingFromStack = false;
  bool _isInitialState = true; // Add this flag
  TextState _lastState = TextState(
    '',
    const TextSelection.collapsed(offset: 0),
  );

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
      _changeStack.undo();
    }
  }

  void redo() {
    if (_changeStack.canRedo) {
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

    _changeStack.add(
      Change<TextState>(
        oldState,
        () => _updateTextFromStack(newState),
        (oldValue) => _updateTextFromStack(oldValue),
      ),
    );

    _lastState = newState;
    notifyListeners();
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
    _changeStack.clearHistory();
    notifyListeners();
  }

  void setText(String text) {
    _externalController.text = text;
  }

  @override
  void dispose() {
    _externalController.removeListener(_onTextChanged);
    super.dispose();
  }
}
