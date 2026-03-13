import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' as hl;

/// Embed type for syntax-highlighted code blocks (from markdown ```lang ... ```).
const String syntaxCodeBlockType = 'syntax_code_block';

/// Dark-theme–style colors for code block (screenshot: purple keyword, orange number, white text).
class _CodeBlockTheme {
  _CodeBlockTheme({required this.isDark});

  final bool isDark;

  Color get background => isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D);
  Color get text => isDark ? const Color(0xFFE0E0E0) : const Color(0xFFE8E8E8);
  Color get keyword => const Color(0xFFC586C0); // purple
  Color get number => const Color(0xFFDCDCAA);   // yellow
  Color get string => const Color(0xFFCE9178);   // orange
  Color get comment => const Color(0xFF6A9955);  // green
  Color get footerBg => isDark ? const Color(0xFF252526) : const Color(0xFF3C3C3C);
  Color get footerText => const Color(0xFF858585);
}

/// Maps highlight [hl.Node] class names to colors (VS Code–like dark theme).
Color _colorForClass(String? className, _CodeBlockTheme theme) {
  if (className == null || className.isEmpty) return theme.text;
  // highlight.dart uses classes like "keyword", "number", "string", "comment", etc.
  if (className.contains('keyword')) return theme.keyword;
  if (className.contains('number')) return theme.number;
  if (className.contains('string')) return theme.string;
  if (className.contains('comment')) return theme.comment;
  return theme.text;
}

/// Builds a [TextSpan] from highlight [hl.Result] with theme colors.
List<TextSpan> _resultToSpans(hl.Result? result, _CodeBlockTheme theme, TextStyle baseStyle) {
  if (result == null || result.nodes == null) return [];
  final spans = <TextSpan>[];
  void visit(hl.Node node) {
    if (node.value != null && node.value!.isNotEmpty) {
      final color = _colorForClass(node.className, theme);
      spans.add(TextSpan(text: node.value, style: baseStyle.copyWith(color: color)));
    }
    if (node.children != null) {
      for (final child in node.children!) {
        visit(child);
      }
    }
  }
  for (final node in result.nodes!) {
    visit(node);
  }
  if (spans.isEmpty) return [];
  return spans;
}

