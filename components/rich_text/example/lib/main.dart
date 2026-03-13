import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  runApp(const RichTextExampleApp());
}

class RichTextExampleApp extends StatefulWidget {
  const RichTextExampleApp({super.key});

  @override
  State<RichTextExampleApp> createState() => _RichTextExampleAppState();
}

class _RichTextExampleAppState extends State<RichTextExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rich Text Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(primary: Colors.blue),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: _RichTextExampleScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class _RichTextExampleScreen extends StatefulWidget {
  const _RichTextExampleScreen({required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<_RichTextExampleScreen> createState() => _RichTextExampleScreenState();
}

class _RichTextExampleScreenState extends State<_RichTextExampleScreen> {
  late RichTextController _controller;
  final EditorFocusRequester _editorFocusRequester = EditorFocusRequester();
  String _debouncedMarkdown = '';

  @override
  void initState() {
    super.initState();
    _controller = RichTextController(
      initialMarkdown:
          'Start typing here. Use the toolbar for **bold**, *italic*, __underline__.\n\n'
          'With cursor in place, Bold puts you in bold for the next typing.',
      debounceMarkdownDuration: const Duration(milliseconds: 200),
      onMarkdownChanged: (markdown) {
        setState(() => _debouncedMarkdown = markdown);
      },
    );
    _debouncedMarkdown = _controller.markdown;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static bool _isDesktopOrWeb(BuildContext context) {
    if (kIsWeb) return true;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text Example'),
        actions: [
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: theme.brightness == Brightness.dark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.loadMarkdown('');
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: FormatToolbar(controller: _controller),
          ),
          // Give the editor a bounded height so it gets correct layout and tap/Enter
          // positions. Nesting QuillEditor inside SingleChildScrollView causes the
          // first line break to be inserted in the wrong place (middle of line).
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RichTextEditor(
                controller: _controller,
                config: richTextEditorConfig(
                  context,
                  enableIndentOnTab: _isDesktopOrWeb(context),
                  controller: _controller,
                  editorFocusRequester: _editorFocusRequester,
                ),
                editorFocusRequester: _editorFocusRequester,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Markdown output (debounced, DB-ready)',
                    style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: SelectableText(
                      _debouncedMarkdown.isEmpty ? '(empty)' : _debouncedMarkdown,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListenableBuilder(
              listenable: _controller.selectionStyleListenable,
              builder: (context, _) {
                final plain = _controller.quillController.document.toPlainText();
                final words = plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                final sel = _controller.quillController.selection;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Characters: ${plain.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Words: $words',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Selection: ${sel.isCollapsed ? "cursor @ ${sel.start}" : "${sel.start}-${sel.end}"}',
                      style: theme.textTheme.bodySmall,
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
