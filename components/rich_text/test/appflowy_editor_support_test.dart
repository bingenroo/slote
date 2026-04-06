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
    test('sloteClearInlineFormatting no-op at collapsed caret', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 1, endOffset: 1).normalized;
      applyBiusToggle(es, AppFlowyRichTextKeys.bold);
      expect(es.toggledStyle[AppFlowyRichTextKeys.bold], isTrue);

      await sloteClearInlineFormatting(es);
      expect(es.toggledStyle[AppFlowyRichTextKeys.bold], isTrue);
    });

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

    test('sloteApplyTextColor at collapsed caret sets toggledStyle for next insert',
        () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      final caret =
          Selection.single(path: [0], startOffset: 5, endOffset: 5).normalized;
      es.selection = caret;

      await sloteApplyTextColor(es, caret, kSloteSpikeTextColor.toHex());
      expect(
        es.toggledStyle[AppFlowyRichTextKeys.textColor],
        kSloteSpikeTextColor.toHex(),
      );
    });

    test('sloteApplyHighlightColor at collapsed caret sets toggledStyle', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hi'));
      await es.apply(t);
      final caret =
          Selection.single(path: [0], startOffset: 2, endOffset: 2).normalized;
      es.selection = caret;

      final hex = sloteDefaultHighlightHex(const ColorScheme.light());
      await sloteApplyHighlightColor(es, caret, hex);
      expect(es.toggledStyle[AppFlowyRichTextKeys.backgroundColor], hex);
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

    test('sloteToggleSuperscript at collapsed caret toggles typing style', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'a'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 1, endOffset: 1).normalized;

      await sloteToggleSuperscript(es);
      expect(es.toggledStyle[kSloteSuperscriptAttribute], isTrue);
      expect(es.toggledStyle[kSloteSubscriptAttribute], isFalse);

      await sloteToggleSuperscript(es);
      expect(es.toggledStyle[kSloteSuperscriptAttribute], isFalse);
    });

    test(
      'insert with slote superscript toggledStyle applies attribute (IME contract)',
      () async {
        final es = EditorState.blank(withInitialText: false);
        final setup = es.transaction;
        setup.insertNode([0], paragraphNode(text: 'a'));
        await es.apply(setup);
        es.selection =
            Selection.single(path: [0], startOffset: 1, endOffset: 1).normalized;

        await sloteToggleSuperscript(es);
        expect(AppFlowyRichTextKeys.supportToggled, contains(kSloteSuperscriptAttribute));

        final node = es.getNodeAtPath([0]);
        expect(node, isNotNull);
        final tx = es.transaction;
        tx.insertText(
          node!,
          1,
          'x',
          toggledAttributes: es.toggledStyle,
        );
        await es.apply(tx);

        expect(es.getNodeAtPath([0])!.delta!.toPlainText(), 'ax');
        final encoded = jsonEncode(es.document.toJson());
        expect(encoded, contains(kSloteSuperscriptAttribute));
      },
    );

    test(
      'RichTextEditorController restores subscript toggledStyle for continued typing',
      () async {
        ensureSloteAppFlowyRichTextKeysRegistered();
        final controller = RichTextEditorController(
          document: Document.blank(withInitialText: false),
        );
        final es = controller.editorState;
        final setup = es.transaction;
        setup.insertNode([0], paragraphNode(text: 'a'));
        await es.apply(setup);

        es.selection =
            Selection.single(path: [0], startOffset: 1, endOffset: 1).normalized;

        await sloteToggleSubscript(es);
        expect(es.toggledStyle[kSloteSubscriptAttribute], isTrue);

        var node = es.getNodeAtPath([0]);
        var tx = es.transaction;
        tx.insertText(
          node!,
          1,
          'b',
          toggledAttributes: es.toggledStyle,
        );
        await es.apply(tx);

        expect(
          es.toggledStyle[kSloteSubscriptAttribute],
          isTrue,
          reason: 'sync after selection clear must not flip script pending style',
        );

        node = es.getNodeAtPath([0]);
        tx = es.transaction;
        tx.insertText(
          node!,
          2,
          'c',
          toggledAttributes: es.toggledStyle,
        );
        await es.apply(tx);

        final delta = es.getNodeAtPath([0])!.delta!;
        expect(delta.toPlainText(), 'abc');
        expect(delta.sliceAttributes(2)?[kSloteSubscriptAttribute], isTrue);
        expect(delta.sliceAttributes(3)?[kSloteSubscriptAttribute], isTrue);
        expect(jsonEncode(es.document.toJson()), contains(kSloteSubscriptAttribute));

        controller.dispose();
      },
    );

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

    test('sloteToggleSuperscript clamps selection beyond paragraph end',
        () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);

      // Intentionally beyond bounds to reproduce "phantom" extra formatting.
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 50).normalized;

      await sloteToggleSuperscript(es);

      // Verify superscript span covers only real characters (5).
      final encoded = jsonEncode(es.document.toJson());
      expect(encoded, isNot(contains('"insert":""')));

      final docJson = es.document.toJson() as Map<String, dynamic>;
      final document = (docJson['document'] ?? docJson) as Map<String, dynamic>;
      final children = document['children'] as List;
      final paragraph = children.first as Map<String, dynamic>;
      final data = paragraph['data'] as Map<String, dynamic>;
      final delta = data['delta'] as List;

      final supLen = delta.fold<int>(0, (sum, op) {
        final m = op as Map<String, dynamic>;
        final attrs = m['attributes'] as Map<String, dynamic>?;
        if (attrs == null) return sum;
        if (attrs[kSloteSuperscriptAttribute] != true) return sum;
        final insert = m['insert'];
        if (insert is! String) return sum;
        return sum + insert.length;
      });

      expect(supLen, 5);
    });

    test('sloteToggleSuperscript respects backward selection direction',
        () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);

      // Backward selection: should normalize to [2, 4) -> two 'l' chars.
      es.selection =
          Selection.single(path: [0], startOffset: 4, endOffset: 2).normalized;

      await sloteToggleSuperscript(es);

      final docJson = es.document.toJson() as Map<String, dynamic>;
      final document = (docJson['document'] ?? docJson) as Map<String, dynamic>;
      final children = document['children'] as List;
      final paragraph = children.first as Map<String, dynamic>;
      final data = paragraph['data'] as Map<String, dynamic>;
      final delta = data['delta'] as List;

      final supLen = delta.fold<int>(0, (sum, op) {
        final m = op as Map<String, dynamic>;
        final attrs = m['attributes'] as Map<String, dynamic>?;
        if (attrs == null) return sum;
        if (attrs[kSloteSuperscriptAttribute] != true) return sum;
        final insert = m['insert'];
        if (insert is! String) return sum;
        return sum + insert.length;
      });

      expect(supLen, 2);
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

    test(
      'collapsed caret after superscript typing: sub toggle is exclusive',
      () async {
        ensureSloteAppFlowyRichTextKeysRegistered();
        final es = EditorState.blank(withInitialText: false);
        final setup = es.transaction;
        setup.insertNode([0], paragraphNode(text: 'ab'));
        await es.apply(setup);

        es.selection =
            Selection.single(path: [0], startOffset: 0, endOffset: 2).normalized;
        await sloteToggleSuperscript(es);

        var node = es.getNodeAtPath([0]);
        var tx = es.transaction;
        tx.insertText(
          node!,
          2,
          'c',
          toggledAttributes: es.toggledStyle,
        );
        await es.apply(tx);

        es.selection =
            Selection.single(path: [0], startOffset: 3, endOffset: 3).normalized;

        await sloteToggleSubscript(es);

        expect(es.toggledStyle[kSloteSubscriptAttribute], isTrue);
        expect(es.toggledStyle[kSloteSuperscriptAttribute], isFalse);
        expect(
          sloteIsFormatKeyActive(es, kSloteSuperscriptAttribute),
          isFalse,
        );
        expect(sloteIsFormatKeyActive(es, kSloteSubscriptAttribute), isTrue);

        node = es.getNodeAtPath([0]);
        tx = es.transaction;
        tx.insertText(
          node!,
          3,
          'd',
          toggledAttributes: es.toggledStyle,
        );
        await es.apply(tx);

        final delta = es.getNodeAtPath([0])!.delta!;
        TextInsert? dOp;
        for (final op in delta) {
          if (op is TextInsert && op.text == 'd') {
            dOp = op;
            break;
          }
        }
        expect(dOp, isNotNull);
        expect(dOp!.attributes![kSloteSubscriptAttribute], isTrue);
        expect(dOp.attributes![kSloteSuperscriptAttribute], isNot(isTrue));
      },
    );
  });

  group('Caret typing style sync', () {
    test('RichTextEditorController clears superscript typing style when caret leaves sup range',
        () async {
      final controller = RichTextEditorController(
        document: Document.fromJson({
          'document': {
            'type': 'page',
            'children': [
              {
                'type': 'paragraph',
                'data': {
                  'delta': [
                    {'insert': 'hello'}
                  ]
                }
              }
            ],
          }
        }),
      );

      // Apply superscript to the first two chars ('he').
      controller.editorState.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 2).normalized;
      await sloteToggleSuperscript(controller.editorState);

      final node = controller.editorState.getNodeAtPath([0]);
      final delta = node?.delta;
      if (delta == null) {
        fail('Expected node.delta to be non-null.');
      }
      final nonNullDelta = delta;

      // Pick a caret offset where AppFlowy reports superscript atCaret.
      final supCaretOffset = (() {
        for (var i = 0; i <= 5; i++) {
          final atCaret = nonNullDelta.sliceAttributes(i);
          if (atCaret?[kSloteSuperscriptAttribute] == true) return i;
        }
        return null;
      })();
      if (supCaretOffset == null) {
        fail('Expected to find a caret offset inside superscript span.');
      }
      final nonNullSupCaretOffset = supCaretOffset;

      controller.editorState.selection = Selection.single(
        path: [0],
        startOffset: nonNullSupCaretOffset,
        endOffset: nonNullSupCaretOffset,
      ).normalized;
      // Ensure the controller's selection listener runs in this unit test.
      (controller.editorState.selectionNotifier as dynamic).notifyListeners();
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.editorState.toggledStyle[kSloteSuperscriptAttribute] == true,
        isTrue,
      );

      // Pick a caret offset where AppFlowy reports baseline (no sup).
      final baseCaretOffset = (() {
        for (var i = 0; i <= 5; i++) {
          final atCaret = nonNullDelta.sliceAttributes(i);
          if (atCaret?[kSloteSuperscriptAttribute] != true) return i;
        }
        return null;
      })();
      if (baseCaretOffset == null) {
        fail('Expected to find a caret offset on baseline.');
      }
      final nonNullBaseCaretOffset = baseCaretOffset;

      controller.editorState.selection = Selection.single(
        path: [0],
        startOffset: nonNullBaseCaretOffset,
        endOffset: nonNullBaseCaretOffset,
      ).normalized;
      (controller.editorState.selectionNotifier as dynamic).notifyListeners();
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.editorState.toggledStyle[kSloteSuperscriptAttribute] == true,
        isFalse,
      );

      controller.dispose();
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
