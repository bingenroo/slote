import 'package:hive_flutter/hive_flutter.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/services/hive_export.dart';

class LocalDBService {
  static const String noteBoxName = 'notes';
  late Future<Box<Note>> box;

  LocalDBService() {
    box = openDB();
  }

  Future<Box<Note>> openDB() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteAdapter());
    }
    return await Hive.openBox<Note>(noteBoxName);
  }

  Future<void> saveNote({required Note note}) async {
    final b = await box;
    await b.put(note.id, note);
    // Automatically export to JSON for Hive Browser sync
    try {
      await HiveExporter.exportNotesToJsonForSync();
    } catch (e) {
      // Don't fail if export fails, just log it
      print('[LOCAL-DB] Failed to export to JSON: $e');
    }
  }

  Stream<List<Note>> listenAllNotes() async* {
    final b = await box;
    yield b.values.toList();
    yield* b.watch().map((_) => b.values.toList());
  }

  Future<void> deleteNote({required int id}) async {
    final b = await box;
    await b.delete(id);
    // Automatically export to JSON for Hive Browser sync
    try {
      await HiveExporter.exportNotesToJsonForSync();
    } catch (e) {
      // Don't fail if export fails, just log it
      print('[LOCAL-DB] Failed to export to JSON: $e');
    }
  }
}
