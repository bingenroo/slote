# Real-Time Updates Architecture

## Overview

This document explains how real-time updates work in Slote, ensuring that when notes are saved, created, or deleted, the home view immediately reflects these changes without requiring an app restart.

## Problem Statement

Previously, when a note was saved in `CreateNoteView`, the home view would not update automatically. Users had to restart the app (via `flutter run`) to see newly created or updated notes. This was due to multiple instances of `LocalDBService` being created, each with its own isolated stream controller.

## Root Cause

The issue occurred because:

1. **Multiple Service Instances**: Different parts of the app were creating separate instances of `LocalDBService`:
   - `HomeView` created one instance for listening to notes
   - `CreateNoteView` created another instance for saving notes
   - `CreateNoteViewZoomPan` created yet another instance

2. **Isolated Stream Controllers**: Each instance had its own `StreamController<List<Note>>`, so when a note was saved in one instance, it only notified its own listeners, not the listeners from other instances.

3. **No Shared State**: Without a shared service instance, there was no way for the save operation to notify the home view's stream.

## Solution: Singleton Pattern

The solution implements the **Singleton Pattern** for `LocalDBService` to ensure all parts of the app use the same instance and share the same stream controller.

### Implementation

```dart
class LocalDBService {
  // Singleton instance
  static LocalDBService? _instance;
  
  // Factory constructor to return the singleton instance
  factory LocalDBService() {
    _instance ??= LocalDBService._internal();
    return _instance!;
  }
  
  // Private constructor for singleton
  LocalDBService._internal();
  
  // Shared stream controller (all instances use the same one)
  final StreamController<List<Note>> _notesController = 
      StreamController<List<Note>>.broadcast();
  
  // ... rest of the implementation
}
```

### Key Changes

1. **Singleton Instance**: A static `_instance` variable stores the single shared instance
2. **Factory Constructor**: The public constructor always returns the same instance
3. **Private Constructor**: `_internal()` prevents direct instantiation
4. **Shared Stream Controller**: All parts of the app now listen to and emit events on the same stream controller

## How It Works

### Stream Architecture

```
┌─────────────────┐
│  LocalDBService │ (Singleton)
│   (Shared)      │
└────────┬────────┘
         │
         ├─── StreamController (Broadcast)
         │    └─── Listens to all note changes
         │
         ├─── HomeView
         │    └─── StreamBuilder listens to stream
         │
         ├─── CreateNoteView
         │    └─── Saves note → notifies stream
         │
         └─── CreateNoteViewZoomPan
              └─── Saves note → notifies stream
```

### Update Flow

1. **User saves a note** in `CreateNoteView` or `CreateNoteViewZoomPan`
2. **`saveNote()` is called** on the shared `LocalDBService` instance
3. **Note is saved** to the SQLite database
4. **`_notifyListeners()` is called**, which:
   - Fetches all notes from the database
   - Adds the updated list to the shared `_notesController`
5. **Stream emits new data** to all active listeners
6. **HomeView's StreamBuilder** receives the update and rebuilds with the new note list

### Code Flow Example

```dart
// In CreateNoteView
final localDb = LocalDBService(); // Returns singleton instance
await localDb.saveNote(note: newNote); // Saves and notifies

// In HomeView
final _dbService = LocalDBService(); // Returns same singleton instance
StreamBuilder(
  stream: _dbService.listenAllNotes(), // Listens to shared stream
  builder: (context, snapshot) {
    // Automatically rebuilds when stream emits new data
  },
)
```

## Benefits

1. **Real-Time Updates**: Notes appear immediately in the home view after saving
2. **Consistent State**: All parts of the app see the same data
3. **Efficient**: Single database connection and stream controller
4. **Memory Efficient**: Only one service instance exists in memory

## Best Practices

### In HomeView

Cache the service instance and stream in the state:

```dart
class _HomeViewState extends State<HomeView> {
  // Cache the service instance and stream
  late final LocalDBService _dbService = LocalDBService();
  late final Stream<List<Note>> _notesStream = _dbService.listenAllNotes();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: _notesStream, // Use cached stream
      // ...
    );
  }
}
```

### In CreateNoteView

Use the service instance directly:

```dart
class _CreateNoteViewState extends State<CreateNoteView> {
  final localDb = LocalDBService(); // Gets singleton instance
  
  void _saveNoteData() async {
    await localDb.saveNote(note: newNote); // Automatically notifies all listeners
  }
}
```

## Testing

To verify real-time updates are working:

1. **Create a new note**: 
   - Open the app
   - Tap the FAB to create a new note
   - Add title and content
   - Navigate back
   - ✅ The note should appear immediately in the home view

2. **Update an existing note**:
   - Open a note from the home view
   - Modify the title or content
   - Navigate back
   - ✅ The home view should show the updated note immediately

3. **Delete a note**:
   - Long-press a note to enter selection mode
   - Select and delete a note
   - ✅ The note should disappear immediately from the home view

## Troubleshooting

### Notes still not updating?

1. **Check singleton implementation**: Ensure `LocalDBService` uses the factory constructor pattern
2. **Verify stream subscription**: Check that `HomeView` is using `StreamBuilder` with the correct stream
3. **Check for errors**: Look for database errors in the console that might prevent `_notifyListeners()` from being called
4. **Verify broadcast stream**: Ensure `StreamController` is created with `.broadcast()` to support multiple listeners

### Performance issues?

- The singleton pattern ensures only one database connection
- Stream updates are efficient as they only fetch data when changes occur
- Consider implementing pagination if you have a large number of notes

## Related Files

- `lib/src/services/local_db.dart` - Singleton service implementation
- `lib/src/views/home.dart` - Home view with StreamBuilder
- `lib/src/views/create_note.dart` - Note creation view
- `lib/src/views/create_note_zoompan.dart` - Alternative note creation view

## Future Improvements

Potential enhancements to consider:

1. **Stream Debouncing**: Add debouncing to prevent excessive database queries during rapid updates
2. **Selective Updates**: Only fetch and emit changed notes instead of the entire list
3. **Optimistic Updates**: Update UI immediately before database confirmation
4. **Error Recovery**: Implement retry logic for failed database operations
5. **Background Sync**: Support syncing changes when the app comes to foreground
