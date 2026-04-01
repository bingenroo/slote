import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_markdown_codec callouts', () {
    test('export: callout node becomes <callout kind=...>', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], calloutNode(kind: 'info', text: 'hello'));
      await es.apply(t);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('<callout'));
      expect(md, contains('kind="info"'));
      expect(md, contains('hello'));
    });

    test('import: <callout kind=...> becomes callout node', () {
      final doc = sloteMarkdownToDocument('<callout kind="warning">hi</callout>');
      final node = doc.root.children.first;
      expect(node.type, CalloutBlockKeys.type);
      expect(node.attributes[CalloutBlockKeys.kind], 'warning');
      expect(node.delta?.toPlainText(), 'hi');
    });
  });
}

