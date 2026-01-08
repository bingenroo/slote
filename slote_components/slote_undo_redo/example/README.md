# Slote Undo/Redo Example

Standalone test app for the `slote_undo_redo` component.

## Purpose

This example app allows you to test and debug the undo/redo functionality independently without running the full Slote app. It provides a focused environment for:

- Testing undo operations
- Testing redo operations
- Testing state management
- Testing history tracking
- Testing can undo/redo state
- Testing text editing integration

## Running the Example

```bash
cd slote_components/slote_undo_redo/example
flutter pub get
flutter run
```

## Features

- **Text Editor**: Multi-line text input for testing undo/redo
- **Undo Button**: Undo the last change (disabled when no history)
- **Redo Button**: Redo the last undone change (disabled when nothing to redo)
- **Clear History Button**: Clear the undo/redo history
- **State Indicators**: Visual feedback for can undo/redo states
- **Info Bar**: Real-time state information

## Testing Tips

1. Type some text and test undo to revert changes
2. Test redo after undoing
3. Test multiple undo/redo operations
4. Test that undo/redo buttons are properly enabled/disabled
5. Test text selection preservation during undo/redo
6. Test clear history functionality
7. Test rapid typing and undo/redo behavior
8. Monitor state consistency during operations
