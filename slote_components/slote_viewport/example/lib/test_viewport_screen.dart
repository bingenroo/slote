import 'package:flutter/material.dart';
import 'package:slote_viewport/slote_viewport.dart';

class TestViewportScreen extends StatefulWidget {
  const TestViewportScreen({super.key});

  @override
  State<TestViewportScreen> createState() => _TestViewportScreenState();
}

class _TestViewportScreenState extends State<TestViewportScreen> {
  final GlobalKey _viewportKey = GlobalKey();
  double _viewportHeight = 0.0;
  double _contentHeight = 500.0;
  double _currentScale = 1.0;
  bool _isDrawingMode = false;
  bool _isDrawingActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureViewportHeight();
    });
  }

  void _measureViewportHeight() {
    final RenderBox? renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final newHeight = renderBox.size.height;

    if (newHeight > 0 && (newHeight - _viewportHeight).abs() > 1.0) {
      if (mounted) {
        setState(() {
          _viewportHeight = newHeight;
        });
      }
    }
  }

  void _increaseContentHeight() {
    setState(() {
      _contentHeight += 200;
    });
  }

  void _decreaseContentHeight() {
    setState(() {
      _contentHeight = (_contentHeight - 200).clamp(200.0, double.infinity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slote Viewport Test'),
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
          // Controls
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Zoom Out'),
                      onPressed: () {
                        setState(() {
                          _currentScale = (_currentScale - 0.1).clamp(1.0, 3.0);
                        });
                      },
                    ),
                    Text(
                      'Scale: ${_currentScale.toStringAsFixed(2)}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Zoom In'),
                      onPressed: () {
                        setState(() {
                          _currentScale = (_currentScale + 0.1).clamp(1.0, 3.0);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Decrease Height'),
                      onPressed: _decreaseContentHeight,
                    ),
                    Text(
                      'Content: ${_contentHeight.toStringAsFixed(0)}px',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Increase Height'),
                      onPressed: _increaseContentHeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Viewport area
          Expanded(
            child: Container(
              key: _viewportKey,
              child: Builder(
                builder: (context) {
                  return ViewportSurface(
                    isDrawingMode: _isDrawingMode,
                    isDrawingActive: _isDrawingActive,
                    viewportHeight: _viewportHeight > 0 ? _viewportHeight : 400,
                    contentHeight: _contentHeight,
                    onScaleChanged: (scale) {
                      setState(() {
                        _currentScale = scale;
                      });
                    },
                    minScale: 1.0,
                    maxScale: 3.0,
                    showScrollbar: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      height: _contentHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue[100]!,
                            Colors.green[100]!,
                            Colors.yellow[100]!,
                            Colors.red[100]!,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viewport Test Content',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Viewport Height: ${_viewportHeight.toStringAsFixed(0)}px',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Content Height: ${_contentHeight.toStringAsFixed(0)}px',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Current Scale: ${_currentScale.toStringAsFixed(2)}x',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Instructions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('• Pinch to zoom (or use buttons above)'),
                          const Text('• Drag to pan'),
                          const Text('• Use buttons to adjust content height'),
                          const Text('• Toggle drawing mode to test mode switching'),
                          const SizedBox(height: 32),
                          ...List.generate(
                            10,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Content block ${index + 1}: '
                                'This is test content to demonstrate scrolling and viewport behavior. '
                                'The content height can be adjusted using the controls above.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  'Viewport: ${_viewportHeight.toStringAsFixed(0)}px',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Content: ${_contentHeight.toStringAsFixed(0)}px',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Scale: ${_currentScale.toStringAsFixed(2)}x',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Mode: ${_isDrawingMode ? "Drawing" : "View"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
