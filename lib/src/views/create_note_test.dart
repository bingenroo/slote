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

class ZoomPanSurface extends StatefulWidget {
  final Widget child;
  final bool isDrawingMode;
  final bool isDrawingActive; // true only while 1-finger drawing
  final ScrollController scrollController;
  final ValueChanged<double>? onScaleChanged;
  final double minScale;
  final double maxScale;
  final double Function()?
  contentHeightProvider; // optional: provide dynamic content height

  const ZoomPanSurface({
    super.key,
    required this.child,
    required this.isDrawingMode,
    required this.isDrawingActive,
    required this.scrollController,
    this.onScaleChanged,
    this.minScale = 1.0, // don't allow zoom-out past original
    this.maxScale = 3.0,
    this.contentHeightProvider, // if null, we’ll infer from scroll metrics
  });

  @override
  State<ZoomPanSurface> createState() => _ZoomPanSurfaceState();
}

class _ZoomPanSurfaceState extends State<ZoomPanSurface>
    with SingleTickerProviderStateMixin {
  // final TransformationController _tc = TransformationController();

  // Gesture state
  int _pointers = 0;
  double _scale = 1.0;
  double _lastScale = 1.0;
  Offset _pan = Offset.zero;
  Offset _lastFocal = Offset.zero;

  // Viewport/content
  Size _viewport = Size.zero;
  double _contentHeight = 0.0;

  // Scrollbar
  bool _showScrollBar = false;
  Timer? _scrollBarTimer;
  static const _scrollBarHideDelay = Duration(seconds: 1);

  // Soft boundary margin to avoid cut-offs at top/bottom
  static const _softMarginY = 50.0;

  // Visual overscroll (rubber band) and recoil animation
  double _overscrollY = 0.0;
  double _overscrollX = 0.0;
  AnimationController? _recoilCtrl;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateContentHeightFromScroll);
    _recoilCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateContentHeightFromScroll);
    _scrollBarTimer?.cancel();
    if (_recoilTick != null) {
      _recoilCtrl?.removeListener(_recoilTick!);
    }
    _recoilCtrl?.dispose();
    super.dispose();
  }

  void _updateContentHeightFromScroll() {
    if (!widget.scrollController.hasClients) return;
    final max = widget.scrollController.position.maxScrollExtent;
    if (_viewport.height == 0) return;
    final newHeight = max + _viewport.height;
    if ((newHeight - _contentHeight).abs() > 8) {
      setState(() => _contentHeight = newHeight);
    }
  }

  void _showScrollThumb() {
    setState(() => _showScrollBar = true);
    _scrollBarTimer?.cancel();
    _scrollBarTimer = Timer(_scrollBarHideDelay, () {
      if (mounted) setState(() => _showScrollBar = false);
    });
  }

  void _startRecoilIfNeeded() {
    if (_overscrollX.abs() <= 0.1 && _overscrollY.abs() <= 0.1) return;
    _recoilCtrl?.stop();
    final startX = _overscrollX;
    final startY = _overscrollY;

    // remove existing listener if any
    if (_recoilTick != null) {
      _recoilCtrl!.removeListener(_recoilTick!);
    }

    // create a new listener and add it
    _recoilTick = () {
      if (!mounted) return;
      final t = Curves.easeOutCubic.transform(_recoilCtrl!.value);
      setState(() {
        _overscrollX = startX * (1.0 - t);
        _overscrollY = startY * (1.0 - t);
      });
    };
    _recoilCtrl!.addListener(_recoilTick!);

    _recoilCtrl!.forward(from: 0.0);
  }

  // keep a reference to avoid stacking listeners
  VoidCallback? _recoilTick;

  // Add this method to _ZoomPanSurfaceState:
  Alignment _getZoomAlignment() {
    if (!widget.scrollController.hasClients) {
      return Alignment.topLeft;
    }

    final scrollOffset = widget.scrollController.offset;
    final maxScroll = widget.scrollController.position.maxScrollExtent;

    if (maxScroll <= 0) {
      return Alignment.topLeft;
    }

    // Calculate which quadrant we're in
    final scrollRatio = (scrollOffset / maxScroll).clamp(0.0, 1.0);

    // Fix the panRatio calculation
    double panRatio = 0.0;
    if (_scale > 1.0) {
      final maxPanX =
          (_viewport.width * _scale) - _viewport.width; // Available pan range
      if (maxPanX > 0) {
        panRatio = (-_pan.dx / maxPanX).clamp(
          0.0,
          1.0,
        ); // 0.0 = left, 1.0 = right
      }
    }

    // Choose corner based on position:
    final isTopHalf = scrollRatio < 0.5;
    final isLeftHalf = panRatio < 0.5;

    if (isTopHalf && isLeftHalf) {
      return Alignment.topLeft; // (-1, -1)
    } else if (isTopHalf && !isLeftHalf) {
      return Alignment.topRight; // (1, -1)
    } else if (!isTopHalf && isLeftHalf) {
      return Alignment.bottomLeft; // (-1, 1)
    } else {
      return Alignment.bottomRight; // (1, 1)
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _viewport = Size(c.maxWidth, c.maxHeight);
        // Try provider first; fallback to inferred
        final provided = widget.contentHeightProvider?.call();
        if (provided != null && provided > 0) {
          _contentHeight = provided;
        }

        return Listener(
          onPointerDown: (_) => setState(() => _pointers++),
          onPointerUp: (_) {
            setState(() => _pointers = (_pointers - 1).clamp(0, 10));
            if (_pointers == 0) _startRecoilIfNeeded();
          },
          child: GestureDetector(
            onScaleStart: (d) {
              _lastFocal = d.focalPoint;
              _lastScale = _scale;
              _showScrollThumb();
            },
            onScaleUpdate: (d) {
              // Drawing mode: single-finger fully locked
              if (widget.isDrawingMode && _pointers == 1) return;

              // Multi-touch: zoom + pan
              if (_pointers >= 2) {
                // Zoom
                final ns = (_lastScale * d.scale).clamp(
                  widget.minScale,
                  widget.maxScale,
                );
                if (ns != _scale) {
                  setState(() => _scale = ns);
                  widget.onScaleChanged?.call(_scale);
                }

                // Pan
                final delta = d.focalPoint - _lastFocal;
                _applyPan(delta);
                _lastFocal = d.focalPoint;
                _showScrollThumb();
                return;
              }

              // Single-touch: only when NOT drawing mode (text mode)
              if (!widget.isDrawingMode && _pointers == 1) {
                final delta = d.focalPoint - _lastFocal;
                _applyPan(delta);
                _lastFocal = d.focalPoint;
                _showScrollThumb();
              }
            },
            onScaleEnd: (d) {
              _startRecoilIfNeeded();
            },
            child: Scrollbar(
              controller: widget.scrollController,
              thumbVisibility: _showScrollBar && !widget.isDrawingMode,
              radius: const Radius.circular(10),
              thickness: 6,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _showScrollThumb();
                    _updateContentHeightFromScroll();
                  });
                  return false;
                },
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  physics:
                      widget.isDrawingMode
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                  child: Transform(
                    transform:
                        Matrix4.identity()
                          ..translate(
                            _pan.dx + _overscrollX,
                            _pan.dy + _overscrollY,
                          )
                          ..scale(_scale),
                    alignment: _getZoomAlignment(), // ← Dynamic alignment
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Around line 278-304, modify the _applyPan method:

  void _applyPan(Offset delta) {
    final scaledW = _viewport.width * _scale;

    // Get current alignment to adjust boundaries
    final alignment = _getZoomAlignment();

    // Adjust horizontal boundaries based on zoom alignment
    double minX, maxX;
    final availX = (scaledW - _viewport.width).clamp(0.0, double.infinity);

    if (alignment.x < 0) {
      // Left-aligned zoom (topLeft, bottomLeft)
      minX = -availX;
      maxX = 0.0;
    } else {
      // Right-aligned zoom (topRight, bottomRight)
      // Shift boundaries to account for right-anchored scaling
      final rightShift = availX;
      minX = -availX;
      maxX = rightShift;
    }

    // Horizontal handling with adjusted boundaries
    final candX = _pan.dx + delta.dx;
    const resistance = 0.5;
    const maxPull = 120.0;

    final clampedX = candX.clamp(minX, maxX);
    final overX = candX - clampedX;
    if (overX.abs() > 0) {
      final visualX = overX * resistance;
      _overscrollX = visualX.clamp(-maxPull, maxPull);
    }

    // Vertical: ONLY use scroll controller (unchanged)
    if (delta.dy.abs() > 0.5 && widget.scrollController.hasClients) {
      final current = widget.scrollController.offset;
      final maxScroll = widget.scrollController.position.maxScrollExtent;
      final proposed = current - (delta.dy / _scale);
      final clampedScroll = proposed.clamp(0.0, maxScroll);
      final overScroll = proposed - clampedScroll;

      if (overScroll.abs() > 0) {
        final visualY = -overScroll * resistance * _scale;
        _overscrollY = visualY.clamp(-maxPull, maxPull);
      }

      if (current != clampedScroll) {
        widget.scrollController.jumpTo(clampedScroll);
      }
    }

    setState(() {
      _pan = Offset(clampedX, 0.0);
    });
  }
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
  bool _isDrawingActive = false;
  int _pointerCount = 0;
  double _currentZoomScale = 1.0;
  // bool _isPanning = false;

  double get _zoomAdjustedEraserSize {
    return _baseEraserStrokeWidth / _currentZoomScale;
  }

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
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    final currentOrientation = MediaQuery.of(context).orientation;
    final currentSize = MediaQuery.of(context).size;

    // Initialize portrait height on first call - always use portrait height as reference
    _portraitHeight ??=
        currentOrientation == Orientation.portrait
            ? currentSize.height
            : currentSize.width;

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

      // Transform the drawing based on the new dimensions
      // Only scale width, keep height constant using portrait height as reference
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

      // Get the current orientation to determine the transformation
      final currentOrientation = MediaQuery.of(context).orientation;
      final previousOrientation = _previousOrientation;

      // Only scale width (X coordinates), keep Y coordinates the same
      final scaleX = newSize.width / oldSize.width;

      // Skip scaling if the width change is too small
      if ((scaleX - 1.0).abs() < 0.01) {
        return;
      }

      // Create a new sketch with transformed coordinates
      final transformedLines = <SketchLine>[];

      for (final line in currentSketch.lines) {
        final transformedPoints = <Point>[];

        for (final point in line.points) {
          // Transform coordinates based on orientation change
          double transformedX = point.x;
          double transformedY = point.y;

          if (previousOrientation == Orientation.portrait &&
              currentOrientation == Orientation.landscape) {
            // Portrait to Landscape: Scale X, keep Y
            transformedX = point.x * scaleX;
            transformedY = point.y; // Keep Y the same
          } else if (previousOrientation == Orientation.landscape &&
              currentOrientation == Orientation.portrait) {
            // Landscape to Portrait: Scale X back, keep Y
            transformedX = point.x * scaleX;
            transformedY = point.y; // Keep Y the same
          }

          final transformedPoint = Point(
            transformedX,
            transformedY,
            pressure: point.pressure,
          );
          transformedPoints.add(transformedPoint);
        }

        // Create new line with transformed points
        final transformedLine = SketchLine(
          points: transformedPoints,
          width: line.width,
          color: line.color,
        );
        transformedLines.add(transformedLine);
      }

      // Create new sketch with transformed lines
      final transformedSketch = Sketch(lines: transformedLines);

      // Update the scribble notifier with the transformed sketch
      _scribbleNotifier.setSketch(
        sketch: transformedSketch,
        addToUndoHistory: false,
      );
    } catch (e) {
      // Handle any errors during scaling
      debugPrint('Error scaling drawing for fixed height: $e');
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
            // In your build method, replace the current Expanded widget:
            Expanded(
              child: Listener(
                onPointerDown: (_) => setState(() => _pointerCount++),
                onPointerUp:
                    (_) => setState(
                      () => _pointerCount = (_pointerCount - 1).clamp(0, 10),
                    ),
                child: ZoomPanSurface(
                  isDrawingMode: _isDrawingMode,
                  isDrawingActive: _isDrawingActive,
                  scrollController: _scrollController,
                  onScaleChanged: (s) {
                    setState(() {
                      _currentZoomScale = s;
                    });
                    _updateEraserSizeForZoom();
                  },
                  // Optional: provide content height if you can compute it
                  contentHeightProvider: () {
                    // Return 0/null to let it infer from scroll metrics
                    return 0;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          // Text editor
                          Container(
                            constraints: BoxConstraints(
                              minHeight:
                                  _portraitHeight != null
                                      ? _portraitHeight! -
                                          MediaQuery.of(context).padding.top -
                                          kToolbarHeight -
                                          38 -
                                          20
                                      : MediaQuery.of(context).size.height -
                                          MediaQuery.of(context).padding.top -
                                          kToolbarHeight -
                                          38 -
                                          20,
                            ),
                            // child: TextFormField(
                            //   controller: _bodyController,
                            //   decoration: InputDecoration(
                            //     border: InputBorder.none,
                            //     hintText: "Start Sloting...",
                            //     hintStyle: TextStyle(
                            //       color: Colors.grey.shade300,
                            //       fontSize: AppThemeConfig.bodyFontSize,
                            //       fontStyle: FontStyle.italic,
                            //     ),
                            //   ),
                            //   style: GoogleFonts.poppins(
                            //     fontSize: AppThemeConfig.bodyFontSize,
                            //   ),
                            //   maxLines: null,
                            //   textInputAction: TextInputAction.newline,
                            //   keyboardType: TextInputType.multiline,
                            // ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top sentence: This is the very first sentence at the top of the note.',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppThemeConfig.bodyFontSize,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Force lots of vertical space to create overflow
                                ...List.generate(
                                  150,
                                  (_) => const SizedBox(height: 24),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Bottom sentence: This is the very last sentence at the bottom of the note.',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppThemeConfig.bodyFontSize,
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
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: (_) {
                                  if (_isDrawingMode && _pointerCount < 2) {
                                    setState(() => _isDrawingActive = true);
                                  }
                                },
                                onPointerUp: (_) {
                                  if (_isDrawingMode && _pointerCount <= 1) {
                                    setState(() => _isDrawingActive = false);
                                  }
                                },
                                child: Scribble(
                                  notifier: _scribbleNotifier,
                                  drawPen: _isDrawingActive && _isDrawingMode,
                                  enableGestureCatcher: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
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
