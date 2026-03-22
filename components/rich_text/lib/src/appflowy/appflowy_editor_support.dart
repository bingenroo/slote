/// Slote helpers for [AppFlowyEditor] composition: inline formatting, command
/// shortcuts, and related glue.
///
/// Wave A (BIUS) + Wave B (link, highlight, text color, clear) in the example;
/// see `docs/ROADMAP.md`. Split into e.g. `appflowy_blocks.dart` if this file
/// grows further.
library;

import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

// --- Spike colors (swap for Theme-driven values in the app later) ------------

/// Default highlight tint (matches AppFlowy [ToggleColorsStyle]).
const Color kSloteDefaultHighlightColor = Color(0x60FFCE00);

/// Fixed text color used by [sloteToggleTextColor] and toolbar active state.
const Color kSloteSpikeTextColor = Color(0xFF1565C0);

/// Hex string for [kSloteSpikeTextColor] in delta attributes (`font_color`).
final String sloteSpikeTextColorHex = kSloteSpikeTextColor.toHex();

// --- BIUS (toolbar + shortcuts) ---------------------------------------------

/// Shared BIUS entry point for toolbar buttons, tests, and custom shortcuts.
void applyBiusToggle(EditorState editorState, String attributeKey) {
  editorState.toggleAttribute(attributeKey);
}

/// BIUS command-shortcut handler (null selection → ignored).
KeyEventResult applyBiusFromShortcut(
  EditorState editorState,
  String attributeKey,
) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }
  editorState.toggleAttribute(attributeKey);
  return KeyEventResult.handled;
}

// --- Wave B: highlight, text color, clear, link -----------------------------

/// Toggles highlight on a **non-collapsed** selection (works on mobile; unlike
/// stock `toggleHighlightCommand`).
Future<void> sloteToggleHighlight(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;

  final nodes = editorState.getNodesInSelection(selection);
  final isHighlighted = nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) =>
          attributes[AppFlowyRichTextKeys.backgroundColor] != null,
    );
  });

  await editorState.formatDelta(
    selection,
    {
      AppFlowyRichTextKeys.backgroundColor:
          isHighlighted ? null : kSloteDefaultHighlightColor.toHex(),
    },
  );
}

/// Toggles [kSloteSpikeTextColor] on a **non-collapsed** selection.
Future<void> sloteToggleTextColor(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;

  final hex = sloteSpikeTextColorHex;
  final nodes = editorState.getNodesInSelection(selection);
  final allSpike = nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) => attributes[AppFlowyRichTextKeys.textColor] == hex,
    );
  });

  await editorState.formatDelta(
    selection,
    {AppFlowyRichTextKeys.textColor: allSpike ? null : hex},
  );
}

Map<String, dynamic> _sloteClearInlineAttributes() {
  final m = <String, dynamic>{
    for (final k in AppFlowyRichTextKeys.supportSliced) k: null,
    AppFlowyRichTextKeys.href: null,
    AppFlowyRichTextKeys.code: null,
    AppFlowyRichTextKeys.fontFamily: null,
    AppFlowyRichTextKeys.fontSize: null,
  };
  return m;
}

/// Clears inline attributes on a **non-collapsed** selection.
Future<void> sloteClearInlineFormatting(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;
  await editorState.formatDelta(selection, _sloteClearInlineAttributes());
}

/// Shows a URL dialog and applies or removes `href` on the current range.
void sloteShowLinkDialog(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;

  final ctx =
      editorState.getNodeAtPath(selection.end.path)?.key.currentContext;
  if (ctx == null || !ctx.mounted) return;

  final existing = editorState.getDeltaAttributeValueInSelection<String>(
    AppFlowyRichTextKeys.href,
    selection,
  );

  showDialog<void>(
    context: ctx,
    builder: (dialogContext) {
      return _SloteLinkEditorDialog(
        editorState: editorState,
        selection: selection,
        initialHref: existing,
      );
    },
  );
}

/// Owns [TextEditingController] for the link field; dispose runs after the route
/// is popped so [TextField] is never rebuilt with a disposed controller.
class _SloteLinkEditorDialog extends StatefulWidget {
  const _SloteLinkEditorDialog({
    required this.editorState,
    required this.selection,
    this.initialHref,
  });

  final EditorState editorState;
  final Selection selection;
  final String? initialHref;

  @override
  State<_SloteLinkEditorDialog> createState() => _SloteLinkEditorDialogState();
}

class _SloteLinkEditorDialogState extends State<_SloteLinkEditorDialog> {
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

