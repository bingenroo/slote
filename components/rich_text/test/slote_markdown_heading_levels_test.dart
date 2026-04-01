import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_markdown_codec headings', () {
    test('export: H4/H5 become ####/#####', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], headingNode(level: 4, text: 'h4'));
      t.insertNode([1], headingNode(level: 5, text: 'h5'));
      await es.apply(t);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('#### h4'));
      expect(md, contains('##### h5'));
    });

    test('import: ####/##### become heading level 4/5', () {
      final doc = sloteMarkdownToDocument('#### h4\n\n##### h5\n');
      final h4 = doc.root.children.first;
      final h5 = doc.root.children[1];

      expect(h4.type, HeadingBlockKeys.type);
      expect(h4.attributes[HeadingBlockKeys.level], 4);
      expect(h5.type, HeadingBlockKeys.type);
      expect(h5.attributes[HeadingBlockKeys.level], 5);
    });
  });
}

