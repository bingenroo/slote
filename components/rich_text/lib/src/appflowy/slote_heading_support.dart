import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Heading level (1–5) for the block at the selection start, or `null` if that
/// block is not a heading.
int? sloteHeadingLevelAtSelectionStart(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) return null;
  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null || node.type != HeadingBlockKeys.type) return null;
  return node.attributes[HeadingBlockKeys.level] as int?;
}

/// Whether block-level heading controls apply (collapsed caret or range within
/// one or more supported blocks). Matches AppFlowy floating toolbar rules.
bool sloteCanUseBlockHeadingControls(EditorState editorState) {
  return onlyShowInSingleSelectionAndTextType(editorState);
}

/// Toggle [level] (1–5) on each affected block in the current selection.
///
/// Uses the same rules as AppFlowy’s heading toolbar: if a block is already a
/// heading at [level], it becomes a paragraph; otherwise it becomes a heading at
/// [level]. Works with a **collapsed caret** (the whole line / block).
Future<void> sloteToggleHeadingLevel(
  EditorState editorState,
  int level,
) async {
  assert(level >= 1 && level <= 6);
  final selection = editorState.selection;
  if (selection == null) return;

  await editorState.formatNode(
    selection,
    (node) {
      if (node.delta == null || !toolbarItemWhiteList.contains(node.type)) {
        return node;
      }
      final isThisLevel = node.type == HeadingBlockKeys.type &&
          node.attributes[HeadingBlockKeys.level] == level;
      final delta = (node.delta ?? Delta()).toJson();
      return node.copyWith(
        type: isThisLevel ? ParagraphBlockKeys.type : HeadingBlockKeys.type,
        attributes: {
          HeadingBlockKeys.level: level,
          blockComponentBackgroundColor:
              node.attributes[blockComponentBackgroundColor],
          blockComponentTextDirection:
              node.attributes[blockComponentTextDirection],
          blockComponentDelta: delta,
        },
      );
    },
  );
}

/// Turn supported blocks in the selection into normal paragraphs (body text).
Future<void> sloteApplyParagraphBody(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) return;

  await editorState.formatNode(
    selection,
    (node) {
      if (node.delta == null || !toolbarItemWhiteList.contains(node.type)) {
        return node;
      }
      if (node.type == ParagraphBlockKeys.type) return node;
      final delta = (node.delta ?? Delta()).toJson();
      return node.copyWith(
        type: ParagraphBlockKeys.type,
        attributes: {
          ParagraphBlockKeys.delta: delta,
          blockComponentBackgroundColor:
              node.attributes[blockComponentBackgroundColor],
          blockComponentTextDirection:
              node.attributes[blockComponentTextDirection],
        },
      );
    },
  );
}

enum _SloteHeadingMenuValue { body, h1, h2, h3, h4, h5 }

/// Popup menu: Normal paragraph, H1–H5. Uses [keepEditorFocusNotifier] so
/// the editor regains focus after the menu closes (same pattern as font menus).
class SloteHeadingStyleToolbarMenu extends StatelessWidget {
  const SloteHeadingStyleToolbarMenu({
    super.key,
    required this.editorState,
    required this.enabled,
  });

  final EditorState editorState;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SloteHeadingMenuValue>(
      enabled: enabled,
      tooltip: 'Heading style',
      icon: const Icon(Icons.title),
      onOpened: () => keepEditorFocusNotifier.increase(),
      onCanceled: () => keepEditorFocusNotifier.decrease(),
      onSelected: (value) {
        unawaited((() async {
          try {
            switch (value) {
              case _SloteHeadingMenuValue.body:
                await sloteApplyParagraphBody(editorState);
                break;
              case _SloteHeadingMenuValue.h1:
                await sloteToggleHeadingLevel(editorState, 1);
                break;
              case _SloteHeadingMenuValue.h2:
                await sloteToggleHeadingLevel(editorState, 2);
                break;
              case _SloteHeadingMenuValue.h3:
                await sloteToggleHeadingLevel(editorState, 3);
                break;
              case _SloteHeadingMenuValue.h4:
                await sloteToggleHeadingLevel(editorState, 4);
                break;
              case _SloteHeadingMenuValue.h5:
                await sloteToggleHeadingLevel(editorState, 5);
                break;
            }
          } finally {
            keepEditorFocusNotifier.decrease();
          }
        })());
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _SloteHeadingMenuValue.body,
          child: Text('Normal'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _SloteHeadingMenuValue.h1,
          child: Text('Heading 1'),
        ),
        PopupMenuItem(
          value: _SloteHeadingMenuValue.h2,
          child: Text('Heading 2'),
        ),
        PopupMenuItem(
          value: _SloteHeadingMenuValue.h3,
          child: Text('Heading 3'),
        ),
        PopupMenuItem(
          value: _SloteHeadingMenuValue.h4,
          child: Text('Heading 4'),
        ),
        PopupMenuItem(
          value: _SloteHeadingMenuValue.h5,
          child: Text('Heading 5'),
        ),
      ],
    );
  }
}
