import 'package:flutter/material.dart';
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
        _sketchesEqual(other.scribbleSketch, scribbleSketch);
  }

  bool _sketchesEqual(Sketch a, Sketch b) {
    try {
      final aJson = a.toJson();
      final bJson = b.toJson();
      return aJson.toString() == bJson.toString();
    } catch (e) {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(text, textSelection, scribbleSketch);
}

class UnifiedUndoRedoController extends ChangeNotifier {
  final TextEditingController _textController;
  final ScribbleNotifier _scribbleNotifier;

  final List<NoteState> _history = [];
  int _currentIndex = -1;
  bool _isUpdatingFromHistory = false;
  bool _isInitialState = true;

  static const int _maxHistoryLength = 50;

  UnifiedUndoRedoController({
    required TextEditingController textController,
    required ScribbleNotifier scribbleNotifier,
  }) : _textController = textController,
       _scribbleNotifier = scribbleNotifier {
    // Add listeners
    _textController.addListener(_onTextChanged);
    _scribbleNotifier.addListener(_onDrawingChanged);
  }

  TextEditingController get textController => _textController;
  ScribbleNotifier get scribbleNotifier => _scribbleNotifier;

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  void initializeWithCurrentState() {
    final currentState = NoteState(
      text: _textController.text,
      textSelection: _textController.selection,
      scribbleSketch: _scribbleNotifier.currentSketch,
    );

    // Set initial state
    _history.clear();
    _history.add(currentState);
    _currentIndex = 0;
    _isInitialState = false;
    notifyListeners();
  }

  void _onTextChanged() {
    if (_isUpdatingFromHistory) return;

    final newText = _textController.text;
    final newSelection = _textController.selection;
    final currentState = _getCurrentState();

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

    _addToHistory(newState);
  }

  void _onDrawingChanged() {
    if (_isUpdatingFromHistory) return;

    final newScribbleSketch = _scribbleNotifier.currentSketch;
    final currentState = _getCurrentState();

    // Skip if drawing hasn't actually changed
    if (_sketchesEqual(currentState.scribbleSketch, newScribbleSketch)) {
      return;
    }

    final newState = currentState.copyWith(scribbleSketch: newScribbleSketch);
    _addToHistory(newState);
  }

  bool _sketchesEqual(Sketch a, Sketch b) {
    try {
      final aJson = a.toJson();
      final bJson = b.toJson();
      return aJson.toString() == bJson.toString();
    } catch (e) {
      return false;
    }
  }

  NoteState _getCurrentState() {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return NoteState(
      text: _textController.text,
      textSelection: _textController.selection,
      scribbleSketch: _scribbleNotifier.currentSketch,
    );
  }

  void _addToHistory(NoteState newState) {
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

  void undo() {
    if (!canUndo) return;

    _currentIndex--;
    _restoreState(_history[_currentIndex]);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    _currentIndex++;
    _restoreState(_history[_currentIndex]);
    notifyListeners();
  }

  void _restoreState(NoteState state) {
    _isUpdatingFromHistory = true;

    // Update text controller
    final textLength = state.text.length;
    final restoredSelection = state.textSelection;

    // Ensure we don't go beyond text bounds
    final safeStart = restoredSelection.start.clamp(0, textLength);
    final safeEnd = restoredSelection.end.clamp(safeStart, textLength);

    final newSelection = TextSelection(
      baseOffset: safeStart,
      extentOffset: safeEnd,
    );

    _textController.value = TextEditingValue(
      text: state.text,
      selection: newSelection,
    );

    // Update drawing by restoring the sketch
    _scribbleNotifier.setSketch(
      sketch: state.scribbleSketch,
      addToUndoHistory: false,
    );

    _isUpdatingFromHistory = false;
  }

  void clearHistory() {
    final currentState = _getCurrentState();
    _history.clear();
    _history.add(currentState);
    _currentIndex = 0;
    notifyListeners();
  }

  void setText(String text) {
    final newState = _getCurrentState().copyWith(
      text: text,
      textSelection: TextSelection.collapsed(offset: text.length),
    );

    _isUpdatingFromHistory = true;
    _textController.text = text;
    _isUpdatingFromHistory = false;

    // Update current state without adding to history
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      _history[_currentIndex] = newState;
    }
  }

  void clearDrawing() {
    final newState = _getCurrentState().copyWith(
      scribbleSketch: _scribbleNotifier.currentSketch,
    );

    _isUpdatingFromHistory = true;
    _scribbleNotifier.clear();
    _isUpdatingFromHistory = false;

    // Update current state without adding to history
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      _history[_currentIndex] = newState;
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scribbleNotifier.removeListener(_onDrawingChanged);
    super.dispose();
  }
}