/// Syntax-highlighted code block widget with footer (language selector, Copy).
/// When [onCodeChanged] is set, tapping the code area lets you edit the code.
class SyntaxCodeBlockWidget extends StatelessWidget {
  const SyntaxCodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
    required this.isDark,
    this.onLanguageChanged,
    this.onCodeChanged,
    this.embedOffset,
    this.onFocusGained,
    this.onExitUp,
    this.onExitDown,
    this.registerRequestFocus,
  });

  final String code;
  final String language;
  final bool isDark;
  /// When set, the footer shows a language dropdown (bottom right) to change the language.
  final void Function(String newLanguage)? onLanguageChanged;
  /// When set, tapping the code area focuses an editor; changes are saved when focus is lost.
  final void Function(String newCode)? onCodeChanged;
  /// Used with [onFocusGained]/[onExitUp]/[onExitDown] for selection sync and arrow-key exit.
  final int? embedOffset;
  /// Called when the code block's text field gains focus (collapse editor selection at embed).
  final VoidCallback? onFocusGained;
  /// Called when user presses Arrow Up on the first line to exit the block.
  final VoidCallback? onExitUp;
  /// Called when user presses Arrow Down on the last line to exit the block.
  final VoidCallback? onExitDown;
  /// Called by the content with a callback to enter edit mode and request focus (used when selection lands on embed).
  final void Function(void Function()? fn)? registerRequestFocus;

  /// Common languages for the footer dropdown (id -> display name).
  static const List<MapEntry<String, String>> supportedLanguages = [
    MapEntry('plaintext', 'Plain'),
    MapEntry('cpp', 'C++'),
    MapEntry('c', 'C'),
    MapEntry('csharp', 'C#'),
    MapEntry('dart', 'Dart'),
    MapEntry('java', 'Java'),
    MapEntry('javascript', 'JavaScript'),
    MapEntry('typescript', 'TypeScript'),
    MapEntry('python', 'Python'),
    MapEntry('go', 'Go'),
    MapEntry('rust', 'Rust'),
    MapEntry('sql', 'SQL'),
    MapEntry('html', 'HTML'),
    MapEntry('css', 'CSS'),
    MapEntry('json', 'JSON'),
    MapEntry('yaml', 'YAML'),
    MapEntry('markdown', 'Markdown'),
    MapEntry('bash', 'Bash'),
    MapEntry('shell', 'Shell'),
  ];

  static const double _fontSize = 13;
  static const double _lineHeight = 1.4;

  @override
  Widget build(BuildContext context) {
    final theme = _CodeBlockTheme(isDark: isDark);
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: _fontSize,
      height: _lineHeight,
      color: theme.text,
    );
    final langId = language.isEmpty ? 'plaintext' : language.toLowerCase();
    hl.Result? result;
    try {
      result = hl.highlight.parse(code, language: langId);
    } catch (_) {
      try {
        result = hl.highlight.parse(code, language: 'plaintext');
      } catch (_) {
        result = null;
      }
    }
    final spans = _resultToSpans(result, theme, baseStyle);
    final effectiveSpans = spans.isEmpty && code.isNotEmpty
        ? [TextSpan(text: code, style: baseStyle)]
        : spans;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: _CodeBlockContent(
              code: code,
              language: language,
              theme: theme,
              baseStyle: baseStyle,
              effectiveSpans: effectiveSpans,
              onCodeChanged: onCodeChanged,
              onFocusGained: onFocusGained,
              onExitUp: onExitUp,
              onExitDown: onExitDown,
              registerRequestFocus: registerRequestFocus,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.footerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onLanguageChanged != null)
                  _LanguageDropdown(
                    currentLanguage: language.isEmpty ? 'plaintext' : language.toLowerCase(),
                    footerTextColor: theme.footerText,
                    onChanged: onLanguageChanged!,
                  )
                else
                  Text(
                    _displayLanguage(language),
                    style: TextStyle(fontSize: 11, color: theme.footerText),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Text(
                    'Copy',
                    style: TextStyle(fontSize: 11, color: theme.footerText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _displayLanguage(String lang) {
    if (lang.isEmpty) return 'Plain';
    final lower = lang.toLowerCase();
    if (lower == 'cpp' || lower == 'c++') return 'C++';
    if (lower == 'csharp' || lower == 'c#') return 'C#';
    return lang;
  }
}

/// Code block body: read-only syntax-highlighted view, or editable TextField when [onCodeChanged] is set.
class _CodeBlockContent extends StatefulWidget {
  const _CodeBlockContent({
    required this.code,
    required this.language,
    required this.theme,
    required this.baseStyle,
    required this.effectiveSpans,
    this.onCodeChanged,
    this.onFocusGained,
    this.onExitUp,
    this.onExitDown,
    this.registerRequestFocus,
  });

  final String code;
  final String language;
  final _CodeBlockTheme theme;
  final TextStyle baseStyle;
  final List<TextSpan> effectiveSpans;
  final void Function(String newCode)? onCodeChanged;
  final VoidCallback? onFocusGained;
  final VoidCallback? onExitUp;
  final VoidCallback? onExitDown;
  final void Function(void Function()? fn)? registerRequestFocus;

  @override
  State<_CodeBlockContent> createState() => _CodeBlockContentState();
}

class _CodeBlockContentState extends State<_CodeBlockContent> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.registerRequestFocus?.call(_enterAndRequestFocus);
  }

  void _enterAndRequestFocus() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_focusNode);
      widget.onFocusGained?.call();
    });
  }

  @override
  void didUpdateWidget(_CodeBlockContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.code != widget.code) {
      _controller.text = widget.code;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      if (!mounted) return;
      final textToSave = _controller.text;
      setState(() => _editing = false);
      widget.onCodeChanged?.call(textToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onCodeChanged == null) {
      return SelectableText.rich(
        TextSpan(children: widget.effectiveSpans),
        style: widget.baseStyle,
      );
    }

    if (_editing) {
      return Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final text = _controller.text;
          final offset = _controller.selection.baseOffset;
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            final firstNewline = text.indexOf('\n');
            final onFirstLine = firstNewline == -1
                ? true
                : (offset <= firstNewline);
            if (onFirstLine && widget.onExitUp != null) {
              node.unfocus();
              widget.onExitUp!();
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final lastNewline = text.lastIndexOf('\n');
            final onLastLine = lastNewline == -1
                ? (offset >= text.length)
                : (offset >= lastNewline + 1);
            if (onLastLine && widget.onExitDown != null) {
              node.unfocus();
              widget.onExitDown!();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          minLines: 1,
          style: widget.baseStyle,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintText: 'Type code here…',
            hintStyle: widget.baseStyle.copyWith(
              color: widget.theme.text.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _editing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).requestFocus(_focusNode);
            widget.onFocusGained?.call();
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: widget.effectiveSpans.isEmpty && widget.code.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap to add code',
                  style: widget.baseStyle.copyWith(
                    color: widget.theme.text.withValues(alpha: 0.5),
                  ),
                ),
              )
            : SelectableText.rich(
                TextSpan(children: widget.effectiveSpans),
                style: widget.baseStyle,
              ),
      ),
    );
  }
}

/// Dropdown for selecting the code block language (footer, bottom right).
class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.currentLanguage,
    required this.footerTextColor,
    required this.onChanged,
  });

  final String currentLanguage;
  final Color footerTextColor;
  final void Function(String newLanguage) onChanged;

  @override
  Widget build(BuildContext context) {
    final value = SyntaxCodeBlockWidget.supportedLanguages
        .any((e) => e.key == currentLanguage)
        ? currentLanguage
        : 'plaintext';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        iconSize: 16,
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        style: TextStyle(fontSize: 11, color: footerTextColor),
        items: SyntaxCodeBlockWidget.supportedLanguages
            .map((e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ))
            .toList(),
        onChanged: (String? newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }
}
