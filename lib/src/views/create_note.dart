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
import 'dart:developer';
import 'package:slote/src/views/widgets/viewport/viewport_surface.dart';
import 'package:scribble/scribble.dart';
import 'dart:math' as math;

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

  double?
  _portraitHeight; // Store the portrait height as the fixed canvas height

  // save settings
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  static const Duration _autoSaveDelay = Duration(seconds: 2);

  // Drawing mode state and flags
  bool _isDrawingMode = false;
  // bool _isEraserStrokeMode = false;
  bool _isDrawingActive = false;
  final int _pointerCount = 0;
  // bool _isPanning = false;

  Matrix4 _currentTransform = Matrix4.identity();
  double _currentScale = 1.0;

  // Global Key for calc height
  final GlobalKey _viewportKey = GlobalKey();
  double _viewportHeight = 0.0; // State variable for viewport height

  final GlobalKey _contentKey = GlobalKey();
  double _contentHeight = 0.0; // State variable for content height

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

  final double _baseEraserStrokeWidth = 15.0; // Base eraser size at 1.0 zoom

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
      _scribbleNotifier.setStrokeWidth(_baseEraserStrokeWidth / _currentScale);
    }
  }

  void _measureViewportHeight() {
    final RenderBox? renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final newHeight = renderBox.size.height;

    // Only update state if the height has actually changed
    if (newHeight > 0 && (newHeight - _viewportHeight).abs() > 1.0) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _viewportHeight = newHeight;
            });
          }
        });
      }
    }
  }

  double _calculateTextHeight() {
    final text = _bodyController.text;
    if (text.isEmpty) {
      return _viewportHeight;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(fontSize: AppThemeConfig.bodyFontSize),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );

    // Layout without width constraint to get natural height
    textPainter.layout();

    final calculatedHeight = textPainter.size.height + 20; // Add some padding

    // Return either viewport height or calculated height, whichever is larger
    return calculatedHeight > _viewportHeight
        ? calculatedHeight
        : _viewportHeight;
  }

  void _measureContentHeight() {
    // Calculate text height using TextPainter
    final textHeight = _calculateTextHeight();

    // Add some buffer for drawings, but ensure minimum is viewport height
    final totalContentHeight = textHeight + 100; // Add buffer for drawings

    // Only update state if the height has actually changed
    if (totalContentHeight > 0 &&
        (totalContentHeight - _contentHeight).abs() > 1.0) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _contentHeight = totalContentHeight;
            });
          }
        });
      }
    }
  }

  void _scheduleAutoSave() {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

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
        if (_hasUnsavedChanges && mounted) {
          _saveNoteData();
          _hasUnsavedChanges = false;
        }
      });
    }
  }

  void _saveNoteData() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

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
    if (_hasUnsavedChanges && mounted) {
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

    // Replace the existing generic setState listener with the measurement listener
    _bodyController.addListener(_measureContentHeight);

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
      _measureViewportHeight();
      _measureContentHeight();
      _unifiedUndoRedoController.initializeWithCurrentState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize portrait height if not set - always use portrait height as reference
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

    // Measure viewport height after dependencies change (orientation, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureViewportHeight();
    });
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
            onPressed: () {
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
                          widget.note == null
                              ? "Are you sure you want to discard this note?"
                              : "Are you sure you want to delete this note permanently?",
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
                                // _scribbleNotifier.setStrokeWidth(
                                //   _zoomAdjustedEraserSize,
                                // );
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
            // In your build method, replace the current Expanded widget:
            Expanded(
              child: Container(
                key: _viewportKey,
                child: Builder(
                  builder: (context) {
                    // log(
                    //   "Creating ViewportSurface - _contentHeight: $_contentHeight, _viewportHeight: $_viewportHeight",
                    // );
                    return ViewportSurface(
                      isDrawingMode: _isDrawingMode,
                      isDrawingActive: _isDrawingActive,
                      viewportHeight: _viewportHeight,
                      contentHeight: _contentHeight,
                      onScaleChanged: (scale) {
                        setState(() {
                          _currentScale = scale;
                        });
                        _updateEraserSizeForZoom();
                      },
                      // onTransformChanged: (transform) {
                      //   _currentTransform =
                      //       transform; // for future features like saving the current view state or coordinating with drawing coordinates
                      // },
                      minScale: 1.0,
                      maxScale: 3.0,
                      showScrollbar: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Stack(
                          children: [
                            Stack(
                              key: _contentKey,
                              children: [
                                TextFormField(
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
                                  readOnly: _isDrawingMode,
                                  maxLines: null,
                                  textInputAction: TextInputAction.newline,
                                  keyboardType: TextInputType.multiline,
                                ),
                                // in the Stack, replace the current drawing overlay block
                                Positioned.fill(
                                  child: IgnorePointer(
                                    // Previously: ignoring: !_isDrawingMode,
                                    // New: also ignore when 2+ fingers are down to block Scribble's InteractiveViewer
                                    ignoring:
                                        !_isDrawingMode || _pointerCount >= 2,
                                    child: Listener(
                                      behavior: HitTestBehavior.translucent,
                                      onPointerDown: (_) {
                                        if (_isDrawingMode &&
                                            _pointerCount < 2) {
                                          setState(
                                            () => _isDrawingActive = true,
                                          );
                                        }
                                      },
                                      onPointerUp: (_) {
                                        if (_isDrawingMode &&
                                            _pointerCount <= 1) {
                                          setState(
                                            () => _isDrawingActive = false,
                                          );
                                        }
                                      },
                                      // child: Scribble(
                                      //   notifier: _scribbleNotifier,
                                      //   drawPen:
                                      //       _isDrawingActive && _isDrawingMode,
                                      //   enableGestureCatcher: false,
                                      // ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
