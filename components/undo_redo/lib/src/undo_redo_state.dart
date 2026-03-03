/// Generic state for undo/redo system
abstract class UndoRedoState {
  /// Creates a copy of this state with the given fields replaced
  UndoRedoState copyWith();

  /// Checks if this state is equal to another
  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

/// Text state for undo/redo
class TextState extends UndoRedoState {
  final String text;
  final int selectionStart;
  final int selectionEnd;

  TextState({
    required this.text,
    this.selectionStart = 0,
    this.selectionEnd = 0,
  });

  @override
  TextState copyWith({
    String? text,
    int? selectionStart,
    int? selectionEnd,
  }) {
    return TextState(
      text: text ?? this.text,
      selectionStart: selectionStart ?? this.selectionStart,
      selectionEnd: selectionEnd ?? this.selectionEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextState &&
        other.text == text &&
        other.selectionStart == selectionStart &&
        other.selectionEnd == selectionEnd;
  }

  @override
  int get hashCode => Object.hash(text, selectionStart, selectionEnd);
}

