# Slote Rich Text Example

Standalone test app for the `slote_rich_text` component.

## Purpose

This example app allows you to test and debug the rich text editing functionality independently without running the full Slote app. It provides a focused environment for:

- Testing text input and editing
- Testing format toolbar functionality
- Testing text formatting (bold, italic, underline)
- Testing text selection
- Debugging text editor behavior

## Running the Example

```bash
cd slote_components/slote_rich_text/example
flutter pub get
flutter run
```

## Features

- **Text Editor**: Multi-line text input with rich text support
- **Format Toolbar**: Buttons for bold, italic, and underline formatting
- **Text Selection**: Select text and apply formatting
- **Character/Word Count**: Real-time text statistics
- **Clear Button**: Clear all text content

## Testing Tips

1. Test text input with various lengths
2. Test text selection and formatting application
3. Test format toolbar button states
4. Test multiple format combinations (bold + italic, etc.)
5. Test text persistence and restoration
6. Monitor performance with large text content
