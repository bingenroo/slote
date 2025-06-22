import 'package:flutter/material.dart';

enum FieldType { title, description }

class FieldAction {
  final FieldType type;
  final String oldValue;
  final String newValue;
  FieldAction(this.type, this.oldValue, this.newValue);
}

// Change here: extend ChangeNotifier
class MultiFieldUndoRedoController extends ChangeNotifier {
  final TextEditingController titleController;
  final TextEditingController descController;

  FieldAction? peekUndo() => _undoStack.isNotEmpty ? _undoStack.last : null;
  FieldAction? peekRedo() => _redoStack.isNotEmpty ? _redoStack.last : null;

  final List<FieldAction> _undoStack = [];
  final List<FieldAction> _redoStack = [];

  String _lastTitle = '';
  String _lastDesc = '';

  bool _skipNextTitleChange = false;
  bool _skipNextDescChange = false;

  MultiFieldUndoRedoController(this.titleController, this.descController) {
    _lastTitle = titleController.text;
    _lastDesc = descController.text;
    titleController.addListener(_onTitleChanged);
    descController.addListener(_onDescChanged);
  }

  void _onTitleChanged() {
    final newText = titleController.text;
    if (_skipNextTitleChange) {
      _skipNextTitleChange = false;
      _lastTitle = newText;
      return;
    }

    if (_lastTitle != newText) {
      _undoStack.add(FieldAction(FieldType.title, _lastTitle, newText));
      _redoStack.clear();
      _lastTitle = newText;
      notifyListeners();
    }
  }

  void _onDescChanged() {
    final newText = descController.text;
    if (_skipNextDescChange) {
      _skipNextDescChange = false;
      _lastDesc = newText;
      return;
    }

    if (_lastDesc != newText) {
      _undoStack.add(FieldAction(FieldType.description, _lastDesc, newText));
      _redoStack.clear();
      _lastDesc = newText;
      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final action = _undoStack.removeLast();
      _redoStack.add(action);
      if (action.type == FieldType.title) {
        _skipNextTitleChange = true;
        titleController.text = action.oldValue;
      } else {
        _skipNextDescChange = true;
        descController.text = action.oldValue;
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final action = _redoStack.removeLast();
      _undoStack.add(action);
      if (action.type == FieldType.title) {
        _skipNextTitleChange = true;
        titleController.text = action.newValue;
      } else {
        _skipNextDescChange = true;
        descController.text = action.newValue;
      }
      notifyListeners();
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void dispose() {
    titleController.removeListener(_onTitleChanged);
    descController.removeListener(_onDescChanged);
    super.dispose(); // Call super.dispose() for ChangeNotifier
  }
}
