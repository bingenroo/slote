import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:viewport/viewport.dart';

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
  static const double _kContentHeight = 3200;

  @override
  void initState() {
    super.initState();
    _drawController = DrawController();
    _drawController.setColor(Colors.black);
    _drawController.setStrokeWidth(2.0);
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const pagePadding = EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Example'),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.edit : Icons.visibility),
            onPressed: () {
              setState(() => _isDrawingMode = !_isDrawingMode);
            },
            tooltip: _isDrawingMode ? 'View mode' : 'Drawing mode',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              if (_isDrawingMode) ...[
                SloteDrawAppDrawerContent(
                  controller: _drawController,
                  selectedToolColor: scheme.primary,
                  selectedColorBorderColor: scheme.primary,
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewportConstraints) {
                    return ViewportSurface(
                      viewportHeight: viewportConstraints.maxHeight,
                      contentHeight: _kContentHeight,
                      isDrawingMode: _isDrawingMode,
                      isDrawingActive: _isDrawingActive,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: _kContentHeight,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: pagePadding,
                                    child: _FakeDocument(
                                      isDrawingMode: _isDrawingMode,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: SloteDrawScaffold(
                                      controller: _drawController,
                                      isDrawingMode: _isDrawingMode,
                                      onStrokeCaptureActiveChanged: (active) {
                                        if (_isDrawingActive == active) return;
                                        setState(
                                          () => _isDrawingActive = active,
                                        );
                                      },
                                      selectedToolColor: scheme.primary,
                                      selectedColorBorderColor: scheme.primary,
                                      canvasMargin: EdgeInsets.zero,
                                      showCanvasBorder: false,
                                      showStatusBar: false,
                                      showInlineControls: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FakeDocument extends StatelessWidget {
  const _FakeDocument({
    required this.isDrawingMode,
  });

  final bool isDrawingMode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewport + ink (Wave G demo)',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isDrawingMode
              ? 'Drawing is ON: draw with one finger (pan is disabled).'
              : 'Drawing is OFF: drag with one finger to pan.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...List.generate(
          18,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Block ${i + 1}: This is fake document content to make the viewport scrollable. '
              'Pinch to zoom. Start a stroke and try pinching: pinch should be suppressed while ink is active.',
              style: textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}
