# Undo/redo example

Example app for the `undo_redo` component.

## Purpose

Run and debug undo/redo without the full Slote app:

- Undo and redo with text editing
- Can undo/redo state
- History clear
- State indicators

## Run

```bash
cd components/undo_redo/example
flutter pub get
flutter run
```

**If you see "No supported devices connected":** the example may not have platform folders (android, macos, web, etc.). Add them with:

```bash
flutter create .
```

Then run on a specific device, e.g.:

```bash
flutter run -d chrome
# or: flutter run -d macos
# or: flutter run -d <device-id>   # from flutter devices
```

**Hot reload:** With the app running, press **`r`** in the same terminal for hot reload, **`R`** for hot restart. Keep that terminal in the foreground so you can use `r`/`R` after code changes.

## Features

- **Text editor**: Multi-line input
- **Undo / redo / clear history** buttons
- **State indicators**: Can undo/redo and text length

## Tips

1. Type, then undo and redo
2. Check button enabled/disabled state
3. Use clear history and continue editing
