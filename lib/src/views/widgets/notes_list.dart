import 'package:auto_animated_list/auto_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/views/widgets/note_list_item.dart';

class NotesList extends StatelessWidget {
  const NotesList({
    super.key,
    required this.notes,
    required this.onNoteLongPress,
    required this.onNoteTap,
    required this.selectionMode,
    required this.selectedNoteIds,
  });

  final List<Note> notes;
  final void Function(int noteId) onNoteLongPress;
  final void Function(int noteId) onNoteTap;
  final bool selectionMode;
  final Set<int> selectedNoteIds;

  @override
  Widget build(BuildContext context) {
    return AutoAnimatedList<Note>(
      padding: const EdgeInsets.all(20),
      items: notes,
      itemBuilder: (context, note, index, animation) {
        return SizeFadeTransition(
          animation: animation,
          child: NoteListItem(
            note: notes[index],
            onLongPress: () => onNoteLongPress(notes[index].id),
            onTap: () => onNoteTap(notes[index].id),
            selectionMode: selectionMode,
            selected: selectedNoteIds.contains(notes[index].id),
          ),
        );
      },
    );
  }
}
