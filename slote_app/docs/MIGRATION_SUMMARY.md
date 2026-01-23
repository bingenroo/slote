# Database Migration: Hive to SQLite

## Summary

Successfully migrated the Slote application from Hive to SQLite database. This eliminates the need for complex binary parsing and JSON export workarounds.

## Changes Made

### Flutter App (`slote_app/`)

1. **Dependencies Updated** (`pubspec.yaml`):
   - Removed: `hive`, `hive_flutter`, `hive_generator`
   - Added: `sqflite`

2. **Note Model** (`lib/src/model/note.dart`):
   - Removed Hive annotations (`@HiveType`, `@HiveField`)
   - Removed `HiveObject` inheritance
   - Kept `toMap()` and `fromMap()` methods for SQLite compatibility

3. **Database Service** (`lib/src/services/local_db.dart`):
   - Completely rewritten to use SQLite
   - Uses `sqflite` package for database operations
   - Implements reactive streams using `StreamController`
   - Database file: `notes.db` in app documents directory

4. **Migration Script** (`lib/src/services/hive_to_sqlite_migration.dart`):
   - One-time migration script to convert Hive data to SQLite
   - Run with: `flutter run --dart-define=MIGRATE_HIVE_TO_SQLITE=1`

5. **Main Entry Point** (`lib/main.dart`):
   - Removed Hive initialization
   - Added migration flag support

6. **Removed Files**:
   - `lib/src/services/hive_export.dart` (no longer needed)

### Database Browser Tool

**Removed**: Electron browser app (`hive_browser/`) - no longer needed

**Replaced with**: DB Browser for SQLite (standard SQLite browser tool)

- Free, open-source SQLite browser
- Install via Homebrew: `brew install --cask db-browser-for-sqlite`
- Direct file access - no custom tools needed
- Standard SQL queries and table views
- Cross-platform support

**Database Access**:
- Pull database files from emulators using ADB commands
- Open directly in DB Browser for SQLite
- No custom parsing or workarounds needed

## Benefits

1. **Code Reduction**: 
   - Removed ~1000 lines of complex binary parser
   - Removed JSON export/import workarounds
   - Estimated 50-70% reduction in database-related code

2. **Simplicity**:
   - Standard SQL queries instead of binary parsing
   - No custom format handling
   - Easy to debug and inspect with standard SQLite tools

3. **Cross-Platform**:
   - Native SQLite support in both Flutter and Electron
   - No format conversion needed
   - Direct file sync

4. **Maintainability**:
   - Well-documented SQLite format
   - Standard tooling support
   - Easier to extend and modify

## Migration Steps for Users

1. **Run Migration Script** (one-time):
   ```bash
   cd slote_app
   flutter run --dart-define=MIGRATE_HIVE_TO_SQLITE=1
   ```

2. **Update Dependencies**:
   ```bash
   # Flutter app
   cd slote_app
   flutter pub get
   
   # No additional tools needed - use DB Browser for SQLite
   ```

3. **Test**:
   - Verify notes load correctly
   - Test CRUD operations
   - Test emulator sync

## Notes

- The old `hive-parser.ts` file is still in the codebase but no longer used
- Consider removing it in a future cleanup
- The `emulator-sync.ts` file still contains some legacy logging code that can be cleaned up
- Database file location: Same as before (app documents directory), but now `notes.db` instead of `notes.hive`

## Next Steps

1. Test the migration thoroughly
2. Remove old Hive parser file (`hive-parser.ts`)
3. Clean up legacy logging code in `emulator-sync.ts`
4. Update documentation to reflect SQLite usage
