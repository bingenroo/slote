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
// import 'package:slote/src/functions/stroke_eraser.dart';
import 'package:undo/undo.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'widgets/pixel_detector.dart';
import 'package:slote/src/functions/extended_drawing_controller.dart';

// final _testLine1 = [
//   {
//     "type": "StraightLine",
//     "startPoint": {"dx": 114.5670061088183, "dy": 117.50547159585983},
//     "endPoint": {"dx": 252.9362813512929, "dy": 254.91849554320638},
//     "paint": {
//       "blendMode": 3,
//       "color": 4294198070,
//       "filterQuality": 3,
//       "invertColors": false,
//       "isAntiAlias": false,
//       "strokeCap": 1,
//       "strokeJoin": 1,
//       "strokeWidth": 4.0,
//       "style": 1,
//     },
//   },
//   {
//     "type": "StraightLine",
//     "startPoint": {"dx": 226.6379349225167, "dy": 152.11430225316613},
//     "endPoint": {"dx": 135.67632523940733, "dy": 210.35948249064901},
//     "paint": {
//       "blendMode": 3,
//       "color": 4294198070,
//       "filterQuality": 3,
//       "invertColors": false,
//       "isAntiAlias": false,
//       "strokeCap": 1,
//       "strokeJoin": 1,
//       "strokeWidth": 4.0,
//       "style": 1,
//     },
//   },
// ];

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class NoOpPaintContent extends PaintContent {
  @override
  void startDraw(Offset startPoint) {
    // Do nothing
  }

  @override
  void drawing(Offset nowPoint) {
    // Do nothing
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // Do nothing - don't draw anything
  }

  @override
  PaintContent copy() => NoOpPaintContent();

  @override
  Map<String, dynamic> toJson() => {'type': 'NoOp'};

  @override
  Map<String, dynamic> toContentJson() => {'type': 'NoOp'};
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late final ExtendedDrawingController _drawingController;
  bool _isDrawingMode = false;
  // bool _isStrokeEraserMode = false;
  bool _isEraserStrokeMode = false; // Add this flag

  // late UndoRedoTextController _undoRedoTextController;
  late UnifiedUndoRedoController _unifiedUndoRedoController;
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
        // case 'StrokeEraserContent': // Add this case
        //   contents.add(StrokeEraserContent.fromJson(item));
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

    _drawingController = ExtendedDrawingController();
    _drawingController.setStyle(color: Colors.black);

    // undo redo
    _changeStack = ChangeStack();
    // _undoRedoTextController = UndoRedoTextController(
    //   _changeStack,
    //   _bodyController,
    // );

    _unifiedUndoRedoController = UnifiedUndoRedoController(
      _changeStack,
      _bodyController,
      _drawingController,
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
          // drawingData
          //     .removeLast(); //last array is removable. meaning we can use this to delete strokes
          _loadDrawingFromJson(drawingData);

          // Initialize the undo/redo controller with the loaded state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _unifiedUndoRedoController.initializeWithCurrentState();
          });
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
    // _undoRedoTextController.dispose();

    _unifiedUndoRedoController.dispose();
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
                    // listenable: _undoRedoTextController,
                    listenable: _unifiedUndoRedoController,
                    builder: (context, child) {
                      return IconButton(
                        onPressed:
                            _changeStack.canUndo
                                // ? _undoRedoTextController.undo
                                ? _unifiedUndoRedoController.undo
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
                    // listenable: _undoRedoTextController,
                    listenable: _unifiedUndoRedoController,
                    builder: (context, child) {
                      return IconButton(
                        onPressed:
                            _changeStack.canRedo
                                // ? _undoRedoTextController.redo
                                ? _unifiedUndoRedoController.redo
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
                  if (_isDrawingMode)
                    IconButton(
                      onPressed: () {
                        // Toggle eraser mode
                        // if (_drawingController.drawConfig.value.contentType ==
                        //     Eraser) {
                        if (_isEraserStrokeMode) {
                          // Switch back to drawing mode (SimpleLine)
                          _isEraserStrokeMode = false;
                          _drawingController.setPaintContent(SimpleLine());
                        } else {
                          _isEraserStrokeMode = true;
                          // _drawingController.setPaintContent(Eraser());
                          _drawingController.setPaintContent(
                            NoOpPaintContent(),
                          );
                        }
                        setState(() {}); // Refresh UI to show current tool
                      },
                      icon: Icon(
                        _isEraserStrokeMode ? Icons.brush : Icons.auto_fix_off,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      tooltip:
                          _isEraserStrokeMode ? 'Drawing Mode' : 'Eraser Mode',
                    ),
                  IconButton(
                    icon: Icon(Icons.adb_rounded),
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () {
                      log('button pressed');
                      _drawingController.removeLastContent();
                      // _loadDrawingFromJson(drawingData);
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
                              Widget drawingWidget = DrawingBoard(
                                controller: _drawingController,
                                background: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                ),
                              );
                              if (_isEraserStrokeMode) {
                                drawingWidget = PixelDetector(
                                  drawingData: _getDrawingDataAsJson(),
                                  child: drawingWidget,
                                  onPixelTouched: (offset) {
                                    // No-op, logging is handled inside PixelDetector
                                  },
                                );
                              }
                              return IgnorePointer(
                                ignoring:
                                    !_isDrawingMode, // Block drawing interaction when in text mode
                                child: drawingWidget,
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

      // Remove the _buildTextMode() and _buildDrawingMode() methods
    );
  }
}
