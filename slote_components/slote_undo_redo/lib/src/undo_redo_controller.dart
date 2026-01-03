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

    final currentState = _getCurrentState();

    // Check if state has changed
    if (_stateEquals != null) {
      if (_stateEquals!(currentState, newState)) {
        return;
      }
    } else if (currentState == newState) {
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
    _restoreState(_history[_currentIndex]);
    notifyListeners();
  }

  /// Redo to next state
  void redo() {
    if (!canRedo) return;

    _currentIndex++;
    _restoreState(_history[_currentIndex]);
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

