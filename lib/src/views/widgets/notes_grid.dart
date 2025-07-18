import 'package:flutter/material.dart';
import 'package:slote/src/model/note.dart';
import 'package:auto_animated/auto_animated.dart';
import 'package:slote/src/views/widgets/note_grid_item.dart';

class NotesGrid extends StatelessWidget {
  const NotesGrid({super.key, required this.notes, this.onNoteLongPress});

  final List<Note> notes;
  final VoidCallback? onNoteLongPress;

  @override
  Widget build(BuildContext context) {
    return LiveGrid.options(
      padding: const EdgeInsets.all(20.0),
      itemBuilder: (context, index, animation) {
        return NoteGridItem(note: notes[index], onLongPress: onNoteLongPress);
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: notes.length,
      options: const LiveOptions(),
    );
  }
}
