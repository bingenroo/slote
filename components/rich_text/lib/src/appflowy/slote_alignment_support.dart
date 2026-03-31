import 'package:appflowy_editor/appflowy_editor.dart';

/// Supported block alignment values for Slote's toolbar.
///
/// Maps to AppFlowy node attribute [blockComponentAlign]:
/// `left` | `center` | `right` | `justify`.
enum SloteBlockAlignment { left, center, right, justify }

String _sloteBlockAlignmentValue(SloteBlockAlignment alignment) {
  switch (alignment) {
    case SloteBlockAlignment.left:
      return 'left';
    case SloteBlockAlignment.center:
      return 'center';
    case SloteBlockAlignment.right:
      return 'right';
    case SloteBlockAlignment.justify:
      return 'justify';
  }
}

/// Returns the uniform `blockComponentAlign` value across the current selection,
/// or `null` when selection is missing, contains non-text blocks, or is mixed.
SloteBlockAlignment? sloteBlockAlignmentInSelection(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) return null;

  final nodes = editorState.getNodesInSelection(selection);
  if (nodes.isEmpty) return null;

  SloteBlockAlignment? uniform;
  for (final node in nodes) {
    // Only consider text-like blocks; non-text nodes don't support alignment in
    // the same way and would make "active state" misleading.
    if (node.delta == null) return null;

    final raw = node.attributes[blockComponentAlign] as String?;
    final a = switch (raw) {
      'left' => SloteBlockAlignment.left,
      'center' => SloteBlockAlignment.center,
      'right' => SloteBlockAlignment.right,
      'justify' => SloteBlockAlignment.justify,
      _ => SloteBlockAlignment.left, // AppFlowy default when unset.
    };
    uniform ??= a;
    if (uniform != a) return null;
  }
  return uniform;
}

/// Applies [alignment] to each affected block in the current selection.
Future<void> sloteApplyBlockAlignment(
  EditorState editorState,
  SloteBlockAlignment alignment,
) async {
  final selection = editorState.selection;
  if (selection == null) return;
  final value = _sloteBlockAlignmentValue(alignment);

  await editorState.updateNode(
    selection,
    (node) {
      if (node.delta == null) return node;
      return node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentAlign: value,
        },
      );
    },
  );
}

