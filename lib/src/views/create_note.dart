import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/assets.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/functions/undo_redo.dart';
import 'package:undo/undo.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final DrawingController _drawingController = DrawingController();
  bool _isDrawingMode = false;

  late UndoRedoTextController _undoRedoTextController;
  late ChangeStack _changeStack;

  final localDb = LocalDBService();

  @override
  void initState() {
    super.initState();

    _drawingController.setStyle(color: Colors.black);

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
  }

  @override
  void dispose() {
    _saveNoteData();

    _titleController.dispose();
    _bodyController.dispose();
    _undoRedoTextController.dispose();
    _drawingController.dispose();

    super.dispose();
  }

  void _saveNoteData() async {
    final title = _titleController.text;
    final body = _bodyController.text;

    if (widget.note != null) {
      if (title.isEmpty && body.isEmpty) {
        localDb.deleteNote(id: widget.note!.id);
      } else if (widget.note!.title != title || widget.note!.body != body) {
        final newNote = widget.note!.copyWith(title: title, body: body);
        localDb.saveNote(note: newNote);
      }
    } else {
      if (title.isNotEmpty || body.isNotEmpty) {
        final newNote = Note(
          id: Isar.autoIncrement,
          title: title,
          body: body,
          lastMod: DateTime.now(),
        );
        localDb.saveNote(note: newNote);
      }
    }
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
          if (widget.note != null)
            IconButton(
              icon: Icon(_isDrawingMode ? Icons.text_fields : Icons.draw),
              onPressed: () {
                setState(() {
                  _isDrawingMode = !_isDrawingMode;
                  if (_isDrawingMode) {
                    // Clear any existing text selection
                    _bodyController.selection = TextSelection.collapsed(
                      offset: _bodyController.selection.baseOffset,
                    );
                  }
                });
              },
              tooltip: _isDrawingMode ? 'Text Mode' : 'Drawing Mode',
            ),
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
            Expanded(
              child: Stack(
                children: [
                  // Original text field with padding
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Expanded(
                            child: AbsorbPointer(
                              absorbing: _isDrawingMode,
                              child: TextFormField(
                                controller: _bodyController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Description",
                                  hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                style: GoogleFonts.poppins(fontSize: 18),
                                maxLines: null,
                                expands: true,
                                readOnly: _isDrawingMode,
                                enableInteractiveSelection: !_isDrawingMode,
                                showCursor: !_isDrawingMode,
                                contextMenuBuilder:
                                    _isDrawingMode
                                        ? null
                                        : (context, editableTextState) {
                                          return AdaptiveTextSelectionToolbar.editableText(
                                            editableTextState:
                                                editableTextState,
                                          );
                                        },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Drawing board overlay - full area
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        return IgnorePointer(
                          ignoring:
                              !_isDrawingMode, // Block drawing interaction when in text mode
                          child: DrawingBoard(
                            controller: _drawingController,
                            background: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                            ),
                            showDefaultActions:
                                _isDrawingMode, // Only show tools in drawing mode
                            showDefaultTools:
                                _isDrawingMode, // Only show tools in drawing mode
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
