import 'package:flutter/material.dart';

import '../draw_canvas.dart';
import '../draw_controller.dart';
import '../draw_tool.dart';
import '../eraser_mode.dart';

/// Shared drawing chrome: tools, palette, stroke width, canvas, and status bar.
///
/// The [controller] is owned by the parent (lifecycle, persistence).
/// [isDrawingMode] controls whether input applies strokes (e.g. toggle from an
/// [AppBar] action in the parent).
///
/// [onStrokeCaptureActiveChanged] fires when the user starts or ends an in-progress
/// stroke (or eraser drag). The note shell can forward this to the viewport
/// **isDrawingActive** flag (see `package:viewport` zoom/pan surface) so pinch-zoom
/// does not fight ink.
class SloteDrawScaffold extends StatefulWidget {
  const SloteDrawScaffold({
    super.key,
    required this.controller,
    required this.isDrawingMode,
    this.palette,
    this.onStrokesChanged,
    this.onStrokeCaptureActiveChanged,
    this.selectedColorBorderColor,
    this.selectedToolColor,
    this.canvasMargin = const EdgeInsets.all(16),
    this.showCanvasBorder = true,
    this.showStatusBar = true,
    this.showInlineControls = true,
    this.documentTransform,
  });

  final DrawController controller;
  final bool isDrawingMode;

  /// When null, a default palette is used.
  final List<Color>? palette;

  /// Called after the stroke list changes (add stroke or clear).
  final VoidCallback? onStrokesChanged;

  /// See [DrawCanvas.onStrokeCaptureActiveChanged] — for viewport **isDrawingActive**.
  final ValueChanged<bool>? onStrokeCaptureActiveChanged;

  final Color? selectedColorBorderColor;
  final Color? selectedToolColor;

  final EdgeInsets canvasMargin;

  /// Whether to draw the bordered, rounded canvas container.
  ///
  /// For “full-bleed” draw surfaces, set false.
  final bool showCanvasBorder;

  final bool showStatusBar;

  /// Whether to render the tool/palette/stroke controls inline above the canvas.
  ///
  /// When false, you can move controls into a modal “app drawer” instead.
  final bool showInlineControls;

  /// Document → canvas local; defaults to identity (see [DrawCanvas]).
  final Matrix4? documentTransform;

  static const List<Color> kDefaultPalette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  @override
  State<SloteDrawScaffold> createState() => _SloteDrawScaffoldState();
}

class _SloteDrawScaffoldState extends State<SloteDrawScaffold> {
  bool _isDrawingActive = false;
  late int _lastStrokeCount;

  @override
  void initState() {
    super.initState();
    _lastStrokeCount = widget.controller.strokes.length;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final n = widget.controller.strokes.length;
    if (n != _lastStrokeCount) {
      _lastStrokeCount = n;
      widget.onStrokesChanged?.call();
    }
    setState(() {});
  }

