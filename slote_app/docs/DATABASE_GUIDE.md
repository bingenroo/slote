# Database Guide

This guide covers database access, schema, and migration information for Slote.

## Table of Contents

1. [Database Access](#database-access)
2. [Database Schema](#database-schema)
3. [Database Migration Analysis](#database-migration-analysis)

---

## Database Access

### Overview

Slote uses SQLite for local storage. The database file (`notes.db`) can be accessed using standard SQLite tools.

### Database Location

The SQLite database is stored in the app's documents directory:

- **Android**: `/data/data/com.example.slote/app_flutter/notes.db`
- **iOS**: App Documents directory
- **macOS**: `~/Library/Containers/com.example.slote/Data/Documents/notes.db`
- **Windows**: App Data directory
- **Linux**: `~/.local/share/com.example.slote/notes.db`

### Accessing Database (Cross-Platform)

#### Quick Method (Recommended)

Use the unified command tool (`cmd.py`) to open the database in one command:

**Note:** On macOS/Linux, use `python3` (or run directly as `./cmd.py`). On Windows, use `python`.

```bash
# From project root - Auto-detect platform and open database
python3 cmd.py db open

# Force Android mode (pulls from device/emulator)
python3 cmd.py db open android [--device-id DEVICE_ID] [--output-file FILE]

# Force iOS simulator mode (booted simulator only)
python3 cmd.py db open ios

# Force host platform mode (macOS/Linux/Windows)
python3 cmd.py db open host [--db-path PATH]

# Web platform guidance (uses IndexedDB, not SQLite file)
python3 cmd.py db open web
```

**How it works:**
- **Auto mode** (no arguments): If an Android device/emulator is connected and the app is installed, it pulls the database and opens it. Otherwise, it opens the database file directly from the host platform's location.
- **Android mode**: Pulls the database from the connected device/emulator using ADB.
- **iOS mode**: Accesses the database from the booted iOS simulator.
- **Host mode**: Opens the database file directly from the platform-specific location (macOS, Linux, or Windows).
- **Web mode**: Displays guidance about using browser DevTools to inspect IndexedDB.

**Platform Support:**
- ✅ **Android**: Pulls database via ADB from device/emulator
- ✅ **iOS**: Accesses database from booted simulator
- ✅ **macOS**: Opens database from `~/Library/Containers/com.example.slote/Data/Documents/notes.db`
- ✅ **Linux**: Opens database from `~/.local/share/com.example.slote/notes.db`
- ✅ **Windows**: Opens database from AppData directory
- ℹ️ **Web**: Uses IndexedDB (not a SQLite file) - use browser DevTools

#### Manual Method

If you prefer to access the database manually:

**Android:**
```bash
# Pull and open database using cmd.py
python3 cmd.py db open android

# Or manually pull and open
adb exec-out run-as com.example.slote cat app_flutter/notes.db > notes.db
python3 cmd.py db open host notes.db
```

**macOS:**
```bash
# Open database directly using cmd.py
python3 cmd.py db open host

# Or manually
open -a "DB Browser for SQLite" ~/Library/Containers/com.example.slote/Data/Documents/notes.db
```

**Linux:**
```bash
# Open database directly using cmd.py
python3 cmd.py db open host

# Or manually
sqlitebrowser ~/.local/share/com.example.slote/notes.db
```

**Windows:**
```bash
# Open database directly using cmd.py
python cmd.py db open host

# Or manually (path varies by Windows version)
sqlitebrowser "%LOCALAPPDATA%\com.example.slote\Data\Documents\notes.db"
```

**iOS Simulator:**
```bash
# Use cmd.py (requires booted simulator)
python3 cmd.py db open ios
```

#### Pushing Database Changes Back to Device

After editing the database in DB Browser, push changes back to the device:

```bash
# Push local notes.db to Android device/emulator
python3 cmd.py db push

# Push specific file to specific device
python3 cmd.py db push --db-file notes.db --device-id emulator-5554
```

### Recommended Tools

#### DB Browser for SQLite (Recommended)

**Installation:**
- **macOS**: `brew install --cask db-browser-for-sqlite`
- **Linux**: Install `sqlitebrowser` package (package name varies by distribution)
- **Windows**: Download from https://sqlitebrowser.org/ or install via package manager
- **Website**: https://sqlitebrowser.org/

**Features:**
- Simple, intuitive UI
- Browse tables and data
- Execute SQL queries
- Edit data directly
- Export/import data
- Cross-platform support

#### Alternative Tools

- **TablePlus** (free tier available): https://tableplus.com/
- **SQLiteStudio**: https://sqlitestudio.pl/
- **DBeaver Community**: https://dbeaver.io/

### Common Tasks

#### View All Notes

```sql
SELECT * FROM notes ORDER BY lastMod DESC;
```

#### Search Notes

```sql
SELECT * FROM notes WHERE title LIKE '%search term%' OR body LIKE '%search term%';
```

#### Export Data

Use DB Browser's Export feature:
1. Open database in DB Browser
2. Go to **File → Export → Database to SQL file**
3. Or use **File → Export → Table(s) to CSV file**

#### Backup Database

```bash
# From emulator
adb exec-out run-as com.example.slote cat app_flutter/notes.db > backup_notes.db

# Or copy the file directly if you have access
cp notes.db backup_notes.db
```

### Notes

- The database file is created automatically when the app first runs
- Always backup before making manual changes
- Changes made in DB Browser will be reflected in the app after restart
- For production, use the app's built-in CRUD operations rather than manual edits

---

## Database Schema

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  drawingData TEXT,
  lastMod INTEGER NOT NULL
);
```

---

## Database Migration Analysis

### Current Situation Analysis

#### What You Have Now

- **SQLite** for local storage (migrated from Hive)
- **Standard SQLite format**: Well-documented, widely understood, no custom parsing needed
- **Easy inspection**: Can use standard SQLite tools (DB Browser, CLI, VS Code extensions)
- **Simple CRUD**: Standard SQL queries, no complex binary parsing

#### Previous Pain Points (Resolved)

1. **Binary Format Complexity**: Previously used Hive with a 1000+ line binary parser with complex edge cases
2. **Cross-Platform Friction**: Hive was Flutter-native, requiring custom parsers for Electron/Node.js
3. **Development Overhead**: Previously maintained a separate Electron app and complex parser
4. **Debugging Difficulty**: Binary format was hard to inspect without specialized tools
5. **Workaround Dependencies**: JSON export/import as a workaround suggested the binary format was problematic

### Why SQLite is Better

**Advantages:**

- ✅ **Native cross-platform support**: Works natively in Flutter (`sqflite`) and Electron/Node.js (`better-sqlite3`)
- ✅ **Standard format**: Well-documented, widely understood, no custom parsing needed
- ✅ **Easy inspection**: Can use standard SQLite tools (DB Browser, CLI, VS Code extensions)
- ✅ **Simple CRUD**: Standard SQL queries, no complex binary parsing
- ✅ **Better Electron integration**: `better-sqlite3` is mature and well-maintained
- ✅ **No workarounds needed**: Direct file access, no JSON export/import required
- ✅ **Performance**: SQLite is highly optimized and performant
- ✅ **Query capabilities**: Can do complex queries, filtering, sorting without loading all data

**Your Data Model Fits Perfectly:**

```sql
-- Current Note model maps directly to SQL table
CREATE TABLE notes (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  drawingData TEXT,
  lastMod INTEGER NOT NULL
);
```

### Migration Status

✅ **Migration Complete**: The app has been successfully migrated from Hive to SQLite.

The migration was completed because:
- No binary parsing complexity
- Native support in both Flutter and Electron
- Standard, well-documented format
- Easy debugging and inspection
- Simpler codebase to maintain

### Migration Implementation

The migration effort resulted in:
- **Code reduction**: Removed ~1000 lines of binary parser code
- **Removed workarounds**: No more JSON export/import needed
- **Simplified sync logic**: Direct SQLite file access
- **Estimated: 50-70% reduction in database-related code**

### Future Considerations

#### Security

- Research SQLite's security features and ensure proper safeguards are accounted for
- Consider encryption for sensitive data if needed
- Implement proper backup and recovery strategies

#### Performance Optimization

- Consider indexing frequently queried columns
- Implement pagination for large datasets
- Monitor query performance and optimize as needed

#### Alternative Options (If SQLite Doesn't Fit Future Needs)

**Option 2: JSON Files**
- **Pros**: Simplest, human-readable, no parsing
- **Cons**: Slower for large datasets, no query capabilities
- **Best for**: Small datasets (<1000 notes), prototyping

**Option 3: Isar**
- **Pros**: Very fast, Flutter-native, modern API
- **Cons**: No Electron/Node.js support (would still need custom parser)
- **Best for**: Flutter-only apps

**Option 4: Drift (Moor)**
- **Pros**: Type-safe SQL, reactive queries, good Flutter support
- **Cons**: Still SQLite-based (SQLite is simpler), more complex setup
- **Best for**: Complex relational data needs

---

*This guide covers database access, schema, and migration information. For real-time updates architecture, see [REAL_TIME_UPDATES.md](./REAL_TIME_UPDATES.md).*
