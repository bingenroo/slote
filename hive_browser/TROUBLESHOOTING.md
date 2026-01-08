# Troubleshooting Guide

## Issue: Electron Window Not Showing / electronAPI Undefined

### Symptoms

- Electron app starts but window is not visible
- `TypeError: Cannot read properties of undefined (reading 'getDatabaseInfo')` in renderer
- `window.electronAPI` is undefined in React components
- Preload script appears to execute (logs show ping received) but API is not accessible

### Root Cause

The development mode check in `main.ts` was using a strict equality check:

```typescript
if (process.env.NODE_ENV === 'development') {
  // Load from Vite dev server
}
```

However, `NODE_ENV` was not being set in the npm scripts, so it was `undefined`. This caused the condition to fail, preventing the app from loading the React app from the Vite dev server (`http://localhost:3000`). As a result:

1. The window was created but never shown (it was set to `show: false` and only shown on `dom-ready`, which never fired)
2. The preload script executed successfully, but the renderer never loaded, so `window.electronAPI` was never accessible

### Solution

Changed the environment check to default to development mode when `NODE_ENV` is not explicitly set to `'production'`:

```typescript
// Before (broken)
if (process.env.NODE_ENV === 'development') {
  // ...
}

// After (fixed)
const isDevelopment = process.env.NODE_ENV !== 'production';
if (isDevelopment) {
  // ...
}
```

This ensures that:

- The app loads from `http://localhost:3000` in development (when `NODE_ENV` is unset or set to `'development'`)
- The window is shown when `dom-ready` fires
- A fallback timeout (2 seconds) shows the window if `dom-ready` doesn't fire
- The preload script successfully exposes `window.electronAPI` to the renderer

### Additional Improvements

1. **Fallback Window Display**: Added a 2-second timeout to show the window if `dom-ready` doesn't fire, preventing the window from staying hidden
2. **Preload Script Confirmation**: Kept IPC handlers (`preload:ping`, `preload:expose-complete`, `preload:expose-error`) to confirm preload script execution
3. **Better Error Handling**: Improved error messages and console logging for debugging

### Verification

After the fix:

- ✅ Window appears when Electron app starts
- ✅ `window.electronAPI` is available in React components
- ✅ Preload script executes and exposes API successfully
- ✅ App loads from Vite dev server in development mode

### Prevention

To prevent this issue in the future:

1. **Set NODE_ENV explicitly** in package.json scripts if needed:
   ```json
   "dev:main": "NODE_ENV=development tsc -p tsconfig.main.json && tsc -p tsconfig.preload.json && electron ."
   ```
2. **Use the default-to-development pattern** (as implemented) which is more robust
3. **Test window visibility** in development mode to catch similar issues early

### Related Files

- `src/main/main.ts` - Main Electron process, contains window creation and URL loading logic
- `src/main/preload.ts` - Preload script that exposes `window.electronAPI`
- `src/renderer/components/App.tsx` - React component that uses `window.electronAPI`

---

## Issue: Note Data Not Displaying Correctly - Titles and Descriptions Missing

### Symptoms

- Table view shows "Key" and "lines" columns instead of "Note Title" and "Note Description"
- Raw JSON view shows `{"lines":[]}` instead of proper note format
- Note titles appear as keys but descriptions are empty
- Desired format `[{ "note title": [note description] }]` is not displayed

### Root Cause

The Hive binary file was storing Note data in an incorrect format:

1. **Keys stored as strings (titles) instead of integers (note.id)**:
   - Expected: Keys should be integers (note.id) as per `box.put(note.id, note)` in Flutter
   - Actual: Keys were stored as strings containing note titles (e.g., "test", "test1", "test 3 desc")

2. **Values stored as JSON strings instead of binary Note objects**:
   - Expected: Values should be binary-encoded Note objects with typeId 0, containing fields: id, title, body, drawingData, lastMod
   - Actual: Values were stored as JSON strings like `{"lines":[]}` instead of proper binary Note objects

3. **Parser was extracting wrong data structure**:
   - The binary parser was correctly extracting the string keys and JSON values
   - However, it wasn't recognizing that the keys were actually titles and the values were malformed
   - The parser attempted to parse Note objects from binary format, but the data wasn't in that format

This mismatch occurred because:

- The Hive database file structure didn't match the expected format where Note objects are stored with integer keys and binary-encoded values
- The parser needed to handle this legacy/incorrect format and reconstruct proper Note objects

### Solution

Implemented a multi-layered solution to handle the incorrect format and transform it to the desired display format:

