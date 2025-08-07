import 'package:flutter/material.dart';
import 'package:slote/src/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/providers/theme_provider.dart';
// import 'package:slote/src/services/hive_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteAdapter());
  }

  // Initialize theme preference before running the app
  await ThemeProvider.initializeTheme();

  // One-time migration: set MIGRATE=1 in your environment to run
  // const migrate = bool.fromEnvironment('MIGRATE', defaultValue: false);
  // if (migrate) {
  //   await migrateNotesFromJson();
  //   return;
  // }
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
