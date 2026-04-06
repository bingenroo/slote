import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'slote_delta_format.dart';

/// Drag handle + consistent padding for Slote format bottom sheets.
class SloteFormatDrawerShell extends StatelessWidget {
  const SloteFormatDrawerShell({
    super.key,
    required this.title,
    this.actions,
    required this.child,
  });

  final String title;
  final List<Widget>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

BuildContext? _sloteEditorHostContext(EditorState editorState) {
  final sel = editorState.selection;
  if (sel == null) return null;
  return editorState.getNodeAtPath(sel.end.path)?.key.currentContext;
}

/// Resolves a [BuildContext] for showing sheets (toolbar, shortcuts, long-press).
BuildContext? sloteResolveEditorSheetContext(
  EditorState editorState, [
  BuildContext? hostContext,
]) {
  if (hostContext != null && hostContext.mounted) return hostContext;
  final ctx = _sloteEditorHostContext(editorState);
  if (ctx != null && ctx.mounted) return ctx;
  return null;
}

/// Link URL editor: format drawer with URL field and Cancel / Apply.
void showSloteLinkFormatDrawer(
  EditorState editorState, {
  BuildContext? hostContext,
}) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;

  final ctx = sloteResolveEditorSheetContext(editorState, hostContext);
  if (ctx == null) return;

  final existing = editorState.getDeltaAttributeValueInSelection<String>(
    AppFlowyRichTextKeys.href,
    selection,
  );

  keepEditorFocusNotifier.increase();
  showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetContext) {
      return _SloteLinkSheetBody(
        editorState: editorState,
        selection: selection,
        initialHref: existing,
      );
    },
  ).whenComplete(keepEditorFocusNotifier.decrease);
}

class _SloteLinkSheetBody extends StatefulWidget {
  const _SloteLinkSheetBody({
    required this.editorState,
    required this.selection,
    this.initialHref,
  });

  final EditorState editorState;
  final Selection selection;
  final String? initialHref;

  @override
  State<_SloteLinkSheetBody> createState() => _SloteLinkSheetBodyState();
}

class _SloteLinkSheetBodyState extends State<_SloteLinkSheetBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHref ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final v = _controller.text.trim();
    if (!mounted) return;
    Navigator.of(context).pop();
    await sloteApplyLinkHref(
      widget.editorState,
      widget.selection,
      v.isEmpty ? null : v,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SloteFormatDrawerShell(
      title: 'Link',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'URL',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        keyboardType: TextInputType.url,
      ),
    );
  }
}

/// Preset text colors for **light** mode (first swatch matches readable body on
/// light surfaces; avoids trapping users with near-black in dark mode).
const List<Color> kSloteTextColorSwatchesLight = [
  Color(0xFF212121),
  Color(0xFF424242),
  Color(0xFFB71C1C),
  Color(0xFFE65100),
  Color(0xFFF9A825),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
];

/// Preset text colors for **dark** mode (no near-black; first is theme-aligned).
List<Color> kSloteTextColorSwatchesDark(ColorScheme scheme) => [
      scheme.onSurface,
      const Color(0xFFB0BEC5),
      const Color(0xFFEF9A9A),
      const Color(0xFFFFAB40),
      const Color(0xFFFFF59D),
      const Color(0xFFA5D6A7),
      const Color(0xFF90CAF9),
      const Color(0xFFCE93D8),
    ];

/// Kept for backward compatibility; prefer [kSloteTextColorSwatchesLight].
const List<Color> kSloteTextColorSwatches = kSloteTextColorSwatchesLight;

const List<Color> kSloteHighlightSwatchesLight = [
  Color(0xFFFFE082),
  Color(0xFFFFAB91),
  Color(0xFF80CBC4),
  Color(0xFF9FA8DA),
  Color(0xFFF48FB1),
  Color(0xFFBCAAA4),
];

/// Slightly stronger tints for dark surfaces.
const List<Color> kSloteHighlightSwatchesDark = [
  Color(0xFFFFD54F),
  Color(0xFFFF8A65),
  Color(0xFF4DB6AC),
  Color(0xFF7986CB),
  Color(0xFFF06292),
  Color(0xFFA1887F),
];

/// Kept for backward compatibility; prefer [kSloteHighlightSwatchesLight].
const List<Color> kSloteHighlightSwatches = kSloteHighlightSwatchesLight;

List<Color> sloteTextColorSwatchesForTheme(ColorScheme scheme) {
  return scheme.brightness == Brightness.dark
      ? kSloteTextColorSwatchesDark(scheme)
      : kSloteTextColorSwatchesLight;
}

List<Color> sloteHighlightSwatchesForTheme(ColorScheme scheme) {
  return scheme.brightness == Brightness.dark
      ? kSloteHighlightSwatchesDark
      : kSloteHighlightSwatchesLight;
}

/// Text + highlight swatches in one format drawer.
void showSloteColorFormatDrawer(
  EditorState editorState, {
  BuildContext? hostContext,
}) {
  final selection = editorState.selection;

  final ctx = sloteResolveEditorSheetContext(editorState, hostContext);
  if (ctx == null) return;

  keepEditorFocusNotifier.increase();
  showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetContext) {
      return SloteFormatDrawerShell(
        title: 'Text & highlight',
        child: _SloteColorSheetContent(
          editorState: editorState,
          selection: selection,
        ),
      );
    },
  ).whenComplete(keepEditorFocusNotifier.decrease);
}

class _SloteColorSheetContent extends StatelessWidget {
  const _SloteColorSheetContent({
    required this.editorState,
    required this.selection,
  });

  final EditorState editorState;
  final Selection? selection;

  Future<void> _applyTextColor(String? hex) async {
    final sel = selection;
    if (sel == null) {
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, hex);
      return;
    }
    await sloteApplyTextColor(editorState, sel, hex);
  }

  Future<void> _applyHighlight(String? hex) async {
    final sel = selection;
    if (sel == null) {
      editorState.updateToggledStyle(AppFlowyRichTextKeys.backgroundColor, hex);
      return;
    }
    await sloteApplyHighlightColor(editorState, sel, hex);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textSwatches = sloteTextColorSwatchesForTheme(scheme);
    final highlightSwatches = sloteHighlightSwatchesForTheme(scheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ClearSwatch(
              label: 'None',
              onTap: () async {
                await _applyTextColor(null);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            ...textSwatches.map(
              (c) => _ColorDot(
                color: c,
                onTap: () async {
                  await _applyTextColor(c.toHex());
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Highlight',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ClearSwatch(
              label: 'None',
              onTap: () async {
                await _applyHighlight(null);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            ...highlightSwatches.map(
              (c) => _ColorDot(
                color: c,
                onTap: () async {
                  await _applyHighlight(c.toHex());
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final dotL = Color.alphaBlend(color, surface).computeLuminance();
    final surfaceL = surface.computeLuminance();
    final similar = (dotL - surfaceL).abs() < 0.12;
    final borderColor = scheme.outline.withValues(alpha: similar ? 0.9 : 0.45);
    final borderWidth = similar ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearSwatch extends StatelessWidget {
  const _ClearSwatch({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
