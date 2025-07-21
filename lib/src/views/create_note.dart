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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:slote/src/functions/drawing_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

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

  // Add for zoom/pan
  final TransformationController _transformController =
      TransformationController();
  int _pointerCount = 0;
  bool _isCtrlPressed = false;
  final GlobalKey _painterKey = GlobalKey();

  bool _isFrameLocked = true; // Start in editing mode

  // Pen settings state
  Color _penColor = Colors.black;
  double _penStrokeWidth = 2.0;
  final List<Color> _penColors = [
    Colors.black,
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];
  final double _minStroke = 1.0;
  final double _maxStroke = 12.0;

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

  void _showPenSettingsPopup() async {
    double tempStrokeWidth = _penStrokeWidth;
    Color tempPenColor = _penColor;
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor:
              Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stroke size slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                            setStateDialog(() {
                              tempStrokeWidth = (tempStrokeWidth - 1).clamp(
                                _minStroke,
                                _maxStroke,
                              );
                            });
                            _drawingController.setStyle(
                              strokeWidth: tempStrokeWidth,
                            );
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: tempStrokeWidth,
                            min: _minStroke,
                            max: _maxStroke,
                            divisions: (_maxStroke - _minStroke).toInt(),
                            // label: tempStrokeWidth.round().toString(), // Removed to hide droplet
                            onChanged: (value) {
                              setStateDialog(() {
                                tempStrokeWidth = value;
                              });
                              _drawingController.setStyle(
                                strokeWidth: tempStrokeWidth,
                              );
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            setStateDialog(() {
                              tempStrokeWidth = (tempStrokeWidth + 1).clamp(
                                _minStroke,
                                _maxStroke,
                              );
                            });
                            _drawingController.setStyle(
                              strokeWidth: tempStrokeWidth,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Color swatches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          _penColors.map((color) {
                            final isSelected = color == tempPenColor;
                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  tempPenColor = color;
                                });
                                _drawingController.setStyle(
                                  color: tempPenColor,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                width: isSelected ? 36 : 28,
                                height: isSelected ? 36 : 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                          : null,
                                ),
                                child:
                                    isSelected
                                        ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Done button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _penStrokeWidth = tempStrokeWidth;
                            _penColor = tempPenColor;
                          });
                          _drawingController.setStyle(
                            color: _penColor,
                            strokeWidth: _penStrokeWidth,
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Helper to convert global to local coordinates (no matrix transform needed now)
  Offset _globalToLocal(Offset global) {
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(global);
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
          final List<PaintContent> contents =
              drawingJson.map((json) {
                if (json['type'] == 'SimpleLine') {
                  return SimpleLine.fromJson(json);
                } else if (json['type'] == 'Eraser') {
                  return Eraser.fromJson(json);
                }
                return NoOpPaintContent(); // Fallback for unknown types
              }).toList();
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
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  @override
  void dispose() {
    _eraserThrottleTimer?.cancel();
    _saveNoteData();
    _drawingController.removeListener(_trackDrawingChanges);
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);

    _titleController.dispose();
    _bodyController.dispose();
    // _undoRedoTextController.dispose();

    _unifiedUndoRedoController.dispose();
    _drawingController.dispose();

    super.dispose();
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    setState(() {
      _isCtrlPressed = event.isControlPressed;
    });
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
        toolbarHeight: 52, // Smaller height
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 20, // Smaller icon
            color: Theme.of(context).colorScheme.onPrimary,
          ),
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
            fontSize: 20, // Smaller title font
            color: Theme.of(context).colorScheme.onPrimary,
            decorationColor: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.start,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          // Restore text/draw mode toggle
          IconButton(
            icon:
                _isDrawingMode
                    ? FaIcon(
                      FontAwesomeIcons.font,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                    : FaIcon(
                      FontAwesomeIcons.pen,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _isDrawingMode = !_isDrawingMode;
                if (_isDrawingMode) {
                  _bodyController.selection = TextSelection.collapsed(
                    offset: _bodyController.selection.baseOffset,
                  );
                }
              });
            },
            tooltip: _isDrawingMode ? 'Text Mode' : 'Drawing Mode',
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.trash,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed:
                widget.note == null
                    ? null
                    : () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                              "Delete Note?",
                              style: GoogleFonts.poppins(fontSize: 18),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Lottie.asset(AnimationAssets.delete),
                                Text(
                                  "Are you sure you want to delete this note permernantly?",
                                  style: GoogleFonts.poppins(fontSize: 15),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (widget.note != null) {
                                    localDb.deleteNote(id: widget.note!.id);
                                  }
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
            tooltip: 'Delete',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(38), // Slightly smaller than AppBar
          child: Material(
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Set to grey
                // Removed border
              ),
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Undo
                  ListenableBuilder(
                    listenable: _unifiedUndoRedoController,
                    builder: (context, child) {
                      final bool enabled = _changeStack.canUndo;
                      return IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.arrowRotateLeft,
                          size: 20,
                          color: enabled ? Colors.black : Colors.grey.shade300,
                        ),
                        onPressed:
                            enabled ? _unifiedUndoRedoController.undo : null,
                        tooltip: 'Undo',
                      );
                    },
                  ),
                  // Redo
                  ListenableBuilder(
                    listenable: _unifiedUndoRedoController,
                    builder: (context, child) {
                      final bool enabled = _changeStack.canRedo;
                      return IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.arrowRotateRight,
                          size: 20,
                          color: enabled ? Colors.black : Colors.grey.shade300,
                        ),
                        onPressed:
                            enabled ? _unifiedUndoRedoController.redo : null,
                        tooltip: 'Redo',
                      );
                    },
                  ),
                  // Only show Pen and Eraser in drawing mode
                  if (_isDrawingMode) ...[
                    // Pen
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.pen,
                        size: 20,
                        color:
                            !_isEraserStrokeMode
                                ? _penColor
                                : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        if (_isEraserStrokeMode) {
                          setState(() {
                            _isEraserStrokeMode = false;
                            _drawingController.setPaintContent(SimpleLine());
                          });
                        } else {
                          _showPenSettingsPopup();
                        }
                      },
                      tooltip: 'Pen',
                    ),
                    // Eraser
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.eraser,
                        size: 20,
                        color:
                            _isEraserStrokeMode
                                ? Colors.black
                                : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEraserStrokeMode = true;
                          _drawingController.setPaintContent(
                            NoOpPaintContent(),
                          );
                        });
                      },
                      tooltip: 'Eraser',
                    ),
                  ],
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
                          16,
                    ),
                    // --- REPLACE Stack with InteractiveViewer ---
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      boundaryMargin: EdgeInsets.zero,
                      constrained: true,
                      minScale: 1.0,
                      maxScale: 10.0,
                      panEnabled:
                          !_isFrameLocked, // Only allow pan when frame unlocked
                      scaleEnabled:
                          !_isFrameLocked, // Only allow zoom when frame unlocked
                      onInteractionStart: (details) {
                        setState(() {
                          _pointerCount = details.pointerCount;
                          _isFrameLocked =
                              _pointerCount == 1; // Lock when only one finger
                        });
                      },
                      onInteractionEnd: (details) {
                        setState(() {
                          _pointerCount = 0;
                          _isFrameLocked =
                              true; // Lock by default when no interaction
                        });
                      },
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              children: [
                                AbsorbPointer(
                                  absorbing: _isDrawingMode,
                                  child: TextField(
                                    controller: _bodyController,
                                    decoration: InputDecoration(
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      hintText: "Description",
                                      hintStyle: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(30),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15, // Modern note app size
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      decorationColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    maxLines: null,
                                    minLines: 20,
                                    readOnly: _isDrawingMode,
                                    enableInteractiveSelection: !_isDrawingMode,
                                    cursorColor:
                                        Theme.of(context).colorScheme.onSurface,
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
                          // Drawing overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: !_isDrawingMode,
                              child: Listener(
                                onPointerDown: (event) {
                                  if (_isFrameLocked) {
                                    final renderBox =
                                        _painterKey.currentContext
                                                ?.findRenderObject()
                                            as RenderBox?;
                                    if (renderBox == null) return;

                                    // Get correct local position with transformation
                                    final local = _getLocalPosition(
                                      renderBox,
                                      event.position,
                                      _transformController,
                                    );

                                    if (_isDrawingMode) {
                                      if (_isEraserStrokeMode) {
                                        _handleEraserStart(local);
                                      } else {
                                        _drawingController.startDraw(local);
                                      }
                                    }
                                  }
                                },
                                onPointerMove: (event) {
                                  if (_isFrameLocked) {
                                    final renderBox =
                                        _painterKey.currentContext
                                                ?.findRenderObject()
                                            as RenderBox?;
                                    if (renderBox == null) return;

                                    final local = _getLocalPosition(
                                      renderBox,
                                      event.position,
                                      _transformController,
                                    );

                                    if (_isDrawingMode) {
                                      if (_isEraserStrokeMode) {
                                        _handleEraserUpdate(local);
                                      } else {
                                        _drawingController.drawing(local);
                                      }
                                    }
                                  }
                                },
                                onPointerUp: (event) {
                                  if (_isFrameLocked) {
                                    if (_isDrawingMode) {
                                      if (_isEraserStrokeMode) {
                                        _handleEraserEnd();
                                      } else {
                                        _drawingController.endDraw();
                                      }
                                    }
                                  }
                                },
                                child: Stack(
                                  children: [
                                    // Drawing painter
                                    RepaintBoundary(
                                      key: _painterKey,
                                      child: CustomPaint(
                                        painter: _DrawingPainter(
                                          controller: _drawingController,
                                        ),
                                        size: Size.infinite,
                                      ),
                                    ),
                                    // Eraser cursor overlay
                                    if (_isEraserStrokeMode)
                                      CustomPaint(
                                        painter: _EraserCursorPainter(
                                          _eraserCursorPosition,
                                          _eraserRadius,
                                        ),
                                        size: Size.infinite,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ), // end InteractiveViewer child
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

Offset _getLocalPosition(
  RenderBox renderBox,
  Offset globalPosition,
  TransformationController transformController,
) {
  final local = renderBox.globalToLocal(globalPosition);

  // Apply inverse transformation if InteractiveViewer is transformed
  if (transformController.value != Matrix4.identity()) {
    final inverseMatrix = Matrix4.tryInvert(transformController.value);
    if (inverseMatrix != null) {
      return MatrixUtils.transformPoint(inverseMatrix, local);
    }
  }
  return local;
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

// Add custom painter for drawing overlay
class _DrawingPainter extends CustomPainter {
  final DrawingController controller;
  _DrawingPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Get all finished contents
    final contents = paintContentsFromJson(controller.getJsonList());

    // Draw all finished strokes
    for (final content in contents) {
      content.draw(canvas, size, false);
    }

    // Get current stroke if exists (this is the Flutter Drawing Board internal way)
    final currentContent = controller.currentContent;
    if (currentContent != null) {
      currentContent.draw(canvas, size, false);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
