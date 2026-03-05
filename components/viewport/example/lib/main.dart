import 'package:flutter/material.dart';
import 'package:viewport/viewport.dart';

void main() {
  runApp(const ViewportExampleApp());
}

class ViewportExampleApp extends StatelessWidget {
  const ViewportExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viewport Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _ViewportExampleScreen(),
    );
  }
}

class _ViewportExampleScreen extends StatefulWidget {
  const _ViewportExampleScreen();

  @override
  State<_ViewportExampleScreen> createState() => _ViewportExampleScreenState();
}

class _ViewportExampleScreenState extends State<_ViewportExampleScreen> {
  double _currentScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewport Example'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final viewportWidth = constraints.maxWidth;

          return ViewportSurface(
            viewportHeight: viewportHeight,
            contentHeight: null,
            onScaleChanged: (scale) {
              setState(() {
                _currentScale = scale;
              });
            },
            minScale: 1.0,
            maxScale: 3.0,
            showScrollbar: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Viewport Example Content',
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
                  const Text('• Drag with one finger (or mouse) to pan/scroll'),
                  const Text('• Mouse wheel to scroll'),
                  const Text('• Drag scrollbar to pan'),
                  const SizedBox(height: 32),
                  ...List.generate(
                    10,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Content block ${index + 1}: '
                        'This is example content to demonstrate scrolling and viewport behavior. '
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
  }
}
