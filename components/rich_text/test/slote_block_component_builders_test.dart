import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('sloteHeadingTextStyleForLevel', () {
    test('matches AppFlowy H1–H3 sizes, distinct H4–H6', () {
      expect(sloteHeadingTextStyleForLevel(1).fontSize, 32);
      expect(sloteHeadingTextStyleForLevel(2).fontSize, 28);
      expect(sloteHeadingTextStyleForLevel(3).fontSize, 24);
      expect(sloteHeadingTextStyleForLevel(4).fontSize, 20);
      expect(sloteHeadingTextStyleForLevel(5).fontSize, 17);
      expect(sloteHeadingTextStyleForLevel(6).fontSize, 15);
    });

    test('clamps level into 1–6', () {
      expect(sloteHeadingTextStyleForLevel(0).fontSize, 32);
      expect(sloteHeadingTextStyleForLevel(99).fontSize, 15);
    });

    test('uses tight line height so body lineHeight does not inflate caret', () {
      expect(sloteHeadingTextStyleForLevel(1).height, 1.0);
    });

    test('heading builder map overrides stock heading entry', () {
      expect(
        sloteRichTextBlockComponentBuilders.containsKey(HeadingBlockKeys.type),
        isTrue,
      );
    });
  });
}
