import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/assets.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:slote/src/functions/undo_redo.dart';
import 'package:undo/undo.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late UndoRedoTextController _undoRedoTextController;
  late ChangeStack _changeStack;

  final localDb = LocalDBService();

  bool _showDrawing = false;
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();

    // undo redo
    _changeStack = ChangeStack();
    _undoRedoTextController = UndoRedoTextController(
      _changeStack,
      _bodyController,
    );

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _bodyController.text = widget.note!.body;
    }
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    final title = _titleController.text;
    final body = _bodyController.text;

    _signatureController.dispose();

    if (widget.note != null) {
      if (title.isEmpty && body.isEmpty) {
        localDb.deleteNote(id: widget.note!.id);
      } else if (widget.note!.title != title || widget.note!.body != body) {
        final newNote = widget.note!.copyWith(title: title, body: body);
        localDb.saveNote(note: newNote);
      }
    } else {
      final newNote = Note(
        id: Isar.autoIncrement,
        title: title,
        body: body,
        lastMod: DateTime.now(),
      );
      localDb.saveNote(note: newNote);
    }
    _titleController.dispose();
    _bodyController.dispose();
    _undoRedoTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _titleController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "New Slote",
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 28,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.start,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          showCursor: true,
        ),
        actions: [
          IconButton(
            icon: Icon(_showDrawing ? Icons.text_fields : Icons.draw),
            onPressed: () {
              setState(() {
                _showDrawing = !_showDrawing;
              });
            },
          ),
          if (widget.note != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // show warnings
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        "Delete Note?",
                        style: GoogleFonts.poppins(fontSize: 20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset(AnimationAssets.delete),
                          Text(
                            "Are you sure you want to delete this note permernantly?",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            localDb.deleteNote(id: widget.note!.id);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text("Proceed"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Cancel"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Material(
            elevation: 4, // Shadow depth
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                border: const Border(
                  bottom: BorderSide(
                    color: Colors.black12, // Border color
                    width: 1,
                  ),
                ),
              ),
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.undo,
                  //     color:
                  //         _bodyUndoRedo.canUndo
                  //             ? Theme.of(context).colorScheme.onPrimary
                  //             : Theme.of(
                  //               context,
                  //             ).colorScheme.onPrimary.withValues(alpha: 0.3),
                  //   ),
                  //   tooltip: 'Undo',
                  //   onPressed: _bodyUndoRedoStack.canUndo ? _performUndo : null,
                  // ),
                  ListenableBuilder(
                    listenable: _undoRedoTextController,
                    builder: (context, child) {
                      return IconButton(
                        onPressed:
                            _changeStack.canUndo
                                ? _undoRedoTextController.undo
                                : null,
                        icon: Icon(
                          Icons.undo,
                          color:
                              _changeStack.canUndo
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.3),
                        ),
                        tooltip: 'Undo',
                      );
                    },
                  ),

                  // IconButton(
                  //   icon: Icon(
                  //     Icons.redo,
                  //     color:
                  //         _bodyUndoRedo.canRedo
                  //             ? Theme.of(context).colorScheme.onPrimary
                  //             : Theme.of(
                  //               context,
                  //             ).colorScheme.onPrimary.withValues(alpha: 0.3),
                  //   ),
                  //   tooltip: 'Redo',
                  //   onPressed: _bodyUndoRedoStack.canUndo ? _performUndo : null,
                  // ),
                  ListenableBuilder(
                    listenable: _undoRedoTextController,
                    builder: (context, child) {
                      return IconButton(
                        onPressed:
                            _changeStack.canRedo
                                ? _undoRedoTextController.redo
                                : null,
                        icon: Icon(
                          Icons.redo,
                          color:
                              _changeStack.canRedo
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.3),
                        ),
                        tooltip: 'Redo',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 8),
            //       child: IconButton(
            //         onPressed: () {
            //           Navigator.pop(context);
            //         },
            //         icon: Icon(Icons.arrow_back),
            //       ),
            //     ),

            //     IconButton(
            //       icon: Icon(_showDrawing ? Icons.text_fields : Icons.draw),
            //       onPressed: () {
            //         setState(() {
            //           _showDrawing = !_showDrawing;
            //         });
            //       },
            //     ),

            //     widget.note != null
            //         ? Padding(
            //           padding: const EdgeInsets.symmetric(vertical: 8),
            //           child: IconButton(
            //             icon: Icon(Icons.delete),
            //             onPressed: () {
            //               // show warnings
            //               showDialog(
            //                 context: context,
            //                 builder: (context) {
            //                   return AlertDialog(
            //                     title: Text(
            //                       "Delete Note?",
            //                       style: GoogleFonts.poppins(fontSize: 20),
            //                     ),
            //                     content: Column(
            //                       mainAxisSize: MainAxisSize.min,
            //                       crossAxisAlignment: CrossAxisAlignment.center,
            //                       children: [
            //                         Lottie.asset(AnimationAssets.delete),
            //                         Text(
            //                           "Are you sure you want to delete this note permernantly?",
            //                           style: GoogleFonts.poppins(fontSize: 16),
            //                         ),
            //                       ],
            //                     ),
            //                     actions: [
            //                       TextButton(
            //                         onPressed: () {
            //                           localDb.deleteNote(id: widget.note!.id);
            //                           Navigator.pop(context);
            //                           Navigator.pop(context);
            //                         },
            //                         child: Text("Proceed"),
            //                       ),
            //                       TextButton(
            //                         onPressed: () {
            //                           Navigator.pop(context);
            //                         },
            //                         child: Text("Cancel"),
            //                       ),
            //                     ],
            //                   );
            //                 },
            //               );
            //             },
            //           ),
            //         )
            //         : const SizedBox.shrink(),
            //   ],
            // ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title field (no drawing here)
                    // TextFormField(
                    //   controller: _titleController,
                    //   decoration: const InputDecoration(
                    //     border: InputBorder.none,
                    //     hintText: "Title",
                    //   ),
                    //   style: GoogleFonts.poppins(fontSize: 28),
                    // ),
                    const SizedBox(height: 16),
                    // Description field with drawing overlay
                    Expanded(
                      child: Stack(
                        children: [
                          // Drawing layer: always visible, only interactive in draw mode
                          Visibility(
                            visible: _showDrawing,
                            maintainState: true,
                            child: Signature(
                              controller: _signatureController,
                              width: double.infinity,
                              height: double.infinity,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          // If there's a saved drawing and the canvas is empty, show it
                          if (widget.note?.drawing != null &&
                              _signatureController.isEmpty)
                            Positioned.fill(
                              child: Image.memory(
                                Uint8List.fromList(widget.note!.drawing!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          // Description text field: always interactive unless drawing
                          IgnorePointer(
                            ignoring: _showDrawing,
                            child: TextFormField(
                              controller:
                                  // _undoRedoTextController.textController,
                                  _bodyController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Description",
                              ),
                              style: GoogleFonts.poppins(fontSize: 18),
                              maxLines: null,
                              expands: true,
                            ),
                          ),
                          // Clear button for drawing
                          if (_showDrawing)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _signatureController.clear();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: TextFormField(
            //     controller: _titleController,
            //     decoration: const InputDecoration(
            //       border: InputBorder.none,
            //       hintText: "Title",
            //     ),
            //     style: GoogleFonts.poppins(fontSize: 28),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: TextFormField(
            //     controller: _descriptionController,
            //     decoration: const InputDecoration(
            //       border: InputBorder.none,
            //       hintText: "Description",
            //     ),
            //     style: GoogleFonts.poppins(fontSize: 18),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
