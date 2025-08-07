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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      // Today: show 24hr time HH:MM
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (date.year == now.year) {
      // This year: show "30 Jul"
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${date.day} ${months[date.month - 1]}";
    } else {
      // Past years: show "27 Oct 2021"
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    }
  }

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
                    color:
                        isDark
                            ? Colors.grey.shade800
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.grey.shade600.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                      width: isDark ? 0.5 : 1,
                    ),
                    boxShadow:
                        isDark
                            ? [
                              BoxShadow(
                                color: Colors.grey.shade600.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                              note.title.isNotEmpty
                                  ? note.title
                                  : "Slote ${note.lastMod.day.toString().padLeft(2, '0')}/${note.lastMod.month.toString().padLeft(2, '0')}",
                              style: GoogleFonts.poppins(
                                fontSize: AppThemeConfig.bodyFontSize + 2,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.body,
                              style: GoogleFonts.poppins(
                                fontSize: AppThemeConfig.smallFontSize,
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.black87.withValues(alpha: 0.6),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(note.lastMod),
                              style: GoogleFonts.poppins(
                                fontSize: AppThemeConfig.smallFontSize - 1,
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.black87.withValues(alpha: 0.4),
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
