import 'package:flutter/material.dart';
import 'package:draw/draw.dart';

void main() {
  runApp(const DrawExampleApp());
}

class DrawExampleApp extends StatelessWidget {
  const DrawExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _DrawExampleScreen(),
    );
  }
}

class _DrawExampleScreen extends StatefulWidget {
  const _DrawExampleScreen();

  @override
  State<_DrawExampleScreen> createState() => _DrawExampleScreenState();
}

class _DrawExampleScreenState extends State<_DrawExampleScreen> {
  late DrawController _drawController;
  bool _isDrawingMode = true;
  bool _isDrawingActive = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;

  final List<Color> _colors = [
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
  void initState() {
    super.initState();
    _drawController = DrawController();
    _drawController.setColor(_selectedColor);
    _drawController.setStrokeWidth(_strokeWidth);
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isDrawingMode) {
      setState(() {
        _isDrawingActive = true;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawingMode) {
      setState(() {
        _isDrawingActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Example'),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.edit : Icons.visibility),
            onPressed: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
              });
            },
            tooltip: _isDrawingMode ? 'View Mode' : 'Drawing Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.edit,
                  tool: DrawTool.pen,
                  label: 'Pen',
                ),
                _buildToolButton(
                  icon: Icons.brush,
                  tool: DrawTool.highlighter,
                  label: 'Highlighter',
                ),
                _buildToolButton(
                  icon: Icons.cleaning_services,
                  tool: DrawTool.eraser,
                  label: 'Eraser',
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _drawController.clear();
                  },
                  tooltip: 'Clear Canvas',
                ),
              ],
            ),
          ),
          // Color picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                      _drawController.setColor(color);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 3)
                          : Border.all(color: Colors.grey, width: 1),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          // Stroke width slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Stroke Width: '),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: _strokeWidth.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth = value;
                        _drawController.setStrokeWidth(value);
                      });
                    },
                  ),
                ),
                Text('${_strokeWidth.toStringAsFixed(1)}px'),
              ],
            ),
          ),
          const Divider(),
          // Canvas area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Listener(
                onPointerDown: (_) => _onPanStart(
                  DragStartDetails(globalPosition: Offset.zero),
                ),
                onPointerUp: (_) => _onPanEnd(DragEndDetails()),
                child: DrawCanvas(
                  controller: _drawController,
                  isDrawingMode: _isDrawingMode,
                  isDrawingActive: _isDrawingActive,
                ),
              ),
            ),
          ),
          // Info bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Strokes: ${_drawController.strokes.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Tool: ${_drawController.currentTool.name}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawTool tool,
    required String label,
  }) {
    final isSelected = _drawController.currentTool == tool;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          onPressed: () {
            _drawController.setTool(tool);
            setState(() {});
          },
          tooltip: label,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
}
