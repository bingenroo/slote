import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/views/create_note.dart';
import 'package:slote/src/views/widgets/app_checkmark.dart';

class NoteGridItem extends StatelessWidget {
  const NoteGridItem({
    super.key,
    required this.note,
    this.onLongPress,
    this.onTap,
    this.selectionMode = false,
    this.selected = false,
  });

  final Note note;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Stack(
        children: [
          MaterialButton(
            onPressed:
                selectionMode
                    ? null
                    : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateNoteView(note: note),
                        ),
                      );
                    },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
            color: Colors.white,
            elevation: 0.0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.poppins(fontSize: 15),
                          maxLines: 1,
                        ),
                        Flexible(
                          child: Text(
                            note.body,
                            style: GoogleFonts.poppins(fontSize: 15),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectionMode && selected)
            Positioned(
              top: 8,
              left: 8,
              child: AppCheckmark(color: Colors.grey, size: 24),
            ),
        ],
      ),
    );
  }
}
