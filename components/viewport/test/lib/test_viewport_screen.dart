import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:slote_viewport/slote_viewport.dart';

// #region agent log
Object? _jsonSafe(dynamic value) {
  if (value is double && (value.isInfinite || value.isNaN)) {
    return value.isInfinite ? (value > 0 ? 'Infinity' : '-Infinity') : 'NaN';
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _jsonSafe(v)));
  }
  if (value is List) {
    return value.map(_jsonSafe).toList();
  }
  return value;
}

void _debugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  final payload = {
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'data': _jsonSafe(data),
    'sessionId': 'debug-session',
    'hypothesisId': hypothesisId,
  };
  final body = jsonEncode(payload);
  final uri = Uri.parse('http://10.0.2.2:7245/ingest/f06199e7-0954-4ea6-a49f-7cd1f933cda1');
  HttpClient().postUrl(uri).then((request) {
    request.headers.contentType = ContentType.json;
    request.write(body);
    return request.close();
  }).catchError((_) {});
}
// #endregion

class TestViewportScreen extends StatefulWidget {
  const TestViewportScreen({super.key});

  @override
  State<TestViewportScreen> createState() => _TestViewportScreenState();
}

class _TestViewportScreenState extends State<TestViewportScreen> {
  double _currentScale = 1.0;
  bool _isDrawingMode = false;
  bool _isDrawingActive = false;

  /// Content height for BoundaryManager (taller than viewport to enable pan when zoomed).
  /// Must be large enough for all content to avoid Column overflow.
  static const double _contentHeight = 2600.0;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final viewportWidth = constraints.maxWidth;

          return ViewportSurface(
            isDrawingMode: _isDrawingMode,
            isDrawingActive: _isDrawingActive,
            viewportHeight: viewportHeight,
            contentHeight: _contentHeight,
            onScaleChanged: (scale) {
              setState(() {
                _currentScale = scale;
              });
            },
            minScale: 1.0,
            maxScale: 3.0,
            showScrollbar: true,
            child: LayoutBuilder(
              builder: (context, contentConstraints) {
                // #region agent log
                _debugLog(
                  'test_viewport_screen.dart:LayoutBuilder',
                  'Content received constraints from viewport',
                  {
                    'maxWidth': contentConstraints.maxWidth,
                    'maxHeight': contentConstraints.maxHeight,
                    'viewportHeight': viewportHeight,
                    'viewportWidth': viewportWidth,
                    'contentHeight': _contentHeight,
                  },
                  'A',
                );
                _debugLog(
                  'test_viewport_screen.dart:LayoutBuilder',
                  'Constraint limits',
                  {
                    'maxHeight_equals_viewport': contentConstraints.maxHeight == viewportHeight,
                    'maxHeight_less_than_content': contentConstraints.maxHeight < _contentHeight,
                  },
                  'D',
                );
                // #endregion
                return SizedBox(
                  height: _contentHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Viewport Test Content',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Viewport Height: ${viewportHeight.toStringAsFixed(0)}px',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Viewport Width: ${viewportWidth.toStringAsFixed(0)}px',
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
                    const Text('• Pinch with two fingers to zoom'),
                    const Text('• When zoomed, drag with one finger to pan'),
                    const Text('• Scrollbars reflect pan position; drag them to pan'),
                    const Text('• Toggle drawing mode to test mode switching'),
                    const SizedBox(height: 32),
                    ...List.generate(
                      10,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Content block ${index + 1}: '
                          'This is test content to demonstrate scrolling and viewport behavior. '
                          'Zoom in then pan in any direction.',
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
          );
        },
      ),
    );
  }
}
