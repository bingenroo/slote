import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:slote/src/app.dart';
import 'package:theme/theme.dart';
import 'package:slote/src/services/hive_to_sqlite_migration.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Match rich_text example: stock safeLaunchUrl often skips opening when
  // canLaunchUrlString is false; launch directly for tap-to-open links.
  editorLaunchUrl = (href) async {
    if (href == null || href.isEmpty) return false;
    final trimmed = href.trim();
    final uri = Uri.tryParse(trimmed);
    final target =
        (uri != null && uri.hasScheme) ? trimmed : 'https://$trimmed';
    try {
      return launchUrlString(
        target,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  };

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
