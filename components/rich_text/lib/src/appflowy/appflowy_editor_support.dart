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

import 'slote_inline_attributes.dart';
import 'slote_delta_format.dart';
import 'slote_format_drawers.dart';

// --- Spike colors (swap for Theme-driven values in the app later) ------------

/// Default highlight tint (matches AppFlowy [ToggleColorsStyle]).
const Color kSloteDefaultHighlightColor = Color(0x60FFCE00);

/// Fixed text color used by [sloteToggleTextColor] and legacy toolbar checks.
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

/// Toggles highlight on the current selection.
///
/// Range: same as before (all highlighted → clear, else apply default tint).
/// Collapsed: toggles pending highlight for the next insert via
/// [EditorState.toggledStyle].
Future<void> sloteToggleHighlight(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) return;

  final bg = AppFlowyRichTextKeys.backgroundColor;
  final defaultHex = kSloteDefaultHighlightColor.toHex();

  if (selection.isCollapsed) {
    final toggled = editorState.toggledStyle;
    final bool currentlyOn;
    if (toggled.containsKey(bg)) {
      currentlyOn = toggled[bg] != null;
    } else {
      final node = editorState.getNodeAtPath(selection.start.path);
      final delta = node?.delta;
      if (delta == null || delta.isEmpty) {
        currentlyOn = false;
      } else {
        final atCaret = delta.sliceAttributes(selection.start.offset);
        currentlyOn = atCaret?[bg] != null;
      }
    }
    editorState.updateToggledStyle(bg, currentlyOn ? null : defaultHex);
    return;
  }

  final nodes = editorState.getNodesInSelection(selection);
  final isHighlighted = nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) => attributes[AppFlowyRichTextKeys.backgroundColor] != null,
    );
  });

  await sloteApplyHighlightColor(
    editorState,
    selection,
    isHighlighted ? null : kSloteDefaultHighlightColor.toHex(),
  );
}

bool _sloteSelectionAllHaveAttributeTrue(
  EditorState editorState,
  Selection selection,
  String attributeKey,
) {
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) => attributes[attributeKey] == true,
    );
  });
}

int _sloteDeltaTextLength(Delta delta) {
  var len = 0;
  final iterator = delta.iterator;
  while (iterator.moveNext()) {
    final op = iterator.current;
    if (op is! TextInsert) continue;
    len += op.text.length;
  }
  return len;
}

