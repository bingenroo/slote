import 'dart:convert';
import 'dart:developer';

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
import 'package:flutter_drawing_board/paint_contents.dart';

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

  void _loadDrawingFromJson(List<Map<String, dynamic>> jsonData) {
    final List<PaintContent> contents = [];

    for (final Map<String, dynamic> item in jsonData) {
      final String type = item['type'] as String;

      switch (type) {
        case 'StraightLine':
          contents.add(StraightLine.fromJson(item));
          break;
        case 'SimpleLine':
          contents.add(SimpleLine.fromJson(item));
          break;
        case 'Rectangle':
          contents.add(Rectangle.fromJson(item));
          break;
        case 'Circle':
          contents.add(Circle.fromJson(item));
          break;
        case 'Eraser':
          contents.add(Eraser.fromJson(item));
          break;
        default:
          log('Unknown drawing type: $type');
      }
    }

    if (contents.isNotEmpty) {
      _drawingController.addContents(contents);
    }
  }

  String _getDrawingDataAsJson() {
    final contents = _drawingController.getJsonList();
    return json.encode(contents);
  }

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

      // Load drawing data if it exists
      if (widget.note!.drawingData != null &&
          widget.note!.drawingData!.isNotEmpty) {
        try {
          final List<dynamic> drawingJson = json.decode(
            widget.note!.drawingData!,
          );
          final List<Map<String, dynamic>> drawingData =
              drawingJson.cast<Map<String, dynamic>>();
          _loadDrawingFromJson(drawingData);
        } catch (e) {
          log('Error loading drawing data: $e');
        }
      }
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
    final drawingData = _getDrawingDataAsJson();

    if (widget.note != null) {
      if (title.isEmpty &&
          body.isEmpty &&
          (drawingData.isEmpty || drawingData == '[]')) {
        localDb.deleteNote(id: widget.note!.id);
      } else if (widget.note!.title != title ||
          widget.note!.body != body ||
          widget.note!.drawingData != drawingData) {
        final newNote = widget.note!.copyWith(
          title: title,
          body: body,
          drawingData: drawingData,
        );
        localDb.saveNote(note: newNote);
      }
    } else {
      if (title.isNotEmpty ||
          body.isNotEmpty ||
          (drawingData.isNotEmpty && drawingData != '[]')) {
        final newNote = Note(
          id: Isar.autoIncrement,
          title: title,
          body: body,
          drawingData: drawingData,
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
              child: Scrollbar(
                interactive: true,
                notificationPredicate: (ScrollNotification notification) {
                  // Show scrollbar during any scroll activity
                  return notification.depth == 0;
                },
                child: SingleChildScrollView(
                  physics:
                      _isDrawingMode ? NeverScrollableScrollPhysics() : null,
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          kToolbarHeight -
                          48 -
                          16, // Subtract AppBar, bottom bar, and safe area
                    ),
                    child: Stack(
                      children: [
                        // Text field with padding
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              AbsorbPointer(
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
                                  minLines:
                                      20, // Ensure minimum height for drawing area
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
                            ],
                          ),
                        ),
                        // Drawing board overlay - now part of scrollable content
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