1. **Enhanced Binary Parser** (`hive-parser.ts`):
   - Added detection for the malformed format (string keys with JSON `{"lines":[]}` values)
   - Implemented Note object reconstruction from available data:
     - Uses the key (string) as the note title
     - Extracts body from the `lines` array if present (currently empty in the data)
     - Generates a stable ID from the key string using a hash function
     - Creates a proper Note object structure with id, title, body, drawingData, lastMod

2. **Transformation Function** (`database-service.ts`):
   - Created `transformToNoteFormat()` method that converts HiveRecord[] to the desired format
   - Handles both proper Note objects (with id, title, body) and the malformed format
   - Transforms records to: `[{ "note title": [note description] }]`
   - Handles empty titles by replacing them with date format: `"Slote DD/MM"` (matching Flutter app behavior)
   - Splits description by newlines into an array

3. **Updated Views**:
   - **TableView**: Now displays "Note Title" and "Note Description" columns with proper data
   - **Raw JSON View**: Shows the transformed format `[{ "note title": [note description] }]` instead of raw records

### Code Changes

**Key Files Modified:**

- `src/main/hive-parser.ts`: Added Note object reconstruction logic
- `src/renderer/services/database-service.ts`: Added `transformToNoteFormat()` method
- `src/renderer/components/TableView.tsx`: Updated to use transformed format
- `src/renderer/components/DataViewer.tsx`: Updated Raw JSON view to show transformed format

**Key Implementation Details:**

```typescript
// In hive-parser.ts - Reconstruct Note from malformed format
if (
  value &&
  typeof value === 'object' &&
  'lines' in value &&
  Array.isArray(value.lines)
) {
  // Generate stable ID from key string
  let noteId: number;
  if (typeof key === 'string' && /^\d+$/.test(key)) {
    noteId = parseInt(key, 10);
  } else {
    // Hash the string to generate a stable ID
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
      const char = key.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }
    noteId = Math.abs(hash) & 0xffffffff;
  }

  value = {
    id: noteId,
    title: String(key),
    body: value.lines && value.lines.length > 0 ? value.lines.join('\n') : '',
    drawingData: null,
    lastMod: Date.now(),
  } as Note;
}
```

```typescript
// In database-service.ts - Transform to desired format
static transformToNoteFormat(records: HiveRecord[]): Array<Record<string, string[]>> {
  return records.map((record) => {
    // Extract title and body from Note object or reconstruct from available data
    // Handle empty titles with date replacement
    // Return format: { "note title": [note description] }
  });
}
```

### Verification

After the fix:

- ✅ Table view displays "Note Title" and "Note Description" columns correctly
- ✅ Raw JSON view shows format: `[{ "note title": [note description] }]`
- ✅ Note titles are displayed properly (using keys as titles)
- ✅ Empty titles are replaced with date format: `"Slote DD/MM"`
- ✅ Descriptions are extracted from available data (currently empty arrays, but structure is correct)

### Future Improvements

To properly fix the root cause, the Flutter app should be updated to store Note objects correctly:

1. **Ensure keys are integers**: Use `box.put(note.id, note)` where `note.id` is an integer
2. **Store binary Note objects**: Hive should store Note objects in binary format (typeId 0) with all fields
3. **Verify storage format**: The binary file should contain integer keys and binary-encoded Note objects, not string keys with JSON values

The current solution works around the malformed format, but the ideal fix would be to correct the storage format in the Flutter app.

### Related Files

- `src/main/hive-parser.ts` - Binary parser with Note reconstruction logic
- `src/renderer/services/database-service.ts` - Transformation function
- `src/renderer/components/TableView.tsx` - Table view displaying transformed format
- `src/renderer/components/DataViewer.tsx` - Data viewer with Raw JSON transformation
- `slote_app/lib/src/services/local_db.dart` - Flutter app database service (should store with integer keys)
- `slote_app/lib/src/model/note.dart` - Note model definition

---

## Issue: Scroll Position Resetting in Raw View and Visual Glitches During Save

### Symptoms

- Scroll position in raw JSON view resets to top when typing or saving
- Screen jumps/glitches when saving in tree view
- Scroll position not preserved during edits and saves
- Monaco Editor scroll position not being tracked correctly

### Root Cause

1. **Wrong Scroll Container Reference**:
   - The code was tracking scroll position on the Box wrapper element (`rawViewRef`)
   - Monaco Editor has its own internal scrollable container that is separate from the wrapper
   - Reading/writing `scrollTop` on the wrapper had no effect on Monaco's actual scroll position

