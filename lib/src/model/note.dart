import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;
  final String title;
  final String body;
  final String? drawingData;
  final DateTime lastMod;

  Note({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.body,
    required this.lastMod,
    this.drawingData,
  });

  Note copyWith({
    Id? id,
    String? title,
    String? body,
    String? drawingData,
    DateTime? lastMod,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      drawingData: drawingData ?? this.drawingData,
      lastMod: lastMod ?? this.lastMod,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'drawingData': drawingData,
      'lastMod': lastMod.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] as String,
      body: map['body'] as String,
      drawingData: map['drawingData'] as String?,
      lastMod: DateTime.fromMillisecondsSinceEpoch(map['lastMod'] as int),
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, body: $body, drawingData: $drawingData, lastMod: $lastMod)';
  }

  @override
  bool operator ==(covariant Note other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.body == body &&
        other.drawingData == drawingData &&
        other.lastMod == lastMod;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        drawingData.hashCode ^
        lastMod.hashCode;
  }
}
