import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/services/slote_rich_text_storage.dart';

class LocalDBService {
  static const String _dbName = 'notes.db';
  static const String _tableName = 'notes';
  static const int _dbVersion = 2;
  
  // Singleton instance
  static LocalDBService? _instance;
  
  // Factory constructor to return the singleton instance
  factory LocalDBService() {
    _instance ??= LocalDBService._internal();
    return _instance!;
  }
  
  // Private constructor for singleton
  LocalDBService._internal();
  
  Database? _database;
  final StreamController<List<Note>> _notesController = StreamController<List<Note>>.broadcast();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _dbName);
      print('[DB] Initializing database at: $path');

      final db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      print('[DB] Database initialized successfully');
      return db;
    } catch (e, stackTrace) {
      print('[DB ERROR] Failed to initialize database: $e');
      print('[DB ERROR] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        drawingData TEXT,
        lastMod INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Phase-one rich text migration: normalize all note bodies to AppFlowy
      // document JSON strings; invalid/non-json bodies become empty documents.
      final rows = await db.query(_tableName, columns: ['id', 'body']);
      for (final row in rows) {
        final id = row['id'];
        final body = row['body'] as String? ?? '';
        final normalizedBody = normalizeNoteBodyToDocumentJsonString(body);
        await db.update(
          _tableName,
          {'body': normalizedBody},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<void> saveNote({required Note note}) async {
    try {
      final db = await database;
      print('[DB] Saving note: id=${note.id}, title="${note.title}", lastMod=${note.lastMod}');
      await db.insert(
        _tableName,
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('[DB] Note saved successfully');
      await _notifyListeners();
    } catch (e, stackTrace) {
      print('[DB ERROR] Failed to save note: $e');
      print('[DB ERROR] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Note>> listenAllNotes() async* {
    // Emit initial list
    final initialNotes = await getAllNotes();
    yield initialNotes;
    
    // Then emit from stream controller
    yield* _notesController.stream;
  }

  Future<void> _notifyListeners() async {
    final notes = await getAllNotes();
    _notesController.add(notes);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'lastMod DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNote(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<void> deleteNote({required int id}) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyListeners();
  }

  Future<void> close() async {
    await _notesController.close();
    final db = await database;
    await db.close();
    _database = null;
  }
}
