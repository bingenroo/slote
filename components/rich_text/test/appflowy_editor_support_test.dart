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

  test('standardCommandShortcutsWithSharedBius keeps length and replaces BIUS', () {
    final custom = standardCommandShortcutsWithSharedBius();
    final std = standardCommandShortcutEvents;
    expect(custom.length, std.length);
    for (var i = 0; i < std.length; i++) {
      expect(custom[i].key, std[i].key);
      if (isBiusCommandShortcutKey(std[i].key)) {
        expect(custom[i].handler, isNot(same(std[i].handler)));
      } else {
        expect(custom[i].handler, same(std[i].handler));
      }
    }
  });
}
