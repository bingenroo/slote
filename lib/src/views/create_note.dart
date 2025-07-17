import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/assets.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/functions/undo_redo.dart';
import 'package:undo/undo.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:slote/src/functions/extended_drawing_controller.dart';
import 'package:slote/src/functions/drawing_utils.dart';

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
  final _drawingController = DrawingController();
  late final ExtendedDrawingController _extendedDrawingController;
  bool _isDrawingMode = false;
  // bool _isStrokeEraserMode = false;
  bool _isEraserStrokeMode = false; // Add this flag

  // late UndoRedoTextController _undoRedoTextController;
  late UnifiedUndoRedoController _unifiedUndoRedoController;
  late ChangeStack _changeStack;

  final localDb = LocalDBService();

  Timer? _eraserThrottleTimer;
  // List<String>? _pendingEraserPoints;
  List<Offset> _currentEraserPath = [];
  Offset? _lastPointerPosition;
  static const double _eraserRadius = 16.0;
  static const double _eraserSampleDistance = 5.0;

  // New: Track only the current eraser cursor position for visualization
  Offset? _eraserCursorPosition;

  String _getDrawingDataAsJson() {
    final contents = _drawingController.getJsonList();
    return json.encode(contents);
  }

  void _handleEraserStart(Offset pos) {
    _currentEraserPath = [pos];
    _lastPointerPosition = pos;
    _eraserCursorPosition = pos; // Track for visual
    setState(() {});
  }

  Timer? _processTimer;
  void _handleEraserUpdate(Offset pos) {
    if (_lastPointerPosition == null ||
        (pos - _lastPointerPosition!).distance > _eraserSampleDistance) {
      _currentEraserPath.add(pos);
      _lastPointerPosition = pos;
      _eraserCursorPosition = pos; // Track for visual

      // Throttle processing to every 16ms (~60fps)
      _processTimer?.cancel();
      _processTimer = Timer(const Duration(milliseconds: 16), () {
        final points =
            _currentEraserPath.map((e) => '(${e.dx},${e.dy})').toList();
        _extendedDrawingController.processEraserPoints(
          points,
          eraserRadius: _eraserRadius,
        );
      });

      setState(() {});
    }
  }

  void _handleEraserEnd() {
    if (_currentEraserPath.isNotEmpty) {
      final pointsAsString =
          _currentEraserPath.map((e) => '(${e.dx},${e.dy})').toList();
      _extendedDrawingController.processEraserPoints(
        pointsAsString,
        eraserRadius: _eraserRadius,
      );
    }
    _currentEraserPath.clear();
    _lastPointerPosition = null;
    _eraserCursorPosition = null; // Clear visual
    setState(() {});
  }

  void _trackDrawingChanges() {
    final currentStrokes = _drawingController.getJsonList();
    _extendedDrawingController.trackNewStrokes(currentStrokes);
  }

  @override
  void initState() {
    super.initState();

    _drawingController.setStyle(color: Colors.black);
    _extendedDrawingController = ExtendedDrawingController(_drawingController);

    _drawingController.addListener(_trackDrawingChanges);

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
          final List<PaintContent> contents = paintContentsFromJson(
            drawingJson,
          );
          if (contents.isNotEmpty) {
            _drawingController.addContents(contents);
          }

          // Initialize the undo/redo controller with the loaded state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _unifiedUndoRedoController.initializeWithCurrentState();
            _extendedDrawingController.initialize(
              _drawingController.getJsonList(),
            );
          });
        } catch (e) {
          // log('Error loading drawing data: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _eraserThrottleTimer?.cancel();
    _saveNoteData();
    _drawingController.removeListener(_trackDrawingChanges);

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
        await localDb.deleteNote(id: widget.note!.id);
      } else if (widget.note!.title != title ||
          widget.note!.body != body ||
          widget.note!.drawingData != drawingData) {
        final newNote = widget.note!.copyWith(
          title: title,
          body: body,
          drawingData: drawingData,
        );
        await localDb.saveNote(note: newNote);
      }
    } else {
      if (title.isNotEmpty ||
          body.isNotEmpty ||
          (drawingData.isNotEmpty && drawingData != '[]')) {
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF,
          title: title,
          body: body,
          drawingData: drawingData,
          lastMod: DateTime.now(),
        );
        await localDb.saveNote(note: newNote);
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
                  // IconButton(
                  //   icon: Icon(Icons.adb_rounded),
                  //   color: Theme.of(context).colorScheme.onPrimary,
                  //   onPressed: () {
                  //     log('button pressed');
                  //     _drawingController.removeLastContent();
                  //     // _loadDrawingFromJson(drawingData);
                  //   },
                  // ),
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
                                child: Stack(
                                  children: [
                                    // Always show the drawing board with existing drawings
                                    DrawingBoard(
                                      controller: _drawingController,
                                      background: SizedBox(
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                      ),
                                    ),
                                    // Show eraser overlay only when in eraser mode
                                    if (_isEraserStrokeMode)
                                      GestureDetector(
                                        onPanStart: (details) {
                                          final local = (context
                                                      .findRenderObject()
                                                  as RenderBox)
                                              .globalToLocal(
                                                details.globalPosition,
                                              );
                                          _handleEraserStart(local);
                                        },
                                        onPanUpdate: (details) {
                                          final local = (context
                                                      .findRenderObject()
                                                  as RenderBox)
                                              .globalToLocal(
                                                details.globalPosition,
                                              );
                                          _handleEraserUpdate(local);
                                        },
                                        onPanEnd: (_) {
                                          _handleEraserEnd();
                                        },
                                        child: CustomPaint(
                                          painter: _EraserCursorPainter(
                                            _eraserCursorPosition,
                                            _eraserRadius,
                                          ),
                                          size: Size.infinite,
                                        ),
                                      ),
                                  ],
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

      // Remove the _buildTextMode() and _buildDrawingMode() methods
    );
  }
}

// New: Modern eraser cursor painter
class _EraserCursorPainter extends CustomPainter {
  final Offset? position;
  final double radius;
  _EraserCursorPainter(this.position, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    if (position == null) return;
    final eraserRadius = radius * 0.7;
    // Draw shadow (blurred dark circle)
    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, eraserRadius * 0.7);
    canvas.drawCircle(position!, eraserRadius, shadowPaint);
    // Draw solid gray eraser
    canvas.drawCircle(
      position!,
      eraserRadius,
      Paint()..color = Colors.grey[400]!.withValues(alpha: 0.85),
    );
    // No white center, no halo
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.radius != radius;
  }
}
