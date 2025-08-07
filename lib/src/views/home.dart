import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/string.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/views/create_note.dart';
import 'package:slote/src/views/widgets/empty_view.dart';
import 'package:slote/src/views/widgets/notes_grid.dart';
import 'package:slote/src/views/widgets/notes_list.dart';
import 'package:slote/src/views/widgets/app_checkmark.dart';
import 'package:slote/src/res/assets.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:slote/src/providers/theme_provider.dart';
import 'package:slote/src/res/theme_config.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool islistView = true;
  bool _selectionMode = false; // Add selection mode state
  Set<int> _selectedNoteIds = {}; // Track selected notes by ID
  int? _lastNotesCount; // Store for select all logic
  List<int>? _lastNoteIds; // Store for select all logic

  void _enterSelectionMode(int noteId) {
    setState(() {
      _selectionMode = true;
      _selectedNoteIds = {}; // Always start with nothing selected
      _selectedNoteIds.add(noteId); // Only the long-pressed note is selected
    });
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52, // Match create_note
        title: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.appName,
                style: GoogleFonts.poppins(
                  fontSize: AppThemeConfig.titleFontSize,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 16),
              if (_selectionMode) ...[
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final allSelected =
                            _selectedNoteIds.length == (_lastNotesCount ?? 0) &&
                            _selectedNoteIds.isNotEmpty;
                        setState(() {
                          if (!allSelected) {
                            _selectedNoteIds = Set.from(_lastNoteIds ?? []);
                          } else {
                            _selectedNoteIds.clear();
                          }
                        });
                      },
                      child:
                          _selectedNoteIds.length == (_lastNotesCount ?? 0) &&
                                  _selectedNoteIds.isNotEmpty
                              ? AppCheckmark(
                                color: Colors.white, // Light background
                                iconColor: Colors.black,
                                size: 20, // Slightly smaller
                                showShadow: false,
                              )
                              : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          isDark
                                              ? Colors.black26
                                              : Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                "Delete Notes?",
                                style: GoogleFonts.poppins(
                                  fontSize: AppThemeConfig.bodyFontSize,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Lottie.asset(AnimationAssets.delete),
                                  SizedBox(height: 16),
                                  Text(
                                    "Are you sure you want to delete the selected notes permanently?",
                                    style: GoogleFonts.poppins(
                                      fontSize: AppThemeConfig.smallFontSize,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: Text(
                                    "Proceed",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (shouldDelete == true) {
                          final idsToDelete = _selectedNoteIds.toList();
                          for (final id in idsToDelete) {
                            await LocalDBService().deleteNote(id: id);
                          }
                          setState(() {
                            _selectedNoteIds.clear();
                            _selectionMode = false;
                          });
                        }
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.trash,
                        color: theme.colorScheme.onPrimary,
                        size: 18, // Match create_note
                      ),
                    ),
                    IconButton(
                      onPressed: _exitSelectionMode,
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        color: theme.colorScheme.onPrimary,
                        size: 18, // Match create_note
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisSize:
                      MainAxisSize
                          .min, // This makes the row as small as possible
                  children: [
                    IconButton(
                      icon: Icon(
                        context.watch<ThemeProvider>().isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          islistView = !islistView;
                        });
                      },
                      icon: FaIcon(
                        islistView
                            ? FontAwesomeIcons.listUl
                            : FontAwesomeIcons.tableCellsLarge,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(20.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text(
            //         AppStrings.appName,
            //         style: GoogleFonts.poppins(fontSize: 28),
            //       ),
            //       IconButton(
            //         onPressed: () {
            //           setState(() {
            //             islistView = !islistView;
            //           });
            //         },
            //         icon: Icon(
            //           islistView ? Icons.splitscreen_outlined : Icons.grid_view,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const EmptyView(),
            Expanded(
              child: StreamBuilder<List<Note>>(
                stream: LocalDBService().listenAllNotes(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }
                  final notes = snapshot.data!;

                  // Store for select all logic
                  _lastNotesCount = notes.length;
                  _lastNoteIds = notes.map((n) => n.id).toList();

                  // Check if the list is empty
                  if (notes.isEmpty) {
                    return const EmptyView();
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        islistView
                            ? NotesList(
                              notes: notes,
                              onNoteLongPress:
                                  (noteId) => _enterSelectionMode(noteId),
                              onNoteTap: (noteId) {
                                if (_selectionMode) {
                                  _toggleNoteSelection(noteId);
                                } else {
                                  // No-op or open note
                                }
                              },
                              selectionMode: _selectionMode,
                              selectedNoteIds: _selectedNoteIds,
                            )
                            : NotesGrid(
                              notes: notes,
                              onNoteLongPress:
                                  (noteId) => _enterSelectionMode(noteId),
                              onNoteTap: (noteId) {
                                if (_selectionMode) {
                                  _toggleNoteSelection(noteId);
                                } else {
                                  // No-op or open note
                                }
                              },
                              selectionMode: _selectionMode,
                              selectedNoteIds: _selectedNoteIds,
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => CreateNoteView()));
        },
        backgroundColor:
            isDark
                ? Colors.grey.shade800
                : Theme.of(context).colorScheme.surface,
        child: Icon(Icons.add, color: theme.colorScheme.primary),
      ),
    );
  }
}
