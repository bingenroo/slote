import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('sloteCollectOutlineEntries', () {
    test('empty document has no headings', () {
      final doc = EditorState.blank(withInitialText: false).document;
      expect(sloteCollectOutlineEntries(doc), isEmpty);
    });

    test('collects headings in visual order with titles and levels', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction
        ..insertNode([0], headingNode(level: 1, text: 'Alpha'))
        ..insertNode([1], paragraphNode(text: 'body'))
        ..insertNode([2], headingNode(level: 3, text: 'Beta'));
      await es.apply(t);

      final entries = sloteCollectOutlineEntries(es.document);
      expect(entries.length, 2);
      expect(entries[0].title, 'Alpha');
      expect(entries[0].level, 1);
      expect(entries[0].path.equals([0]), isTrue);
      expect(entries[1].title, 'Beta');
      expect(entries[1].level, 3);
      expect(entries[1].path.equals([2]), isTrue);
    });

    test('empty heading text uses Untitled', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction
        ..insertNode([0], headingNode(level: 2, text: ''));
      await es.apply(t);

      final entries = sloteCollectOutlineEntries(es.document);
      expect(entries.length, 1);
      expect(entries[0].title, kSloteOutlineUntitled);
      expect(entries[0].level, 2);
    });

    test('whitespace-only heading uses Untitled', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction
        ..insertNode([0], headingNode(level: 1, text: '   \n  '));
      await es.apply(t);

      final entries = sloteCollectOutlineEntries(es.document);
      expect(entries.single.title, kSloteOutlineUntitled);
    });

    test('level beyond 5 is clamped to 5', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction
        ..insertNode([0], headingNode(level: 6, text: 'x'));
      await es.apply(t);

      final entries = sloteCollectOutlineEntries(es.document);
      expect(entries.single.level, 5);
    });
  });
}
