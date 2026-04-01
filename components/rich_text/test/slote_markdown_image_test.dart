import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_markdown_codec images', () {
    test('import: markdown image becomes image node', () {
      final doc = sloteMarkdownToDocument('![alt](https://example.com/a.png)\n');
      final node = doc.root.children.first;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], 'https://example.com/a.png');
    });

    test('export: image node becomes markdown image', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], imageNode(url: 'https://example.com/a.png'));
      await es.apply(t);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('!['));
      expect(md, contains('(https://example.com/a.png)'));
    });
  });
}

