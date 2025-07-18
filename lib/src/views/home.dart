import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/string.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/views/create_note.dart';
import 'package:slote/src/views/widgets/empty_view.dart';
import 'package:slote/src/views/widgets/notes_grid.dart';
import 'package:slote/src/views/widgets/notes_list.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool islistView = true;
  bool _selectionMode = false; // Add selection mode state
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.appName,
                style: GoogleFonts.poppins(fontSize: 28),
              ),
              SizedBox(width: 16), // Add space between title and button group
              // Selection mode UI
              if (_selectionMode) ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // TODO: Add delete logic
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectionMode = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      islistView = !islistView;
                    });
                  },
                  icon: Icon(
                    islistView ? Icons.splitscreen_outlined : Icons.grid_view,
                  ),
                ),
              ],
            ],
          ),
        ),
        automaticallyImplyLeading:
            false, // Removes default back button if needed
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  final notes = snapshot.data!;

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
                              onNoteLongPress: () {
                                setState(() {
                                  _selectionMode = true;
                                });
                              },
                            )
                            : NotesGrid(
                              notes: notes,
                              onNoteLongPress: () {
                                setState(() {
                                  _selectionMode = true;
                                });
                              },
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
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.grey),
      ),
    );
  }
}
