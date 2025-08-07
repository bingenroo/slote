import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/views/create_note.dart';
import 'package:slote/src/views/widgets/app_checkmark.dart';
import 'package:slote/src/res/theme_config.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: theme.colorScheme.surface,
            elevation: 0.0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.grey.shade800 : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.grey.shade600.withOpacity(0.3)
                          : Colors.grey.shade300,
                  width: isDark ? 0.5 : 1,
                ),
                boxShadow:
                    isDark
                        ? [
                          BoxShadow(
                            color: Colors.grey.shade600.withOpacity(0.1),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: Offset(0, 1),
                          ),
                        ]
                        : [
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
                          style: GoogleFonts.poppins(
                            fontSize: AppThemeConfig.bodyFontSize + 2,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            note.body,
                            style: GoogleFonts.poppins(
                              fontSize: AppThemeConfig.smallFontSize,
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black87.withOpacity(0.6),
                            ),
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
              child: AppCheckmark(color: theme.colorScheme.primary, size: 24),
            ),
        ],
      ),
    );
  }
}
