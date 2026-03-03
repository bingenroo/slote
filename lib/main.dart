import 'package:flutter/material.dart';
import 'package:slote/src/app.dart';
import 'package:slote_theme/slote_theme.dart';
import 'package:slote/src/services/hive_to_sqlite_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme preference before running the app
  await ThemeProvider.initializeTheme();

  // One-time migration: set MIGRATE_HIVE_TO_SQLITE=1 in your environment to run
  const migrate = bool.fromEnvironment('MIGRATE_HIVE_TO_SQLITE', defaultValue: false);
  if (migrate) {
    await migrateHiveToSQLite();
    return;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
