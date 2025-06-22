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

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late final MultiFieldUndoRedoController _multiUndoRedo;

  final localDb = LocalDBService();

  bool _showDrawing = false;
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
    }
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _multiUndoRedo = MultiFieldUndoRedoController(
      _titleController,
      _descriptionController,
    );
    _multiUndoRedo.addListener(_onUndoRedoChanged);
  }

  void _onUndoRedoChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _multiUndoRedo.removeListener(_onUndoRedoChanged);
    super.dispose();
    _multiUndoRedo.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();

    final title = _titleController.text;
    final description = _descriptionController.text;

    _signatureController.dispose();

    if (widget.note != null) {
      if (title.isEmpty && description.isEmpty) {
        localDb.deleteNote(id: widget.note!.id);
      } else if (widget.note!.title != title ||
          widget.note!.description != description) {
        final newNote = widget.note!.copyWith(
          title: title,
          description: description,
        );
        localDb.saveNote(note: newNote);
      }
    } else {
      final newNote = Note(
        id: Isar.autoIncrement,
        title: title,
        description: description,
        lastMod: DateTime.now(),
      );
      localDb.saveNote(note: newNote);
    }
    _titleController.dispose();
    _descriptionController.dispose();
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
        // title: Text(
        //   widget.note == null ? "New Note" : "Edit Note",
        //   style: GoogleFonts.poppins(fontSize: 22),
        // ),
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
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'Undo',
                    onPressed:
                        _multiUndoRedo.canUndo
                            ? () {
                              setState(() {
                                final lastAction = _multiUndoRedo.peekUndo();
                                _multiUndoRedo.undo();
                                if (lastAction?.type == FieldType.title) {
                                  _titleFocusNode.requestFocus();
                                } else if (lastAction?.type ==
                                    FieldType.description) {
                                  _descriptionFocusNode.requestFocus();
                                }
                              });
                            }
                            : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'Redo',
                    onPressed:
                        _multiUndoRedo.canRedo
                            ? () {
                              setState(() {
                                final lastAction = _multiUndoRedo.peekRedo();
                                _multiUndoRedo.redo();
                                if (lastAction?.type == FieldType.title) {
                                  _titleFocusNode.requestFocus();
                                } else if (lastAction?.type ==
                                    FieldType.description) {
                                  _descriptionFocusNode.requestFocus();
                                }
                              });
                            }
                            : null,
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
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Title",
                      ),
                      style: GoogleFonts.poppins(fontSize: 28),
                    ),
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
                              controller: _descriptionController,
                              focusNode: _descriptionFocusNode,
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
