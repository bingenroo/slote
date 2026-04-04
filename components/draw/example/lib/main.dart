import 'package:draw/draw.dart';
import 'package:flutter/material.dart';

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
      body: SloteDrawScaffold(
        controller: _drawController,
        isDrawingMode: _isDrawingMode,
      ),
    );
  }
}
