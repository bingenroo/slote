import 'package:flutter/material.dart';
import 'package:undo/undo.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'dart:async';

enum ActionType { text, drawing }

class TextState {
  final String text;
  final TextSelection selection;

  TextState(this.text, this.selection);
}

class UnifiedAction {
  final ActionType type;
  final dynamic oldState;
  final dynamic newState;

  UnifiedAction({
    required this.type,
    required this.oldState,
    required this.newState,
  });
}

class UnifiedUndoRedoController extends ChangeNotifier {
  final TextEditingController _textController;
  final DrawingController _drawingController;
  final ChangeStack _changeStack;

  bool _isUpdatingFromStack = false;
  bool _isInitialState = true;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  TextState _lastTextState = TextState(
    '',
    const TextSelection.collapsed(offset: 0),
  );
  List<dynamic> _lastDrawingState = [];

  TextState? _pendingTextState;
  List<dynamic>? _pendingDrawingState;

  UnifiedUndoRedoController(
    this._changeStack,
    this._textController,
    this._drawingController,
  ) {
    _textController.addListener(_onTextChanged);
    _drawingController.addListener(_onDrawingChanged);

    // Initialize with current states
    _lastTextState = TextState(_textController.text, _textController.selection);
    _lastDrawingState = List.from(_drawingController.getJsonList());
  }

  void initializeWithCurrentState() {
    _lastTextState = TextState(_textController.text, _textController.selection);
    _lastDrawingState = List.from(_drawingController.getJsonList());
    _isInitialState = false;
  }

  TextEditingController get textController => _textController;
  DrawingController get drawingController => _drawingController;
  bool get canUndo => _changeStack.canUndo;
  bool get canRedo => _changeStack.canRedo;

  void undo() {
    if (_changeStack.canUndo) {
      _cancelDebounce();
      _changeStack.undo();
      notifyListeners(); // Add this to update UI
    }
  }

  void redo() {
    if (_changeStack.canRedo) {
      _cancelDebounce();
      _changeStack.redo();
      notifyListeners(); // Add this to update UI
    }
  }

  void _onTextChanged() {
    if (_isUpdatingFromStack) return;

    final newText = _textController.text;
    final newSelection = _textController.selection;
    final oldState = _lastTextState;

    // Skip adding to stack if this is the initial state setup
    if (_isInitialState) {
      _lastTextState = TextState(newText, newSelection);
      _isInitialState = false;
      return;
    }

    // Skip if text hasn't actually changed
    if (oldState.text == newText) {
      _lastTextState = TextState(newText, newSelection);
      return;
    }

    // Capture selection at the current cursor position
    final capturedSelection =
        newSelection.isValid
            ? newSelection
            : TextSelection.collapsed(offset: newText.length);

    final newState = TextState(newText, capturedSelection);
    _pendingTextState = newState;

    _startDebounceTimer();
  }

  void _onDrawingChanged() {
    if (_isUpdatingFromStack) return;

    final newDrawingData = _drawingController.getJsonList();
    final oldDrawingData = _lastDrawingState;

    // Skip if drawing hasn't actually changed
    if (_areDrawingStatesEqual(oldDrawingData, newDrawingData)) {
      return;
    }

    _pendingDrawingState = List.from(newDrawingData);
    _startDebounceTimer();
  }

  void _startDebounceTimer() {
    // Cancel existing timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _addPendingChangesToStack();
    });
  }

  void _addPendingChangesToStack() {
    // Handle text changes
    if (_pendingTextState != null) {
      final oldTextState = _lastTextState;
      final newTextState = _pendingTextState!;

      _changeStack.add(
        Change<UnifiedAction>(
          UnifiedAction(
            type: ActionType.text,
            oldState: oldTextState,
            newState: newTextState,
          ),
          () => _restoreTextState(newTextState),
          (action) => _restoreTextState(action.oldState as TextState),
        ),
      );

      _lastTextState = newTextState;
      _pendingTextState = null;
    }

    // Handle drawing changes
    if (_pendingDrawingState != null) {
      final oldDrawingState = _lastDrawingState;
      final newDrawingState = _pendingDrawingState!;

      _changeStack.add(
        Change<UnifiedAction>(
          UnifiedAction(
            type: ActionType.drawing,
            oldState: List.from(oldDrawingState),
            newState: List.from(newDrawingState),
          ),
          () => _restoreDrawingState(newDrawingState),
          (action) => _restoreDrawingState(action.oldState as List<dynamic>),
        ),
      );

      _lastDrawingState = List.from(newDrawingState);
      _pendingDrawingState = null;
    }

    notifyListeners();
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // If there are pending changes, add them immediately
    if (_pendingTextState != null || _pendingDrawingState != null) {
      _addPendingChangesToStack();
    }
  }

  void _restoreTextState(TextState state) {
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

    _textController.value = TextEditingValue(
      text: state.text,
      selection: newSelection,
    );

    _lastTextState = TextState(state.text, newSelection);
    _isUpdatingFromStack = false;
  }

  void _restoreDrawingState(List<dynamic> drawingData) {
    _isUpdatingFromStack = true;

    // Clear current drawing
    _drawingController.clear();

    // Restore drawing data if not empty
    if (drawingData.isNotEmpty) {
      // Convert JSON data back to PaintContent objects
      final List<PaintContent> contents = _convertJsonToContents(drawingData);
      if (contents.isNotEmpty) {
        _drawingController.addContents(contents);
      }
    }

    _lastDrawingState = List.from(drawingData);
    _isUpdatingFromStack = false;
  }

  List<PaintContent> _convertJsonToContents(List<dynamic> jsonData) {
    final List<PaintContent> contents = [];

    for (final dynamic item in jsonData) {
      if (item is Map<String, dynamic>) {
        final String type = item['type'] as String? ?? '';

        try {
          switch (type) {
            case 'StraightLine':
              contents.add(StraightLine.fromJson(item));
              break;
            case 'SimpleLine':
              contents.add(SimpleLine.fromJson(item));
              break;
            case 'Rectangle':
              contents.add(Rectangle.fromJson(item));
              break;
            case 'Circle':
              contents.add(Circle.fromJson(item));
              break;
            case 'Eraser':
              contents.add(Eraser.fromJson(item));
              break;
            default:
              // Skip unknown types
              break;
          }
        } catch (e) {
          // Skip invalid content items
          continue;
        }
      }
    }

    return contents;
  }

  bool _areDrawingStatesEqual(List<dynamic> state1, List<dynamic> state2) {
    if (state1.length != state2.length) return false;

    for (int i = 0; i < state1.length; i++) {
      if (state1[i].toString() != state2[i].toString()) {
        return false;
      }
    }
    return true;
  }

  void clearHistory() {
    _cancelDebounce();
    _changeStack.clearHistory();
    notifyListeners();
  }

  void setText(String text) {
    _cancelDebounce();
    _textController.text = text;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _drawingController.removeListener(_onDrawingChanged);
    super.dispose();
  }
}