  void _onStrokeCaptureActiveChanged(bool active) {
    if (_isDrawingActive == active) return;
    setState(() => _isDrawingActive = active);
    widget.onStrokeCaptureActiveChanged?.call(active);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.isDrawingMode && widget.showInlineControls) ...[
          SloteDrawAppDrawerContent(
            controller: widget.controller,
            palette: widget.palette,
            selectedColorBorderColor: widget.selectedColorBorderColor,
            selectedToolColor: widget.selectedToolColor,
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: Padding(
            padding: widget.canvasMargin,
            child:
                widget.showCanvasBorder
                    ? DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: DrawCanvas(
                          controller: widget.controller,
                          isDrawingMode: widget.isDrawingMode,
                          isDrawingActive: _isDrawingActive,
                          documentTransform: widget.documentTransform,
                          onStrokeCaptureActiveChanged:
                              _onStrokeCaptureActiveChanged,
                        ),
                      ),
                    )
                    : DrawCanvas(
                      controller: widget.controller,
                      isDrawingMode: widget.isDrawingMode,
                      isDrawingActive: _isDrawingActive,
                      documentTransform: widget.documentTransform,
                      onStrokeCaptureActiveChanged:
                          _onStrokeCaptureActiveChanged,
                    ),
          ),
        ),
        if (widget.showStatusBar && widget.isDrawingMode)
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Strokes: ${widget.controller.strokes.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Tool: ${widget.controller.currentTool.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.controller.currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SloteDrawAppDrawerContent extends StatefulWidget {
  const SloteDrawAppDrawerContent({
    super.key,
    required this.controller,
    this.palette,
    this.selectedColorBorderColor,
    this.selectedToolColor,
  });

  final DrawController controller;
  final List<Color>? palette;
  final Color? selectedColorBorderColor;
  final Color? selectedToolColor;

  @override
  State<SloteDrawAppDrawerContent> createState() =>
      _SloteDrawAppDrawerContentState();
}

class _SloteDrawAppDrawerContentState extends State<SloteDrawAppDrawerContent> {
  late Color _selectedColor;
  late double _strokeWidth;
  late double _eraserDiameterDoc;

  List<Color> get _colors =>
      widget.palette ?? SloteDrawScaffold.kDefaultPalette;

  Color get _accent =>
      widget.selectedToolColor ?? Theme.of(context).colorScheme.primary;

  Color get _selectionBorder =>
      widget.selectedColorBorderColor ?? Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.controller.currentColor;
    _strokeWidth = widget.controller.currentStrokeWidth;
    _eraserDiameterDoc = widget.controller.eraserDiameterDoc;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolButton(icon: Icons.edit, tool: DrawTool.pen, label: 'Pen'),
                _toolButton(
                  icon: Icons.brush,
                  tool: DrawTool.highlighter,
                  label: 'Highlighter',
                ),
                _toolButton(
                  icon: Icons.cleaning_services,
                  tool: DrawTool.eraser,
                  label: 'Eraser',
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => widget.controller.clear(),
                  tooltip: 'Clear canvas',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                      widget.controller.setColor(color);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border:
                            isSelected
                                ? Border.all(color: _selectionBorder, width: 3)
                                : Border.all(color: Colors.grey, width: 1),
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color:
                                    color.computeLuminance() > 0.5
                                        ? Colors.black54
                                        : Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.controller.currentTool == DrawTool.eraser
                      ? 'Eraser: '
                      : 'Stroke width: ',
                ),
                Expanded(
                  child: Slider(
                    value:
                        widget.controller.currentTool == DrawTool.eraser
                            ? _eraserDiameterDoc
                            : _strokeWidth,
                    min:
                        widget.controller.currentTool == DrawTool.eraser
                            ? 4.0
                            : 1.0,
                    max:
                        widget.controller.currentTool == DrawTool.eraser
                            ? 64.0
                            : 20.0,
                    divisions:
                        widget.controller.currentTool == DrawTool.eraser
                            ? 30
                            : 19,
                    label:
                        widget.controller.currentTool == DrawTool.eraser
                            ? _eraserDiameterDoc.toStringAsFixed(0)
                            : _strokeWidth.toStringAsFixed(1),
                    onChanged: (value) {
                      if (widget.controller.currentTool == DrawTool.eraser) {
                        setState(() => _eraserDiameterDoc = value);
                        widget.controller.setEraserDiameterDoc(value);
                      } else {
                        setState(() => _strokeWidth = value);
                        widget.controller.setStrokeWidth(value);
                      }
                    },
                  ),
                ),
                Text(
                  widget.controller.currentTool == DrawTool.eraser
                      ? '${_eraserDiameterDoc.toStringAsFixed(0)}px'
                      : '${_strokeWidth.toStringAsFixed(1)}px',
                ),
              ],
            ),
          ),
          if (widget.controller.currentTool == DrawTool.eraser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Erase mode',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<EraserMode>(
                      segments: const [
                        ButtonSegment<EraserMode>(
                          value: EraserMode.stroke,
                          label: Text('Stroke'),
                          tooltip: 'Remove whole stroke when touched',
                        ),
                        ButtonSegment<EraserMode>(
                          value: EraserMode.pixel,
                          label: Text('Pixel'),
                          tooltip: 'Erase along path (split stroke)',
                        ),
                      ],
                      selected: {widget.controller.eraserMode},
                      onSelectionChanged: (next) {
                        if (next.isEmpty) return;
                        widget.controller.setEraserMode(next.first);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pressure',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: widget.controller.pressureEnabled,
                  onChanged: (value) {
                    widget.controller.setPressureEnabled(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required DrawTool tool,
    required String label,
  }) {
    final isSelected = widget.controller.currentTool == tool;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? _accent : Colors.grey),
          onPressed: () {
            widget.controller.setTool(tool);
            setState(() {});
          },
          tooltip: label,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? _accent : Colors.grey,
          ),
        ),
      ],
    );
  }
}
