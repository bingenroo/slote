import 'package:hive_flutter/hive_flutter.dart';
import 'package:slote/src/model/note.dart';

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
  }

  Stream<List<Note>> listenAllNotes() async* {
    final b = await box;
    yield b.values.toList();
    yield* b.watch().map((_) => b.values.toList());
  }

  Future<void> deleteNote({required int id}) async {
    final b = await box;
    await b.delete(id);
  }
}
