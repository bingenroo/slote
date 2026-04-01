import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  testWidgets('sloteCaretMetrics returns script-sized caret metrics for subscript',
      (tester) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

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
                    'insert': 'a',
                    'attributes': {kSloteSubscriptAttribute: true},
                  },
                ],
              },
            },
          ],
        },
      }),
    );
    es.editorStyle = const EditorStyle.mobile();

    final node = es.getNodeAtPath([0]);
    expect(node, isNotNull);

    final cfg = TextStyleConfiguration(
      text: TextStyle(fontSize: 16),
    );

    final m = sloteCaretMetrics(
      context: ctx,
      editorState: es,
      node: node!,
      position: Position(path: [0], offset: 1),
      textStyleConfiguration: cfg,
    );

    expect(m, isNotNull);
    expect(m!.dy, greaterThan(0));

    final bodyPainter = TextPainter(
      text: const TextSpan(
        text: 'M',
        // Use an explicit line height similar to editor defaults; the script
        // caret should be smaller than a normal full-line caret.
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    expect(m.height, lessThan(bodyPainter.height));

    // But should include edge padding (avoid chopped caret).
    final scriptM = SloteSupSubMetrics.subscript(ctx, baseFontSize: 16);
    final scriptPainter = TextPainter(
      text: TextSpan(
        text: 'M',
        style: const TextStyle(fontSize: 16).copyWith(
          fontSize: 16 * scriptM.fontScale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(m.height, greaterThan(scriptPainter.height));
  });
}

