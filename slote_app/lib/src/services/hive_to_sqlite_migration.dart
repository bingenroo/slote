/// One-time migration script to migrate data from Hive to SQLite
/// 
/// NOTE: This migration requires hive_flutter to be temporarily added back to pubspec.yaml
/// To use this migration:
/// 1. Add hive_flutter and hive to pubspec.yaml dependencies
/// 2. Run: flutter pub get
/// 3. Run: flutter run --dart-define=MIGRATE_HIVE_TO_SQLITE=1
/// 4. Remove hive_flutter and hive from pubspec.yaml after migration
/// 
/// Usage: Set MIGRATE_HIVE_TO_SQLITE=1 in your environment to run
Future<void> migrateHiveToSQLite() async {
  print('[MIGRATION] Hive to SQLite migration is not available.');
  print('[MIGRATION] The hive_flutter package has been removed from dependencies.');
  print('[MIGRATION]');
  print('[MIGRATION] To run migration:');
  print('[MIGRATION] 1. Temporarily add hive_flutter and hive to pubspec.yaml');
  print('[MIGRATION] 2. Run: flutter pub get');
  print('[MIGRATION] 3. Update this file to import hive_flutter');
  print('[MIGRATION] 4. Run: flutter run --dart-define=MIGRATE_HIVE_TO_SQLITE=1');
  print('[MIGRATION] 5. Remove hive dependencies after migration completes');
  print('[MIGRATION]');
  print('[MIGRATION] Migration aborted.');
}
