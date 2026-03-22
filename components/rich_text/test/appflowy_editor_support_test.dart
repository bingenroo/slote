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
  });
}