  void _apply() {
    final v = _controller.text.trim();
    Navigator.of(context).pop();
    unawaited(
      widget.editorState.formatDelta(
        widget.selection,
        {AppFlowyRichTextKeys.href: v.isEmpty ? null : v},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'URL',
        ),
        autofocus: true,
        keyboardType: TextInputType.url,
      ),
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
    );
  }
}

KeyEventResult _sloteToggleHighlightShortcut(EditorState editorState) {
  if (editorState.selection == null || editorState.selection!.isCollapsed) {
    return KeyEventResult.ignored;
  }
  unawaited(sloteToggleHighlight(editorState));
  return KeyEventResult.handled;
}

KeyEventResult _sloteToggleTextColorShortcut(EditorState editorState) {
  if (editorState.selection == null || editorState.selection!.isCollapsed) {
    return KeyEventResult.ignored;
  }
  unawaited(sloteToggleTextColor(editorState));
  return KeyEventResult.handled;
}

KeyEventResult _sloteClearInlineShortcut(EditorState editorState) {
  if (editorState.selection == null || editorState.selection!.isCollapsed) {
    return KeyEventResult.ignored;
  }
  unawaited(sloteClearInlineFormatting(editorState));
  return KeyEventResult.handled;
}

KeyEventResult _sloteLinkMenuShortcut(EditorState editorState) {
  if (editorState.selection == null || editorState.selection!.isCollapsed) {
    return KeyEventResult.ignored;
  }
  sloteShowLinkDialog(editorState);
  return KeyEventResult.handled;
}

// --- Command shortcuts -------------------------------------------------------

/// Public keys for Slote-appended shortcuts (tests).
const String sloteToggleTextColorShortcutKey = 'slote toggle text color';
const String sloteClearInlineFormattingShortcutKey =
    'slote clear inline formatting';

const _sloteReplacedStandardKeys = {
  'toggle bold',
  'toggle italic',
  'toggle underline',
  'toggle strikethrough',
  'toggle highlight',
  'link menu',
};

CommandShortcutEvent _shortcutWithSharedHandler(
  CommandShortcutEvent base,
  String attributeKey,
) {
  return base.copyWith(
    handler: (editorState) =>
        applyBiusFromShortcut(editorState, attributeKey),
  );
}

Map<String, CommandShortcutEvent> _sloteStandardReplacements() => {
      'toggle bold': _shortcutWithSharedHandler(
        toggleBoldCommand,
        AppFlowyRichTextKeys.bold,
      ),
      'toggle italic': _shortcutWithSharedHandler(
        toggleItalicCommand,
        AppFlowyRichTextKeys.italic,
      ),
      'toggle underline': _shortcutWithSharedHandler(
        toggleUnderlineCommand,
        AppFlowyRichTextKeys.underline,
      ),
      'toggle strikethrough': _shortcutWithSharedHandler(
        toggleStrikethroughCommand,
        AppFlowyRichTextKeys.strikethrough,
      ),
      'toggle highlight': toggleHighlightCommand.copyWith(
        handler: _sloteToggleHighlightShortcut,
      ),
      'link menu': showLinkMenuCommand.copyWith(
        handler: _sloteLinkMenuShortcut,
      ),
    };

final CommandShortcutEvent _sloteToggleTextColorCommand = CommandShortcutEvent(
  key: sloteToggleTextColorShortcutKey,
  getDescription: () => 'Toggle text color',
  command: 'ctrl+shift+comma',
  macOSCommand: 'cmd+shift+comma',
  handler: _sloteToggleTextColorShortcut,
);

final CommandShortcutEvent _sloteClearInlineCommand = CommandShortcutEvent(
  key: sloteClearInlineFormattingShortcutKey,
  getDescription: () => 'Clear inline formatting',
  command: 'ctrl+shift+period',
  macOSCommand: 'cmd+shift+period',
  handler: _sloteClearInlineShortcut,
);

/// Standard AppFlowy shortcuts with Slote handlers for BIUS, highlight, link,
/// plus appended text-color and clear-formatting chords.
List<CommandShortcutEvent> standardCommandShortcutsWithSloteInlineHandlers() {
  final repl = _sloteStandardReplacements();
  return [
    ...standardCommandShortcutEvents.map((e) => repl[e.key] ?? e),
    _sloteToggleTextColorCommand,
    _sloteClearInlineCommand,
  ];
}

/// Whether [key] is a standard shortcut whose handler Slote replaces, or a
/// Slote-appended shortcut key (for tests).
bool isSloteInlineShortcutKey(String key) =>
    _sloteReplacedStandardKeys.contains(key) ||
    key == sloteToggleTextColorShortcutKey ||
    key == sloteClearInlineFormattingShortcutKey;
