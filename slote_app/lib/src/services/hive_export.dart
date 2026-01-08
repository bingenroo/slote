import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slote/src/model/note.dart';

/// Export Hive box to JSON file
/// This creates a JSON file that can be parsed by the Electron Hive browser
class HiveExporter {
  /// Export the notes box to JSON format
  /// Returns the path to the exported JSON file
  static Future<String?> exportNotesToJson() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(NoteAdapter());
      }

      final box = await Hive.openBox<Note>('notes');
      
      // Convert all notes to JSON
      final List<Map<String, dynamic>> notesJson = [];
      for (var key in box.keys) {
        final note = box.get(key);
        if (note != null) {
          notesJson.add(note.toMap());
        }
      }

      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'boxes': {
          'notes': {
            'records': notesJson,
            'recordCount': notesJson.length,
          }
        },
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final exportPath = '${appDir.path}/notes.json';
      
      // Write JSON file
      final file = File(exportPath);
      await file.writeAsString(
        jsonEncode(exportData),
        mode: FileMode.write,
      );

      print('[HIVE-EXPORT] Exported ${notesJson.length} notes to $exportPath');
      return exportPath;
    } catch (e) {
      print('[HIVE-EXPORT] Error exporting to JSON: $e');
      return null;
    }
  }

  /// Export notes to JSON in app_flutter directory (for sync)
  /// This creates notes.json alongside notes.hive
  static Future<String?> exportNotesToJsonForSync() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(NoteAdapter());
      }

      final box = await Hive.openBox<Note>('notes');
      
      // Convert all notes to JSON
      final List<Map<String, dynamic>> notesJson = [];
      for (var key in box.keys) {
        final note = box.get(key);
        if (note != null) {
          notesJson.add(note.toMap());
        }
      }

      // Create export data structure
      final exportData = {
        'version': '1.0.0',
        'boxes': [
          {
            'name': 'notes',
            'keys': box.keys.toList(),
            'recordCount': notesJson.length,
          }
        ],
        'notes': notesJson,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Get app directory (app_flutter)
      // On Android, getApplicationDocumentsDirectory() returns:
      // /data/data/com.example.slote/app_flutter/
      final appDir = await getApplicationDocumentsDirectory();
      print('[HIVE-EXPORT] App directory: ${appDir.path}');
      
      // Hive stores files directly in app_flutter directory
      // Export JSON to the same location as notes.hive
      final exportPath = '${appDir.path}/notes.json';
      print('[HIVE-EXPORT] Export path: $exportPath');
      
      // Ensure directory exists
      final exportFile = File(exportPath);
      if (!await exportFile.parent.exists()) {
        await exportFile.parent.create(recursive: true);
      }
      
      // Write JSON file
      final file = File(exportPath);
      await file.writeAsString(
        jsonEncode(exportData),
        mode: FileMode.write,
      );

      // Verify file was created
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('[HIVE-EXPORT] Exported ${notesJson.length} notes to $exportPath');
      print('[HIVE-EXPORT] File exists: $fileExists, size: $fileSize bytes');
      if (!fileExists || fileSize == 0) {
        print('[HIVE-EXPORT] ERROR: File was not created or is empty!');
      }
      return exportPath;
    } catch (e) {
      print('[HIVE-EXPORT] Error exporting to JSON: $e');
      print('[HIVE-EXPORT] Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}

