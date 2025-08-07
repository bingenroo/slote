import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:slote/src/model/note.dart';
import 'package:slote/src/res/assets.dart';
import 'package:slote/src/res/theme_config.dart';
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

class _CreateNoteViewState extends State<CreateNoteView>
    with WidgetsBindingObserver {
  Note? _currentNote;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();

  // Orientation tracking
  Orientation? _previousOrientation;
  Size? _previousSize;
  bool _isRotating = false;
  double?
  _portraitHeight; // Store the portrait height as the fixed canvas height

  // save settings
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  static const Duration _autoSaveDelay = Duration(seconds: 2);

  // Drawing mode state and flags
  bool _isDrawingMode = false;
  // bool _isEraserStrokeMode = false;
  bool _isZoomed = false;
  bool _isDrawingActive = false;
  int _pointerCount = 0;

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

  bool get hasDrawingContent {
    try {
      final sketch = _scribbleNotifier.currentSketch;
      final jsonData = sketch.toJson();
      // Check if the sketch has any lines (drawing strokes)
      final hasLines =
          jsonData['lines'] != null &&
          jsonData['lines'] is List &&
          (jsonData['lines'] as List).isNotEmpty;

      return hasLines;
    } catch (e) {
      return false;
    }
  }

  // bool get _isEraserMode => _scribbleNotifier.value is Erasing;

  double _currentZoomScale = 1.0;
  final double _baseEraserStrokeWidth = 15.0; // Base eraser size at 1.0 zoom
  // Add this method to calculate zoom-adjusted eraser size
  double get _zoomAdjustedEraserSize {
    return _baseEraserStrokeWidth / _currentZoomScale;
  }

  // Get current canvas dimensions
  Size get _canvasSize {
    final currentSize = MediaQuery.of(context).size;
    final currentOrientation = MediaQuery.of(context).orientation;

    if (_portraitHeight != null) {
      // Fixed height based on portrait, width can vary
      return Size(
        currentSize.width,
        _portraitHeight! -
            MediaQuery.of(context).padding.top -
            kToolbarHeight -
            38 -
            20,
      );
    } else {
      // Fallback to current size
      return currentSize;
    }
  }

  // Pen settings state
  late Color _penColor;
  double _penStrokeWidth = 2.0;
  // final double _eraserStrokeWidth = 15.0;
  bool _hasUserSetColor = false; // Track if user has manually set a color

  List<Color> get _penColors {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        Colors.white, // White first for dark mode
        Colors.red,
        Colors.yellow,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange,
        Colors.black, // Black last for dark mode
      ];
    } else {
      return [
        Colors.black, // Black first for light mode
        Colors.red,
        Colors.yellow,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange,
        Colors.white, // White last for light mode
      ];
    }
  }

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
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  valueIndicatorColor:
                                      Colors
                                          .white, // Background color of the label
                                  valueIndicatorTextStyle: TextStyle(
                                    color:
                                        Colors.black, // Text color of the label
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Slider(
                                  value: tempStrokeWidth,
                                  min: _minStroke,
                                  max: _maxStroke,
                                  divisions: (_maxStroke - _minStroke).toInt(),
                                  label: tempStrokeWidth.round().toString(),
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      tempStrokeWidth = value;
                                    });
                                    _scribbleNotifier.setStrokeWidth(
                                      tempStrokeWidth,
                                    );
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white24,
                                ),
                              ),
                            ],
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
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              _penColors.map((color) {
                                final isSelected = color == tempPenColor;
                                return GestureDetector(
                                  onTap: () {
                                    setStateDialog(() {
                                      tempPenColor = color;
                                    });
                                    // Apply the color immediately to the scribble notifier
                                    _scribbleNotifier.setColor(color);
                                    // Mark that user has set a color
                                    _hasUserSetColor = true;
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
                      ),
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
                            _hasUserSetColor =
                                true; // Mark that user has set a color
                          });
                          // Ensure the scribble notifier has the final settings
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

  // Add this method to update eraser size when zoom changes
  void _updateEraserSizeForZoom() {
    if (_scribbleNotifier.value is Erasing) {
      _scribbleNotifier.setStrokeWidth(_zoomAdjustedEraserSize);
    }
  }

  // Handle orientation changes and scale drawings accordingly
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOrientationChange();
    });
  }

  void _handleOrientationChange() {
    final currentOrientation = MediaQuery.of(context).orientation;
    final currentSize = MediaQuery.of(context).size;

    // Initialize portrait height on first call
    if (_portraitHeight == null) {
      _portraitHeight =
          currentOrientation == Orientation.portrait
              ? currentSize.height
              : currentSize.width; // In landscape, height becomes width
    }

    // Skip if this is the first time or if we're already handling rotation
    if (_previousOrientation == null || _isRotating) {
      _previousOrientation = currentOrientation;
      _previousSize = currentSize;
      return;
    }

    // Check if orientation actually changed
    if (_previousOrientation != currentOrientation) {
      setState(() {
        _isRotating = true;
      });

      // Scale the drawing based on the new dimensions with fixed height
      _scaleDrawingForFixedHeight(_previousSize!, currentSize);

      _previousOrientation = currentOrientation;
      _previousSize = currentSize;

      // Reset rotation flag after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isRotating = false;
          });
        }
      });
    }
  }

  void _scaleDrawingForFixedHeight(Size oldSize, Size newSize) {
    try {
      final currentSketch = _scribbleNotifier.currentSketch;
      if (currentSketch.lines.isEmpty) return;

      // Only scale horizontally (width), keep height fixed
      final scaleX = newSize.width / oldSize.width;
      final scaleY = 1.0; // No vertical scaling - height remains constant

      // Skip scaling if the horizontal change is too small
      if ((scaleX - 1.0).abs() < 0.01) {
        return;
      }

      // Create a new sketch with scaled coordinates
      final scaledLines = <SketchLine>[];

      for (final line in currentSketch.lines) {
        final scaledPoints = <Point>[];

        for (final point in line.points) {
          // Scale only the X coordinate, keep Y coordinate unchanged
          final scaledPoint = Point(
            point.x * scaleX,
            point.y, // Keep Y coordinate unchanged
            pressure: point.pressure,
          );
          scaledPoints.add(scaledPoint);
        }

        // Create new line with scaled points
        final scaledLine = SketchLine(
          points: scaledPoints,
          width: line.width,
          color: line.color,
        );
        scaledLines.add(scaledLine);
      }

      // Create new sketch with scaled lines
      final scaledSketch = Sketch(lines: scaledLines);

      // Update the scribble notifier with the scaled sketch
      _scribbleNotifier.setSketch(
        sketch: scaledSketch,
        addToUndoHistory: false,
      );
    } catch (e) {
      // Handle any errors during scaling
      print('Error scaling drawing for fixed height: $e');
    }
  }

  void _scheduleAutoSave() {
    final title = _titleController.text;
    final body = _bodyController.text;
    final hasDrawing = hasDrawingContent;

    // Only set unsaved changes if there's actual content
    if (title.isNotEmpty || body.isNotEmpty || hasDrawing) {
      _hasUnsavedChanges = true;

      // Cancel existing timer
      _autoSaveTimer?.cancel();

      // Schedule new auto-save
      _autoSaveTimer = Timer(_autoSaveDelay, () {
        if (_hasUnsavedChanges) {
          _saveNoteData();
          _hasUnsavedChanges = false;
        }
      });
    }
  }

  void _saveNoteData() async {
    final title = _titleController.text;
    final body = _bodyController.text;
    final hasDrawing = hasDrawingContent;

    // Don't save if there's no content at all
    if (title.isEmpty && body.isEmpty && !hasDrawing) {
      return;
    }

    if (_currentNote != null) {
      // For existing notes
      if (title.isEmpty && body.isEmpty && !hasDrawing) {
        // Delete if no content at all
        await localDb.deleteNote(id: _currentNote!.id);
      } else if (_currentNote!.title != title ||
          _currentNote!.body != body ||
          _currentNote!.drawingData != drawingData) {
        // Save if content has changed
        final newNote = _currentNote!.copyWith(
          title: title,
          body: body,
          drawingData: drawingData,
        );
        await localDb.saveNote(note: newNote);
      }
    } else {
      // For new notes - save if there's any content
      if (title.isNotEmpty || body.isNotEmpty || hasDrawing) {
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF,
          title: title,
          body: body,
          drawingData: drawingData,
          lastMod: DateTime.now(),
        );
        await localDb.saveNote(note: newNote);

        // Update the current note reference for future saves
        _currentNote = newNote;
      }
    }
  }

  void _handleBackNavigation() {
    // Cancel any pending auto-save timer
    _autoSaveTimer?.cancel();

    // Save immediately if there are unsaved changes and there's actual content
    if (_hasUnsavedChanges) {
      _saveNoteData();
      _hasUnsavedChanges = false;
    }

    // Navigate back
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    // Add orientation observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize current note from widget
    _currentNote = widget.note;

    _scribbleNotifier = ScribbleNotifier(
      // Enable straight line detection with 500ms hold duration
      straightLineHoldDuration: const Duration(milliseconds: 1000),
      enableStraightLineConversion: true,
    );

    // Listeners for auto-save
    _titleController.addListener(_scheduleAutoSave);
    _bodyController.addListener(_scheduleAutoSave);
    _scribbleNotifier.addListener(_scheduleAutoSave);

    // _scribbleNotifier = ScribbleNotifier(
    //   // Only allow single finger touches for drawing
    //   allowedPointersMode: ScribblePointerMode.penOnly,
    // );

    // undo redo
    _unifiedUndoRedoController = UnifiedUndoRedoController(
      textController: _bodyController,
      scribbleNotifier: _scribbleNotifier,
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
    }

    // Initialize the undo/redo controller with the current state (for both new and existing notes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unifiedUndoRedoController.initializeWithCurrentState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize portrait height if not set
    if (_portraitHeight == null) {
      final currentSize = MediaQuery.of(context).size;
      final currentOrientation = MediaQuery.of(context).orientation;
      _portraitHeight =
          currentOrientation == Orientation.portrait
              ? currentSize.height
              : currentSize.width; // In landscape, height becomes width
    }

    // Only initialize pen color based on theme if user hasn't manually set a color
    if (!_hasUserSetColor) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _penColor = isDark ? Colors.white : Colors.black;

      // Initialize with default pen settings
      _scribbleNotifier.setColor(_penColor);
      _scribbleNotifier.setStrokeWidth(_penStrokeWidth);
    }
  }

  @override
  void dispose() {
    // Remove orientation observer
    WidgetsBinding.instance.removeObserver(this);

    // Save immediately on dispose if there are unsaved changes
    if (_hasUnsavedChanges) {
      _saveNoteData();
    }

    _autoSaveTimer?.cancel();
    _titleController.removeListener(_scheduleAutoSave);
    _bodyController.removeListener(_scheduleAutoSave);
    _scribbleNotifier.removeListener(_scheduleAutoSave);

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
            _handleBackNavigation();
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
            fontSize: AppThemeConfig.titleFontSize,
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
                color:
                    Theme.of(context)
                        .bottomNavigationBarTheme
                        .backgroundColor, // Use theme instead of hardcoded color
                // Removed border
              ),
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Undo
                  ListenableBuilder(
                    listenable: _unifiedUndoRedoController,
                    builder:
                        (context, child) => IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.arrowRotateLeft,
                            size: 20,
                            color:
                                _unifiedUndoRedoController.canUndo
                                    ? Theme.of(context)
                                        .bottomNavigationBarTheme
                                        .selectedItemColor // Use theme color instead of hardcoded black
                                    : Theme.of(context)
                                        .bottomNavigationBarTheme
                                        .unselectedItemColor,
                          ),
                          onPressed:
                              _unifiedUndoRedoController.canUndo
                                  ? _unifiedUndoRedoController.undo
                                  : null,
                          tooltip: 'Undo',
                        ),
                  ),
                  // Redo
                  ListenableBuilder(
                    listenable: _unifiedUndoRedoController,
                    builder:
                        (context, child) => IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.arrowRotateRight,
                            size: 20,
                            color:
                                _unifiedUndoRedoController.canRedo
                                    ? Theme.of(context)
                                        .bottomNavigationBarTheme
                                        .selectedItemColor // Use theme color instead of hardcoded black
                                    : Theme.of(context)
                                        .bottomNavigationBarTheme
                                        .unselectedItemColor,
                          ),
                          onPressed:
                              _unifiedUndoRedoController.canRedo
                                  ? _unifiedUndoRedoController.redo
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
                                      ? Theme.of(context)
                                          .bottomNavigationBarTheme
                                          .unselectedItemColor
                                      : _penColor,
                            ),
                            onPressed: () {
                              if (value is Erasing) {
                                // Switch back to pen mode with current settings
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
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface // Use theme color instead of hardcoded black
                                      : Theme.of(context)
                                          .bottomNavigationBarTheme
                                          .unselectedItemColor,
                            ),
                            onPressed: () {
                              if (_scribbleNotifier.value is Erasing) return;
                              if (value is Erasing) {
                                // Switch back to drawing mode with current pen settings
                                _scribbleNotifier.setColor(_penColor);
                                _scribbleNotifier.setStrokeWidth(
                                  _penStrokeWidth,
                                );
                              } else {
                                // Switch to eraser mode
                                _scribbleNotifier.setEraser();
                                _scribbleNotifier.setStrokeWidth(
                                  _zoomAdjustedEraserSize,
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
              child: Listener(
                onPointerDown: (_) => setState(() => _pointerCount++),
                onPointerUp:
                    (_) => setState(
                      () => _pointerCount = (_pointerCount - 1).clamp(0, 10),
                    ),
                child: InteractiveViewer(
                  panEnabled: !_isDrawingActive || _pointerCount >= 2,
                  scaleEnabled: !_isDrawingActive || _pointerCount >= 2,
                  transformationController: _transformController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  scaleFactor: 1000.0,
                  onInteractionStart: (details) {
                    setState(() {
                      // Reset drawing when multi-touch starts
                      if (_pointerCount >= 2) _isDrawingActive = false;
                    });
                  },
                  onInteractionUpdate: (details) {
                    setState(() {
                      _isZoomed =
                          _transformController.value.getMaxScaleOnAxis() > 1.0;
                      _currentZoomScale =
                          _transformController.value.getMaxScaleOnAxis();
                    });
                    // Update eraser size when zoom changes
                    _updateEraserSizeForZoom();
                  },
                  onInteractionEnd: (details) {
                    setState(() {
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
                          (_isZoomed || _isDrawingMode) && _pointerCount < 2
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
                                // Text field (always visible) - with fixed height based on portrait
                                Container(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        _portraitHeight != null
                                            ? _portraitHeight! -
                                                MediaQuery.of(
                                                  context,
                                                ).padding.top -
                                                kToolbarHeight -
                                                38 - // toolbar bottom height
                                                20 // padding
                                            : MediaQuery.of(
                                                  context,
                                                ).size.height -
                                                MediaQuery.of(
                                                  context,
                                                ).padding.top -
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
                                        fontSize: AppThemeConfig.bodyFontSize,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: AppThemeConfig.bodyFontSize,
                                    ),
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
                                            _pointerCount < 2) ||
                                        _pointerCount >= 2,
                                    child: Listener(
                                      behavior: HitTestBehavior.translucent,
                                      onPointerDown: (event) {
                                        if (_isDrawingMode &&
                                            _pointerCount < 2) {
                                          setState(
                                            () => _isDrawingActive = true,
                                          );
                                        }
                                      },
                                      onPointerUp: (event) {
                                        if (_pointerCount <= 1) {
                                          setState(
                                            () => _isDrawingActive = false,
                                          );
                                        }
                                      },
                                      child: Stack(
                                        children: [
                                          Scribble(
                                            notifier: _scribbleNotifier,
                                            drawPen:
                                                _isDrawingActive &&
                                                _isDrawingMode,
                                            enableGestureCatcher:
                                                false, // Disable gesture catcher for InteractiveViewer integration
                                          ),
                                          // Rotation indicator overlay
                                          if (_isRotating)
                                            Container(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Scaling drawing...',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
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
            ),
          ],
        ),
      ),
    );
  }
}
