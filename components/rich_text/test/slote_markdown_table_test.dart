import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_markdown_codec tables', () {
    test('export: table node becomes markdown table', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode(
        [0],
        TableNode.fromList([
          ['a', 'b'],
          ['c', 'd'],
        ]).node,
      );
      await es.apply(t);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('|'));
      expect(md, contains('a'));
      expect(md, contains('d'));
    });

    test('import: markdown table becomes table node', () {
      final doc = sloteMarkdownToDocument(
        '| a | b |\n|---|---|\n| c | d |\n',
      );
      final node = doc.root.children.first;
      expect(node.type, TableBlockKeys.type);
    });
  });
}

