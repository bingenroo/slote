import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_markdown_codec code blocks', () {
    test('import: fenced code block becomes code node', () {
      final doc = sloteMarkdownToDocument('```\nprint(\"hi\")\n```\n');
      final node = doc.root.children.first;
      expect(node.type, CodeBlockKeys.type);
    });

    test('export: code node becomes fenced code block', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], codeBlockNode(text: 'print(\"hi\")'));
      await es.apply(t);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('```'));
      expect(md, contains('print(\"hi\")'));
    });
  });
}

