import 'package:appflowy_editor/appflowy_editor.dart';

void insertHeadingAfterSelection(EditorState editorState, int level) {
  insertNodeAfterSelection(
    editorState,
    headingNode(level: level),
  );
}

void insertQuoteAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    quoteNode(),
  );
}

void insertCheckboxAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    todoListNode(checked: false),
  );
}

void insertBulletedListAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    bulletedListNode(),
  );
}

void insertNumberedListAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    numberedListNode(),
  );
}

void insertCodeBlockAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    codeBlockNode(),
  );
}

void insertCalloutAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    calloutNode(),
  );
}

void insertTableAfterSelection(
  EditorState editorState, {
  int rows = 2,
  int cols = 2,
}) {
  assert(rows > 0 && cols > 0);
  final table = TableNode.fromList(
    List.generate(
      cols,
      (_) => List.generate(rows, (_) => ''),
      growable: false,
    ),
  ).node;
  insertNodeAfterSelection(editorState, table);
}

void insertImageAfterSelection(
  EditorState editorState, {
  required String url,
  String align = 'center',
  double? height,
  double? width,
}) {
  insertNodeAfterSelection(
    editorState,
    imageNode(
      url: url,
      align: align,
      height: height,
      width: width,
    ),
  );
}

bool insertNodeAfterSelection(
  EditorState editorState,
  Node node,
) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final currentNode = editorState.getNodeAtPath(selection.end.path);
  if (currentNode == null) {
    return false;
  }
  node.updateAttributes({
    blockComponentTextDirection:
        currentNode.attributes[blockComponentTextDirection],
  });

  final transaction = editorState.transaction;
  final delta = currentNode.delta;
  if (delta != null && delta.isEmpty) {
    transaction
      ..insertNode(selection.end.path, node)
      ..deleteNode(currentNode)
      ..afterSelection =
          Selection.collapsed(Position(path: selection.end.path));
  } else {
    final next = selection.end.path.next;
    transaction
      ..insertNode(next, node)
      ..afterSelection = Selection.collapsed(Position(path: next));
  }

  editorState.apply(transaction);
  return true;
}
