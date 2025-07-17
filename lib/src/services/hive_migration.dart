import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:slote/src/model/note.dart';

/// Run this script once to migrate notes from lib/src/services/Note.json to Hive.
Future<void> migrateNotesFromJson() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteAdapter());
  }
  final box = await Hive.openBox<Note>('notes');

  try {
    final jsonString = await rootBundle.loadString(
      'lib/src/services/Note.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    for (final item in jsonList) {
      final note = Note(
        id: item['id'] as int,
        title: item['title'] as String,
        body: item['body'] as String,
        drawingData: item['drawingData'] as String?,
        lastMod: DateTime.fromMillisecondsSinceEpoch(
          item['lastMod'] is int
              ? item['lastMod']
              : int.parse(item['lastMod'].toString()),
        ),
      );
      await box.put(note.id, note);
      // ignore: avoid_print
      print('Migrated note: ${note.title}');
    }
    // ignore: avoid_print
    print('Migration complete.');
  } catch (e) {
    // ignore: avoid_print
    print('lib/src/services/Note.json not found or failed to load.');
  }
}