2. **Monaco Editor Scroll API Not Used**:
   - Monaco Editor provides its own scroll API (`getScrollTop()` and `setScrollTop()`)
   - The code wasn't accessing the Monaco editor instance to use these methods
   - The Editor component didn't expose a way to access the Monaco instance

3. **Full Reload on Save**:
   - Saving called `loadRecords()` which triggered a full data reload
   - This caused visual glitches and unnecessary re-renders
   - The loading state caused UI flicker

4. **Missing Scroll Preservation in useEffect**:
   - The `rawJson` useEffect that updates the editor value didn't preserve scroll position
   - When the editor value changed, Monaco reset scroll to top

### Solution

1. **Enhanced Editor Component** (`Editor.tsx`):
   - Added `forwardRef` and `useImperativeHandle` to expose Monaco's scroll API
   - Created `EditorRef` interface with `getScrollTop()` and `setScrollTop()` methods
   - Used `onMount` callback to capture the Monaco editor instance
   - Exposed scroll methods that delegate to Monaco's native API

2. **Updated Scroll Tracking** (`DataViewer.tsx`):
   - Replaced `rawViewRef.current.scrollTop` with `editorRef.current.getScrollTop()/setScrollTop()`
   - Added `editorRef` to track Monaco editor instance
   - Updated all scroll save/restore operations to use Monaco's API

3. **Scroll Preservation in useEffect**:
   - Added scroll position saving before `rawJson` updates in the useEffect
   - Restored scroll position after the editor value updates
   - Used `requestAnimationFrame` for smooth restoration timing

4. **Smoother Save Operation**:
   - Removed `loadRecords()` call during save - updates records in place instead
   - Removed loading state during save to prevent UI flicker
   - Added CSS transitions to JsonTreeView for smooth border color changes
   - Records are updated directly in state without full reload

5. **Keyboard Shortcuts**:
   - Added Cmd/Ctrl+S shortcut for saving in both tree and raw views
   - Save button appears when there are unsaved changes
   - Silent save (no alerts) for VS Code-like experience

### Code Changes

**Key Files Modified:**

- `src/renderer/components/Editor.tsx`: Added ref forwarding and Monaco scroll API exposure
- `src/renderer/components/DataViewer.tsx`: Updated scroll tracking to use Monaco API, improved save flow
- `src/renderer/components/JsonTreeView.tsx`: Added CSS transitions for smooth visual changes

**Key Implementation Details:**

```typescript
// In Editor.tsx - Expose Monaco scroll API
export interface EditorRef {
  getScrollTop: () => number;
  setScrollTop: (scrollTop: number) => void;
}

const JsonEditor = forwardRef<EditorRef, EditorProps>(
  ({ value, onChange, readOnly = false }, ref) => {
    const editorRef = useRef<editor.IStandaloneCodeEditor | null>(null);

    useImperativeHandle(ref, () => ({
      getScrollTop: () => editorRef.current?.getScrollTop() || 0,
      setScrollTop: (scrollTop: number) =>
        editorRef.current?.setScrollTop(scrollTop),
    }));

    // ...
  }
);
```

```typescript
// In DataViewer.tsx - Use Monaco scroll API
const saveScrollPosition = () => {
  if (viewMode === 'raw' && editorRef.current) {
    scrollPositionsRef.current.raw = editorRef.current.getScrollTop();
  }
};

const restoreScrollPosition = () => {
  if (viewMode === 'raw' && editorRef.current) {
    editorRef.current.setScrollTop(scrollPositionsRef.current.raw);
  }
};
```

```typescript
// Smooth save without full reload
const handleSave = useCallback(
  async () => {
    // Update records in place instead of calling loadRecords()
    const updatedRecords = records.map((r) => {
      const edited = editedRecords.get(r.key);
      return edited || r;
    });
    setRecords(updatedRecords);
    setEditedRecords(new Map());
    setHasChanges(false);
    // No loading state - smooth UX
  },
  [
    /* ... */
  ]
);
```

### Verification

After the fix:

- ✅ Scroll position preserved when typing in raw view
- ✅ Scroll position preserved when saving in raw view
- ✅ Scroll position preserved when saving in tree view
- ✅ No visual glitches during save operations
- ✅ Smooth CSS transitions when edited state clears
- ✅ Cmd/Ctrl+S shortcut works for saving
- ✅ Silent save (no alerts) for better UX

### Related Files

- `src/renderer/components/Editor.tsx` - Monaco Editor wrapper with scroll API
- `src/renderer/components/DataViewer.tsx` - Scroll preservation and save logic
- `src/renderer/components/JsonTreeView.tsx` - Tree view with smooth transitions
