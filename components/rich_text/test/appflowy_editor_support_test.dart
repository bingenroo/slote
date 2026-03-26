import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('appflowy_editor_support (stability)', () {
    test('applyBiusFromShortcut ignores when selection is null', () {
      final es = EditorState.blank(withInitialText: true);
      expect(es.selection, isNull);
      expect(
        applyBiusFromShortcut(es, AppFlowyRichTextKeys.bold),
        KeyEventResult.ignored,
      );
    });

    test('applyBiusToggle completes when selection is null', () {
      final es = EditorState.blank(withInitialText: true);
      expect(es.selection, isNull);
      expect(() => applyBiusToggle(es, AppFlowyRichTextKeys.bold), returnsNormally);
    });
  });

  test('standardCommandShortcutsWithSloteInlineHandlers length and replacements', () {
    final custom = standardCommandShortcutsWithSloteInlineHandlers();
    final std = standardCommandShortcutEvents;
    expect(custom.length, std.length + 2);
    for (var i = 0; i < std.length; i++) {
      expect(custom[i].key, std[i].key);
      if (isSloteInlineShortcutKey(std[i].key)) {
        expect(custom[i].handler, isNot(same(std[i].handler)));
      } else {
        expect(custom[i].handler, same(std[i].handler));
      }
    }
    expect(custom[std.length].key, sloteToggleTextColorShortcutKey);
    expect(custom[std.length + 1].key, sloteClearInlineFormattingShortcutKey);
  });

  group('Wave B helpers', () {
    test('sloteClearInlineFormatting removes bold from range', () async {
      final es = EditorState(
        document: Document.fromJson({
          'document': {
            'type': 'page',
            'children': [
              {
                'type': 'paragraph',
                'data': {
                  'delta': [
                    {
                      'insert': 'hello',
                      'attributes': {'bold': true},
                    },
                  ],
                },
              },
            ],
          },
        }),
      );
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5)
              .normalized;
      await sloteClearInlineFormatting(es);

      final encoded = jsonEncode(es.document.toJson());
      expect(encoded.contains('"bold"'), isFalse);
    });

    test('sloteToggleHighlight toggles background on range', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5)
              .normalized;

      await sloteToggleHighlight(es);
      expect(
        jsonEncode(es.document.toJson()),
        contains(AppFlowyRichTextKeys.backgroundColor),
      );

      await sloteToggleHighlight(es);
      expect(
        jsonEncode(es.document.toJson()),
        isNot(contains(AppFlowyRichTextKeys.backgroundColor)),
      );
    });

    test('sloteApplyTextColor sets and clears font_color on range', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      final sel =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;
      es.selection = sel;

      await sloteApplyTextColor(es, sel, kSloteSpikeTextColor.toHex());
      expect(
        jsonEncode(es.document.toJson()),
        contains(AppFlowyRichTextKeys.textColor),
      );

      await sloteApplyTextColor(es, sel, null);
      expect(
        jsonEncode(es.document.toJson()),
        isNot(contains('"${AppFlowyRichTextKeys.textColor}"')),
      );
    });

    test('sloteApplyLinkHref sets href on range', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'link'));
      await es.apply(t);
      final sel =
          Selection.single(path: [0], startOffset: 0, endOffset: 4).normalized;
      es.selection = sel;

      await sloteApplyLinkHref(es, sel, 'https://example.com');
      expect(jsonEncode(es.document.toJson()), contains('https://example.com'));
    });

    test('sloteToggleSuperscript sets then clears slote_superscript', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;

      await sloteToggleSuperscript(es);
      expect(
        jsonEncode(es.document.toJson()),
        contains(kSloteSuperscriptAttribute),
      );

      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;
      await sloteToggleSuperscript(es);
      expect(
        jsonEncode(es.document.toJson()),
        isNot(contains(kSloteSuperscriptAttribute)),
      );
    });

    test('sloteToggleSubscript sets then clears slote_subscript', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;

      await sloteToggleSubscript(es);
      expect(
        jsonEncode(es.document.toJson()),
        contains(kSloteSubscriptAttribute),
      );

      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;
      await sloteToggleSubscript(es);
      expect(
        jsonEncode(es.document.toJson()),
        isNot(contains(kSloteSubscriptAttribute)),
      );
    });

    test('sloteToggleSuperscript clears subscript when switching', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);

      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;
      await sloteToggleSubscript(es);
      expect(jsonEncode(es.document.toJson()), contains(kSloteSubscriptAttribute));

      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 5).normalized;
      await sloteToggleSuperscript(es);

      final encoded = jsonEncode(es.document.toJson());
      expect(encoded, contains(kSloteSuperscriptAttribute));
      expect(encoded, isNot(contains(kSloteSubscriptAttribute)));
    });
  });

  group('slote_markdown_codec (round-trip)', () {
    test('superscript encodes to <sup ...> and decodes back', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'x2'));
      await es.apply(t);

      es.selection =
          Selection.single(path: [0], startOffset: 1, endOffset: 2).normalized;
      await sloteToggleSuperscript(es);

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('<sup'));
      expect(md, contains(kSloteSuperscriptAttribute));

      final doc2 = sloteMarkdownToDocument(md);
      final md2 = sloteDocumentToMarkdown(doc2);
      expect(md2, contains('<sup'));
      expect(md2, contains(kSloteSuperscriptAttribute));
    });

    test('font size/family encodes to <span ...> and decodes back', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hi'));
      await es.apply(t);

      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 2).normalized;
      await sloteApplyFontSize(es, 18);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 2).normalized;
      await sloteApplyFontFamily(es, 'serif');

      final md = sloteDocumentToMarkdown(es.document);
      expect(md, contains('<span'));
      expect(md, contains(AppFlowyRichTextKeys.fontSize));
      expect(md, contains(AppFlowyRichTextKeys.fontFamily));

      final doc2 = sloteMarkdownToDocument(md);
      final md2 = sloteDocumentToMarkdown(doc2);
      expect(md2, contains('<span'));
      expect(md2, contains(AppFlowyRichTextKeys.fontSize));
      expect(md2, contains(AppFlowyRichTextKeys.fontFamily));
    });
  });
}
