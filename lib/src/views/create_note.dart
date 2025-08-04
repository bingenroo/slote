import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/assets.dart';
import 'package:slote/src/services/local_db.dart';
import 'package:slote/src/functions/undo_redo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'dart:developer';
import 'package:scribble/scribble.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key, this.note});

  final Note? note;

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();

  // Drawing mode state and flags
  bool _isDrawingMode = false;
  // bool _isEraserStrokeMode = false;
  bool _isZoomed = false;
  bool _isDrawingActive = false;

  int _activePointers = 0;
  // int? _activeToolPointerId;
  // final GlobalKey _painterKey = GlobalKey();

  final TransformationController _transformController =
      TransformationController();

  // Zoom and pan state
  final double _scale = 1.0;
  final double _minScale = 0.5;
  final double _maxScale = 3.0;

  // Undo/Redo state
  late UnifiedUndoRedoController _unifiedUndoRedoController;

  late ScribbleNotifier _scribbleNotifier;
  String get drawingData {
    return json.encode(_scribbleNotifier.currentSketch.toJson());
  }

  // bool get _isEraserMode => _scribbleNotifier.value is Erasing;

  // Pen settings state
  Color _penColor = Colors.black;
  double _penStrokeWidth = 2.0;
  final double _eraserStrokeWidth = 15.0;
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

  final localDb = LocalDBService();

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
                            _scribbleNotifier.setStrokeWidth(tempStrokeWidth);
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
                              _scribbleNotifier.setStrokeWidth(tempStrokeWidth);
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
                            _scribbleNotifier.setStrokeWidth(tempStrokeWidth);
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
                                _scribbleNotifier.setColor(tempPenColor);
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
                          _scribbleNotifier.setStrokeWidth(tempStrokeWidth);
                          _scribbleNotifier.setColor(tempPenColor);
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

  void _saveNoteData() async {
    final title = _titleController.text;
    final body = _bodyController.text;
    final hasDrawing = drawingData.isNotEmpty && drawingData != '[]';

    if (title.isEmpty && body.isEmpty && !hasDrawing) {
      return;
    }

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
  void initState() {
    super.initState();

    _scribbleNotifier = ScribbleNotifier();

    // Initialize with default pen settings
    _scribbleNotifier.setColor(_penColor);
    _scribbleNotifier.setStrokeWidth(_penStrokeWidth);

    // _scribbleNotifier = ScribbleNotifier(
    //   // Only allow single finger touches for drawing
    //   allowedPointersMode: ScribblePointerMode.penOnly,
    // );

    // undo redo
    _unifiedUndoRedoController = UnifiedUndoRedoController(
      textController: _bodyController,
      scribbleNotifier: _scribbleNotifier,
      maxHistoryLength: 50,
    );

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _bodyController.text = widget.note!.body;

      try {
        // Load drawing data if it exists
        if (widget.note!.drawingData != null &&
            widget.note!.drawingData!.isNotEmpty) {
          final sketchData = json.decode(widget.note!.drawingData!);
          final sketch = Sketch.fromJson(sketchData);
          _scribbleNotifier.setSketch(sketch: sketch, addToUndoHistory: false);
        }
      } catch (e) {
        // Handle error silently - invalid drawing data
      }

      // Initialize the undo/redo controller with the loaded state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _unifiedUndoRedoController.initializeWithCurrentState();
      });
    }
  }

  @override
  void dispose() {
    _saveNoteData();

    _titleController.dispose();
    _bodyController.dispose();
    _scrollController.dispose();
    _unifiedUndoRedoController.dispose();
    _scribbleNotifier.dispose();

    super.dispose();
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
                  ValueListenableBuilder(
                    valueListenable: _scribbleNotifier,
                    builder:
                        (context, value, child) => IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.arrowRotateLeft,
                            size: 20,
                            color:
                                _scribbleNotifier.canUndo
                                    ? Colors.black
                                    : Colors.grey.shade300,
                          ),
                          onPressed:
                              _scribbleNotifier.canUndo
                                  ? _scribbleNotifier.undo
                                  : null,
                          tooltip: 'Undo',
                        ),
                  ),
                  // Redo
                  ValueListenableBuilder(
                    valueListenable: _scribbleNotifier,
                    builder:
                        (context, value, child) => IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.arrowRotateRight,
                            size: 20,
                            color:
                                _scribbleNotifier.canRedo
                                    ? Colors.black
                                    : Colors.grey.shade300,
                          ),
                          onPressed:
                              _scribbleNotifier.canRedo
                                  ? _scribbleNotifier.redo
                                  : null,
                          tooltip: 'Redo',
                        ),
                  ),
                  // Only show Pen and Eraser in drawing mode
                  if (_isDrawingMode) ...[
                    // Pen
                    ValueListenableBuilder(
                      valueListenable: _scribbleNotifier,
                      builder:
                          (context, value, child) => IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.pen,
                              size: 20,
                              color:
                                  value is Erasing
                                      ? Colors.grey.shade300
                                      : _penColor,
                            ),
                            onPressed: () {
                              if (value is Erasing) {
                                _scribbleNotifier.setColor(_penColor);
                                _scribbleNotifier.setStrokeWidth(
                                  _penStrokeWidth,
                                );
                              } else {
                                _showPenSettingsPopup();
                              }
                            },
                            tooltip: 'Pen',
                          ),
                    ),
                    // Eraser
                    ValueListenableBuilder(
                      valueListenable: _scribbleNotifier,
                      builder:
                          (context, value, child) => IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.eraser,
                              size: 20,
                              color:
                                  value is Erasing
                                      ? Colors.black
                                      : Colors.grey.shade300,
                            ),
                            onPressed: () {
                              if (_scribbleNotifier.value is Erasing) return;
                              if (value is Erasing) {
                                // Switch back to drawing mode
                                _scribbleNotifier.setColor(_penColor);
                                _scribbleNotifier.setStrokeWidth(
                                  _penStrokeWidth,
                                );
                              } else {
                                // Switch to eraser mode
                                _scribbleNotifier.setEraser();
                                _scribbleNotifier.setStrokeWidth(
                                  _eraserStrokeWidth,
                                );
                              }
                            },
                            tooltip: 'Eraser',
                          ),
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
            // Zoomable and pannable content area
            Expanded(
              child: InteractiveViewer(
                panEnabled: !_isDrawingActive || _activePointers > 1,
                scaleEnabled: !_isDrawingActive || _activePointers > 1,
                transformationController: _transformController,
                minScale: _minScale,
                maxScale: _maxScale,
                scaleFactor: 1000.0,
                onInteractionStart: (details) {
                  setState(() {
                    _activePointers = details.pointerCount;
                    // Reset drawing when multi-touch starts
                    if (details.pointerCount > 1) _isDrawingActive = false;
                  });
                },
                onInteractionUpdate: (details) {
                  setState(() {
                    _activePointers = details.pointerCount;
                    _isZoomed =
                        _transformController.value.getMaxScaleOnAxis() > 1.0;
                  });
                },
                onInteractionEnd: (details) {
                  setState(() {
                    _activePointers = 0;
                    _isDrawingActive = false;
                    _isZoomed =
                        _transformController.value.getMaxScaleOnAxis() > 1.0;
                  });
                },
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: !_isZoomed && !_isDrawingMode,
                  trackVisibility: false,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics:
                        (_isZoomed || _isDrawingMode) && _activePointers < 2
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Transform.scale(
                      scale: _scale,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Combined text and drawing area
                          Stack(
                            children: [
                              // Text field (always visible) - with minimum height
                              Container(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(context).size.height -
                                      MediaQuery.of(context).padding.top -
                                      kToolbarHeight -
                                      38 - // toolbar bottom height
                                      20, // padding
                                ),
                                child: TextFormField(
                                  controller: _bodyController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Start Sloting...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade300,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 20),
                                  maxLines: null,
                                  textInputAction: TextInputAction.newline,
                                  keyboardType: TextInputType.multiline,
                                ),
                              ),

                              // Drawing layer (always visible) - on top
                              Positioned.fill(
                                child: IgnorePointer(
                                  // Only ignore when:
                                  // 1. Not in drawing mode AND single pointer (normal text editing)
                                  // OR
                                  // 2. Multi-touch (zoom/pan)
                                  ignoring:
                                      (!_isDrawingMode &&
                                          _activePointers < 2) ||
                                      _activePointers > 1,
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: (event) {
                                      if (_isDrawingMode &&
                                          _activePointers < 2) {
                                        setState(() => _isDrawingActive = true);
                                      }
                                    },
                                    onPointerUp: (event) {
                                      if (_activePointers <= 1) {
                                        setState(
                                          () => _isDrawingActive = false,
                                        );
                                      }
                                    },
                                    child: Scribble(
                                      notifier: _scribbleNotifier,
                                      drawPen:
                                          _isDrawingActive && _isDrawingMode,
                                      enableGestureCatcher:
                                          false, // Disable gesture catcher for InteractiveViewer integration
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Add some bottom padding for better scrolling
                          const SizedBox(height: 10),
                        ],
                      ),
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
