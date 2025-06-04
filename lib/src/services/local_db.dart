import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slote/src/model/note.dart';

class LocalDBService {
  late Future<Isar> db;

  LocalDBService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [NoteSchema],
        directory: dir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveNote({required Note note}) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.notes.putSync(note));
  }

  Stream<List<Note>> listenAllNotes() async* {
    final isar = await db;
    yield* isar.notes.where().watch(fireImmediately: true);
  }

  // Future<void> deleteNote({required int id}) async {
  //   final isar = await db;
  //   isar.writeTxnSync(() => isar.notes.delete(id));
  // }
  void deleteNote({required int id}) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.notes.deleteSync(id));
  }
}
