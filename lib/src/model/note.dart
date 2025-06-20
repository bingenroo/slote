// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart'; // For listEquals

part 'note.g.dart';

// class Uint8ListConverter {
//   const Uint8ListConverter();

//   static Uint8List from(List<int> object) => Uint8List.fromList(object);
//   static List<int> to(Uint8List object) => object;
// }

@collection
class Note {
  Id id = Isar.autoIncrement;
  final String title;
  final String description;
  final DateTime lastMod;

  // @Uint8ListConverter()
  // final Uint8List? drawing;

  final List<int>? drawing;

  Note({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.description,
    required this.lastMod,
    this.drawing,
  });

  Note copyWith({
    Id? id,
    String? title,
    String? description,
    DateTime? lastMod,
    Uint8List? drawing,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lastMod: lastMod ?? this.lastMod,
      drawing: drawing ?? this.drawing,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'lastMod': lastMod.millisecondsSinceEpoch,
      'drawing': drawing != null ? base64Encode(drawing!) : null,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] as String,
      description: map['description'] as String,
      lastMod: DateTime.fromMillisecondsSinceEpoch(map['lastMod'] as int),
      drawing:
          map['drawing'] != null
              ? base64Decode(map['drawing'] as String)
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) =>
      Note.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Note(id: $id, title: $title, description: $description, lastMod: $lastMod, drawing: $drawing)';
  }

  @override
  bool operator ==(covariant Note other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.description == description &&
        other.lastMod == lastMod &&
        listEquals(other.drawing, drawing);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        lastMod.hashCode ^
        (drawing == null ? 0 : drawing.hashCode);
  }
}
