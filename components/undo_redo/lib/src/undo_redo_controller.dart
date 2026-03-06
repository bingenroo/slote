import 'package:flutter/material.dart';
import 'undo_redo_state.dart';

/// Generic undo/redo controller that works with any state type
class UndoRedoController<T extends UndoRedoState> extends ChangeNotifier {
  final List<T> _history = [];
  int _currentIndex = -1;
  bool _isUpdatingFromHistory = false;
  bool _isInitialState = true;

  static const int _maxHistoryLength = 50;

  /// Callback to get current state
  final T Function() _getCurrentState;

  /// Callback to restore a state
  final void Function(T state) _restoreState;

  /// Callback to check if state has changed
  final bool Function(T a, T b)? _stateEquals;

  UndoRedoController({
    required T Function() getCurrentState,
    required void Function(T state) restoreState,
    bool Function(T a, T b)? stateEquals,
  })  : _getCurrentState = getCurrentState,
        _restoreState = restoreState,
        _stateEquals = stateEquals;

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  /// Initialize with current state
  void initializeWithCurrentState() {
    final currentState = _getCurrentState();

    _history.clear();
    _history.add(currentState);
    _currentIndex = 0;
    _isInitialState = false;
    notifyListeners();
  }

  /// Add a new state to history
  void addState(T newState) {
    if (_isUpdatingFromHistory) return;

    if (_isInitialState) {
      _isInitialState = false;
      return;
    }

    // Compare against the state we're currently at in history (the previous state),
    // not getCurrentState(), since the listener fires after the source already updated.
    final previousState = _currentIndex >= 0 && _currentIndex < _history.length
        ? _history[_currentIndex]
        : _getCurrentState();

    if (_stateEquals != null) {
      if (_stateEquals!(previousState, newState)) {
        return;
      }
    } else if (previousState == newState) {
      return;
    }

    _addToHistory(newState);
  }

  T _getCurrentStateFromHistory() {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return _getCurrentState();
  }

  void _addToHistory(T newState) {
    // Remove any states after current index (when we're not at the end)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(newState);
    _currentIndex++;

    // Limit history length
    if (_history.length > _maxHistoryLength) {
      _history.removeAt(0);
      _currentIndex--;
    }

    notifyListeners();
  }

  /// Undo to previous state
  void undo() {
    if (!canUndo) return;

    _currentIndex--;
    try {
      _isUpdatingFromHistory = true;
      _restoreState(_history[_currentIndex]);
    } finally {
      _isUpdatingFromHistory = false;
    }
    notifyListeners();
  }

  /// Redo to next state
  void redo() {
    if (!canRedo) return;

    _currentIndex++;
    try {
      _isUpdatingFromHistory = true;
      _restoreState(_history[_currentIndex]);
    } finally {
      _isUpdatingFromHistory = false;
    }
    notifyListeners();
  }

  /// Clear history
  void clearHistory() {
    final currentState = _getCurrentStateFromHistory();
    _history.clear();
    _history.add(currentState);
    _currentIndex = 0;
    notifyListeners();
  }

  /// Get current history index
  int get currentIndex => _currentIndex;

  /// Get history length
  int get historyLength => _history.length;
}

/// Text-specific undo/redo controller
class TextUndoRedoController extends ChangeNotifier {
  final TextEditingController _textController;
  final UndoRedoController<TextState> _undoRedoController;

  TextUndoRedoController({
    required TextEditingController textController,
  })  : _textController = textController,
        _undoRedoController = UndoRedoController<TextState>(
          getCurrentState: () {
            final selection = textController.selection;
            return TextState(
              text: textController.text,
              selectionStart: selection.start,
              selectionEnd: selection.end,
            );
          },
          restoreState: (state) {
            final textLength = state.text.length;
            final safeStart = state.selectionStart.clamp(0, textLength);
            final safeEnd = state.selectionEnd.clamp(safeStart, textLength);

            textController.value = TextEditingValue(
              text: state.text,
              selection: TextSelection(
                baseOffset: safeStart,
                extentOffset: safeEnd,
              ),
            );
          },
        ) {
    _textController.addListener(_onTextChanged);
    _undoRedoController.addListener(notifyListeners);
  }

  TextEditingController get textController => _textController;

  bool get canUndo => _undoRedoController.canUndo;
  bool get canRedo => _undoRedoController.canRedo;

  void initializeWithCurrentState() {
    _undoRedoController.initializeWithCurrentState();
  }

  void _onTextChanged() {
    final selection = _textController.selection;
    final newState = TextState(
      text: _textController.text,
      selectionStart: selection.start,
      selectionEnd: selection.end,
    );
    _undoRedoController.addState(newState);
  }

  void undo() {
    _undoRedoController.undo();
  }

  void redo() {
    _undoRedoController.redo();
  }

  void clearHistory() {
    _undoRedoController.clearHistory();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _undoRedoController.dispose();
    super.dispose();
  }
}

/// Unified undo/redo controller that handles both text and drawing (scribble)
/// This is a temporary implementation that wraps TextUndoRedoController
/// TODO: Replace with proper implementation when scribble is migrated to slote_draw
class UnifiedUndoRedoController extends ChangeNotifier {
  final TextUndoRedoController _textController;
  // TODO: Add drawing controller when slote_draw is integrated

  UnifiedUndoRedoController({
    required TextEditingController textController,
    // ignore: unused_element
    dynamic scribbleNotifier, // Accept but ignore for now
  }) : _textController = TextUndoRedoController(textController: textController) {
    _textController.addListener(notifyListeners);
  }

  bool get canUndo => _textController.canUndo;
  bool get canRedo => _textController.canRedo;

  void initializeWithCurrentState() {
    _textController.initializeWithCurrentState();
  }

  void undo() {
    _textController.undo();
  }

  void redo() {
    _textController.redo();
  }

  @override
  void dispose() {
    _textController.removeListener(notifyListeners);
    _textController.dispose();
    super.dispose();
  }
}

