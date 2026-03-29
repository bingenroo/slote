import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  group('slote_heading_support', () {
    test('collapsed caret: paragraph becomes H1 then toggles back', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'hello'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 2, endOffset: 2).normalized;

      await sloteToggleHeadingLevel(es, 1);
      var node = es.getNodeAtPath([0]);
      expect(node?.type, HeadingBlockKeys.type);
      expect(node?.attributes[HeadingBlockKeys.level], 1);
      expect(sloteHeadingLevelAtSelectionStart(es), 1);

      await sloteToggleHeadingLevel(es, 1);
      node = es.getNodeAtPath([0]);
      expect(node?.type, ParagraphBlockKeys.type);
      expect(sloteHeadingLevelAtSelectionStart(es), isNull);
    });

    test('sloteApplyParagraphBody clears heading at caret', () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], headingNode(level: 2, text: 'hi'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 1, endOffset: 1).normalized;

      await sloteApplyParagraphBody(es);
      final node = es.getNodeAtPath([0]);
      expect(node?.type, ParagraphBlockKeys.type);
    });

    test('sloteCanUseBlockHeadingControls true for paragraph with caret',
        () async {
      final es = EditorState.blank(withInitialText: false);
      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await es.apply(t);
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;

      expect(sloteCanUseBlockHeadingControls(es), isTrue);
    });
  });
}
