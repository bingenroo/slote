import 'package:flutter/material.dart';

enum FieldType { title, description }

class FieldAction {
  final FieldType type;
  final String oldValue;
  final String newValue;
  FieldAction(this.type, this.oldValue, this.newValue);
}

class MultiFieldUndoRedoController {
  final TextEditingController titleController;
  final TextEditingController descController;

  FieldAction? peekUndo() => _undoStack.isNotEmpty ? _undoStack.last : null;
  FieldAction? peekRedo() => _redoStack.isNotEmpty ? _redoStack.last : null;

  final List<FieldAction> _undoStack = [];
  final List<FieldAction> _redoStack = [];

  String _lastTitle = '';
  String _lastDesc = '';

  MultiFieldUndoRedoController(this.titleController, this.descController) {
    _lastTitle = titleController.text;
    _lastDesc = descController.text;
    titleController.addListener(_onTitleChanged);
    descController.addListener(_onDescChanged);
  }

  void _onTitleChanged() {
    if (_lastTitle != titleController.text) {
      _undoStack.add(
        FieldAction(FieldType.title, _lastTitle, titleController.text),
      );
      _redoStack.clear();
      _lastTitle = titleController.text;
    }
  }

  void _onDescChanged() {
    if (_lastDesc != descController.text) {
      _undoStack.add(
        FieldAction(FieldType.description, _lastDesc, descController.text),
      );
      _redoStack.clear();
      _lastDesc = descController.text;
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final action = _undoStack.removeLast();
      _redoStack.add(action); // <-- push as-is
      if (action.type == FieldType.title) {
        titleController.removeListener(_onTitleChanged);
        titleController.text = action.oldValue;
        _lastTitle = action.oldValue;
        titleController.addListener(_onTitleChanged);
      } else {
        descController.removeListener(_onDescChanged);
        descController.text = action.oldValue;
        _lastDesc = action.oldValue;
        descController.addListener(_onDescChanged);
      }
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final action = _redoStack.removeLast();
      _undoStack.add(action); // <-- push as-is
      if (action.type == FieldType.title) {
        titleController.removeListener(_onTitleChanged);
        titleController.text = action.newValue;
        _lastTitle = action.newValue;
        titleController.addListener(_onTitleChanged);
      } else {
        descController.removeListener(_onDescChanged);
        descController.text = action.newValue;
        _lastDesc = action.newValue;
        descController.addListener(_onDescChanged);
      }
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void dispose() {
    titleController.removeListener(_onTitleChanged);
    descController.removeListener(_onDescChanged);
  }
}