/// Clamps selection offsets so `formatDelta` doesn't apply attributes to
/// non-existent trailing positions (e.g. selecting past the last character).
///
/// Only clamps when `start.path == end.path` (single-node selection).
Selection _sloteClampSelectionToNodeText(
  EditorState editorState,
  Selection selection,
) {
  if (selection.isCollapsed) return selection;
  if (selection.start.path.length != selection.end.path.length) return selection;
  for (var i = 0; i < selection.start.path.length; i++) {
    if (selection.start.path[i] != selection.end.path[i]) return selection;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  final delta = node?.delta;
  if (delta == null) return selection;

  final textLen = _sloteDeltaTextLength(delta);
  if (textLen <= 0) return selection;

  final safeStart = selection.start.offset.clamp(0, textLen);
  final safeEnd = selection.end.offset.clamp(0, textLen);

  // If clamping collapses the range, return a collapsed selection so callers
  // can early-exit.
  return Selection.single(
    path: selection.start.path,
    startOffset: safeStart,
    endOffset: safeEnd,
  ).normalized;
}

/// Toggle superscript on a **non-collapsed** selection.
///
/// - If the whole selection is already superscript, clears it.
/// - Otherwise sets superscript and clears subscript.
Future<void> sloteToggleSuperscript(EditorState editorState) async {
  final rawSelection = editorState.selection;
  if (rawSelection == null) return;

  if (rawSelection.isCollapsed) {
    await editorState.toggleAttribute(kSloteSuperscriptAttribute);
    if (editorState.toggledStyle[kSloteSuperscriptAttribute] == true) {
      editorState.updateToggledStyle(kSloteSubscriptAttribute, false);
    }
    return;
  }

  final selection = _sloteClampSelectionToNodeText(
    editorState,
    rawSelection.normalized,
  );
  if (selection.isCollapsed) return;

  final isAllSup = _sloteSelectionAllHaveAttributeTrue(
    editorState,
    selection,
    kSloteSuperscriptAttribute,
  );

  await editorState.formatDelta(selection, {
    kSloteSuperscriptAttribute: isAllSup ? null : true,
    kSloteSubscriptAttribute: null,
  });

  // Collapse to the end so subsequent typing slices the upcoming attributes
  // (and thus continues in superscript/subscript without needing toggledStyle).
  final end = selection.end;
  editorState.selection =
      Selection.single(
        path: end.path,
        startOffset: end.offset,
        endOffset: end.offset,
      ).normalized;
}

/// Toggle subscript on a **non-collapsed** selection.
///
/// - If the whole selection is already subscript, clears it.
/// - Otherwise sets subscript and clears superscript.
Future<void> sloteToggleSubscript(EditorState editorState) async {
  final rawSelection = editorState.selection;
  if (rawSelection == null) return;

  if (rawSelection.isCollapsed) {
    await editorState.toggleAttribute(kSloteSubscriptAttribute);
    if (editorState.toggledStyle[kSloteSubscriptAttribute] == true) {
      editorState.updateToggledStyle(kSloteSuperscriptAttribute, false);
    }
    return;
  }

  final selection = _sloteClampSelectionToNodeText(
    editorState,
    rawSelection.normalized,
  );
  if (selection.isCollapsed) return;

  final isAllSub = _sloteSelectionAllHaveAttributeTrue(
    editorState,
    selection,
    kSloteSubscriptAttribute,
  );

  await editorState.formatDelta(selection, {
    kSloteSubscriptAttribute: isAllSub ? null : true,
    kSloteSuperscriptAttribute: null,
  });

  final end = selection.end;
  editorState.selection =
      Selection.single(
        path: end.path,
        startOffset: end.offset,
        endOffset: end.offset,
      ).normalized;
}

/// Applies or clears font size (`font_size`) on a **non-collapsed** selection.
///
/// Use `null` to clear font size back to the editor default.
Future<void> sloteApplyFontSize(
  EditorState editorState,
  double? fontSize,
) async {
  final selection = editorState.selection;
  // `font_size` is not in AppFlowy `supportToggled`; collapsed would assert in
  // debug on insert. Range-only until upstream adds it.
  if (selection == null || selection.isCollapsed) return;

  await editorState.formatDelta(selection, {
    AppFlowyRichTextKeys.fontSize: fontSize,
  });

  final end = selection.end;
  editorState.selection =
      Selection.single(
        path: end.path,
        startOffset: end.offset,
        endOffset: end.offset,
      ).normalized;
}

/// Applies or clears font family (`font_family`) on a **non-collapsed** selection.
///
/// Use `null` to clear font family back to the editor default.
Future<void> sloteApplyFontFamily(
  EditorState editorState,
  String? fontFamily,
) async {
  final selection = editorState.selection;
  if (selection == null) return;

  if (selection.isCollapsed) {
    editorState.updateToggledStyle(
      AppFlowyRichTextKeys.fontFamily,
      fontFamily,
    );
    return;
  }

  await editorState.formatDelta(selection, {
    AppFlowyRichTextKeys.fontFamily: fontFamily,
  });

  final end = selection.end;
  editorState.selection =
      Selection.single(
        path: end.path,
        startOffset: end.offset,
        endOffset: end.offset,
      ).normalized;
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

  await sloteApplyTextColor(editorState, selection, allSpike ? null : hex);
}

Map<String, dynamic> _sloteClearInlineAttributes() {
  final m = <String, dynamic>{
    for (final k in AppFlowyRichTextKeys.supportSliced) k: null,
    AppFlowyRichTextKeys.href: null,
    AppFlowyRichTextKeys.code: null,
    AppFlowyRichTextKeys.fontFamily: null,
    AppFlowyRichTextKeys.fontSize: null,
    kSloteSuperscriptAttribute: null,
    kSloteSubscriptAttribute: null,
  };
  return m;
}

/// Clears inline attributes on a **non-collapsed** selection.
Future<void> sloteClearInlineFormatting(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) return;
  await editorState.formatDelta(selection, _sloteClearInlineAttributes());
}

/// Opens the link format drawer (bottom sheet) for the current range.
///
/// Prefer passing [hostContext] from the toolbar when available.
void sloteShowLinkDialog(EditorState editorState, {BuildContext? hostContext}) {
  showSloteLinkFormatDrawer(editorState, hostContext: hostContext);
}

KeyEventResult _sloteToggleHighlightShortcut(EditorState editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }
  showSloteColorFormatDrawer(editorState);
  return KeyEventResult.handled;
}

KeyEventResult _sloteToggleTextColorShortcut(EditorState editorState) {
  if (editorState.selection == null) {
    return KeyEventResult.ignored;
  }
  showSloteColorFormatDrawer(editorState);
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
  showSloteLinkFormatDrawer(editorState);
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
    handler: (editorState) => applyBiusFromShortcut(editorState, attributeKey),
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
  'link menu': showLinkMenuCommand.copyWith(handler: _sloteLinkMenuShortcut),
};

final CommandShortcutEvent _sloteToggleTextColorCommand = CommandShortcutEvent(
  key: sloteToggleTextColorShortcutKey,
  getDescription: () => 'Open text & highlight format drawer',
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
