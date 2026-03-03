# Component Test Platforms Documentation

## Overview

This document describes the standalone test platforms created for each component in `components/`. These test apps enable independent development and debugging of components without needing to run the full Slote application.

## Purpose

Previously, testing components required running the entire main app (at repo root), which included:

- Unnecessary code and dependencies
- Slower startup times
- More complex debugging environments
- Difficulty isolating component-specific issues

The new test platforms provide:

- **Faster Development**: Test components in isolation
- **Focused Debugging**: Only the component being developed is active
- **Independent Testing**: Each component can be tested on any platform independently
- **Standard Pattern**: Follows Flutter package conventions (test/ directories)
- **Easy Onboarding**: New developers can test components without understanding the full app

## Architecture

Each component has a `test/` directory containing:

- `lib/main.dart` - Entry point for the test app
- `lib/test_[component]_screen.dart` - Main test screen widget
- `pubspec.yaml` - Minimal dependencies (only Flutter SDK and parent component)
- `README.md` - Component-specific usage instructions

### File Structure

```
components/
  draw/
    test/
      lib/
        main.dart
        test_draw_screen.dart
      pubspec.yaml
      README.md
    lib/                    # Component code

  rich_text/
    test/
      lib/
        main.dart
        test_rich_text_screen.dart
      pubspec.yaml
      README.md
    lib/

  viewport/
    test/
      lib/
        main.dart
        test_viewport_screen.dart
      pubspec.yaml
      README.md
    lib/

  undo_redo/
    test/
      lib/
        main.dart
        test_undo_redo_screen.dart
      pubspec.yaml
      README.md
    lib/
```

## Component Test Platforms

### 1. slote_draw Test Platform

**Location**: `components/draw/test/`

**Features Tested**:

- Drawing with pen tool
- Color selection (8 predefined colors)
- Stroke width adjustment (1px - 20px)
- Eraser tool
- Highlighter tool
- Clear canvas functionality
- Drawing mode toggle
- Stroke rendering and persistence

**UI Components**:

- Canvas area for drawing
- Tool selector (pen, highlighter, eraser)
- Color picker with visual swatches
- Stroke width slider
- Clear button
- Status bar with stroke count and tool info

**Running**:

```bash
cd components/draw/test
flutter pub get
flutter run
```

### 2. slote_rich_text Test Platform

**Location**: `components/rich_text/test/`

**Features Tested**:

- Text input and editing
- Format toolbar functionality
- Bold formatting
- Italic formatting
- Underline formatting
- Text selection
- Format persistence

**UI Components**:

- Multi-line text editor
- Format toolbar with bold/italic/underline buttons
- Visual feedback for active formats
- Text statistics (characters, words, selection)
- Clear button

**Running**:

```bash
cd components/rich_text/test
flutter pub get
flutter run
```

### 3. slote_viewport Test Platform

**Location**: `components/viewport/test/`

**Features Tested**:

- Zoom in/out (pinch gestures and buttons)
- Pan/drag functionality
- Scroll behavior
- Boundary constraints
- Scrollbar visibility
- Transform callbacks
- Content height measurement
- Viewport height measurement
- Drawing mode vs view mode switching

**UI Components**:

- Viewport surface with test content
- Zoom controls (in/out buttons)
- Content height adjustment controls
- Scale indicator
- Drawing mode toggle
- Info bar with viewport/content/scale stats

**Running**:

```bash
cd components/viewport/test
flutter pub get
flutter run
```

### 4. slote_undo_redo Test Platform

**Location**: `components/undo_redo/test/`

**Features Tested**:

- Undo operations
- Redo operations
- State management
- History tracking
- Can undo/redo state detection
- Text editing integration
- History clearing

**UI Components**:

- Multi-line text editor
- Undo button (enabled/disabled based on state)
- Redo button (enabled/disabled based on state)
- Clear history button
- State indicators (can undo/redo status)
- Info bar with text length

**Running**:

```bash
cd components/undo_redo/test
flutter pub get
flutter run
```

## Development Workflow

### Testing a Component

1. Navigate to the component's test directory:

   ```bash
   cd components/[component_name]/test
   ```

2. Get dependencies:

   ```bash
   flutter pub get
   ```

3. Run the test app:

   ```bash
   flutter run
   ```

4. Make changes to the component code in `../lib/`

5. Hot reload will automatically pick up changes (if using hot reload)

### Making Changes to Components

When modifying component code:

1. Edit files in `components/[component_name]/lib/`
2. The test app will automatically use the updated code (path dependency)
3. Hot reload or restart the test app to see changes

### Adding New Test Features

To add new test features to a test app:

1. Edit the test screen file: `lib/test_[component]_screen.dart`
2. Add UI controls or test scenarios as needed
3. Keep the test focused on the component being tested

## Integration Testing

**Important**: These test platforms are for **component-level testing only**.

Integration testing (e.g., drawing + text overlay, component interactions) should still be done in the main app (repo root) where all components are combined. The test platforms focus on individual component functionality.

## Benefits Achieved

1. **Decentralized Development**: Each component can be developed and tested independently
2. **Faster Iteration**: No need to navigate through the full app to test component changes
3. **Focused Debugging**: Only the relevant component code is active during testing
4. **Standard Pattern**: Follows Flutter package conventions (test/ directories)
5. **Better Onboarding**: New developers can understand and test components without learning the entire app architecture

## Implementation Details

### Dependencies

Each test app has minimal dependencies:

- Flutter SDK
- Parent component (via path dependency: `path: ../`)
- Flutter test and lints (dev dependencies only)

### Example pubspec.yaml Structure

```yaml
name: slote_[component]_test
description: Test app for slote_[component] component
publish_to: "none"

version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter
  slote_[component]:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

### Main.dart Structure

Each test app follows a simple structure:

```dart
import 'package:flutter/material.dart';
import 'test_[component]_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slote [Component] Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Test[Component]Screen(),
    );
  }
}
```

## Verification

All test platforms have been verified to:

- ✅ Compile successfully (`flutter analyze` passes)
- ✅ Resolve dependencies correctly (`flutter pub get` succeeds)
- ✅ Be self-contained and runnable independently
- ✅ Follow Flutter package conventions

## Future Enhancements

Potential improvements:

- Add automated widget tests for each component
- Create a unified test runner that can launch any component test
- Add performance profiling tools to test platforms
- Add screenshot testing capabilities
- Create integration test scenarios that combine multiple components

## Related Documentation

- Individual component READMEs in each `test/` directory
- Main repository README: `/README.md`
- Component development guide: `docs/CONCURRENT_DEVELOPMENT_GUIDE.md`

## Implementation Date

January 2025

## Implementation Summary

This implementation successfully created standalone test platforms for all major components:

- `slote_draw` - Drawing functionality testing
- `slote_rich_text` - Text editing and formatting testing
- `slote_viewport` - Zoom/pan/viewport testing
- `slote_undo_redo` - Undo/redo system testing

All platforms are functional, verified, and ready for use in component development workflows.
