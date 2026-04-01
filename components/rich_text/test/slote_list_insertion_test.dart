import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Wave C blocks: insertion helpers', () {
    test('insertBulletedListAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertBulletedListAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, BulletedListBlockKeys.type);
    });

    test('insertNumberedListAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertNumberedListAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, NumberedListBlockKeys.type);
    });

    test('insertCheckboxAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertCheckboxAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, TodoListBlockKeys.type);
      expect(node?.attributes[TodoListBlockKeys.checked], isFalse);
    });

    test('insertQuoteAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertQuoteAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, QuoteBlockKeys.type);
    });

    test('insertNodeAfterSelection can insert divider', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      final inserted = insertNodeAfterSelection(es, dividerNode());
      expect(inserted, isTrue);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, DividerBlockKeys.type);
    });

    test('insertCodeBlockAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertCodeBlockAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, CodeBlockKeys.type);
    });

    test('insertCalloutAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertCalloutAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, CalloutBlockKeys.type);
    });

    test('insertTableAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertTableAfterSelection(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, TableBlockKeys.type);
      expect(node?.children.length, 4);
    });

    test('insertImageAfterSelection replaces empty paragraph', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: ''));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      insertImageAfterSelection(es, url: 'https://example.com/x.png');
      final node = es.getNodeAtPath([0]);
      expect(node?.type, ImageBlockKeys.type);
      expect(node?.attributes[ImageBlockKeys.url], 'https://example.com/x.png');
    });
  });
}

