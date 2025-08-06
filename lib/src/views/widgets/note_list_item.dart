import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/views/create_note.dart';
import 'package:slote/src/views/widgets/app_checkmark.dart';
import 'package:slote/src/res/theme_config.dart';

class NoteListItem extends StatelessWidget {
  const NoteListItem({
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
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
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 0.0,
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black12,
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
                              style: GoogleFonts.poppins(
                                fontSize: AppThemeConfig.bodyFontSize,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                            ),
                            Text(
                              note.body,
                              style: GoogleFonts.poppins(
                                fontSize: AppThemeConfig.bodyFontSize,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
                  child: AppCheckmark(
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
