import 'package:flutter/material.dart';
import 'package:undo_redo/undo_redo.dart';

void main() {
  runApp(const UndoRedoExampleApp());
}

class UndoRedoExampleApp extends StatelessWidget {
  const UndoRedoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Undo/Redo Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _UndoRedoExampleScreen(),
    );
  }
}

class _UndoRedoExampleScreen extends StatefulWidget {
  const _UndoRedoExampleScreen();

  @override
  State<_UndoRedoExampleScreen> createState() => _UndoRedoExampleScreenState();
}

class _UndoRedoExampleScreenState extends State<_UndoRedoExampleScreen> {
  late TextEditingController _textController;
  late TextUndoRedoController _undoRedoController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'Start typing here to test undo/redo functionality...\n\n'
          'Make some changes, then try undo and redo.',
    );
    _undoRedoController = TextUndoRedoController(
      textController: _textController,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _undoRedoController.initializeWithCurrentState();
    });
  }

  @override
  void dispose() {
    _undoRedoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undo/Redo Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _textController.clear();
            },
            tooltip: 'Clear Text',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListenableBuilder(
              listenable: _undoRedoController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                      onPressed: _undoRedoController.canUndo
                          ? () {
                              _undoRedoController.undo();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _undoRedoController.canUndo
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.redo),
                      label: const Text('Redo'),
                      onPressed: _undoRedoController.canRedo
                          ? () {
                              _undoRedoController.redo();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _undoRedoController.canRedo
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type here to test undo/redo...',
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: ListenableBuilder(
              listenable: _undoRedoController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Can Undo: ${_undoRedoController.canUndo ? "Yes" : "No"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _undoRedoController.canUndo
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: _undoRedoController.canUndo
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Can Redo: ${_undoRedoController.canRedo ? "Yes" : "No"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _undoRedoController.canRedo
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: _undoRedoController.canRedo
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Text Length: ${_textController.text.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
