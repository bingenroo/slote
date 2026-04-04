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

  testWidgets(
    'sloteCaretMetrics uses character after caret (boundary before base, not sup)',
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

      // Plain indices: 0–1 base, 2–3 superscript, 4–5 base.
      final es = EditorState(
        document: Document.fromJson({
          'document': {
            'type': 'page',
            'children': [
              {
                'type': 'paragraph',
                'data': {
                  'delta': [
                    {'insert': 'ab'},
                    {
                      'insert': 'cd',
                      'attributes': {kSloteSuperscriptAttribute: true},
                    },
                    {'insert': 'ef'},
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

      // Caret before "e" (offset 4): must not use superscript of "c"/"d".
      final atBaseAfterSup = sloteCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        position: Position(path: [0], offset: 4),
        textStyleConfiguration: cfg,
      );
      expect(atBaseAfterSup, isNull);

      // Caret before "d" (offset 3): still within sup run.
      final inSup = sloteCaretMetrics(
        context: ctx,
        editorState: es,
        node: node,
        position: Position(path: [0], offset: 3),
        textStyleConfiguration: cfg,
      );
      expect(inSup, isNotNull);
    },
  );

  testWidgets(
    'sloteCaretMetrics returns null when superscript toggled off (pending body insert)',
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
                    {'insert': 'ab'},
                    {
                      'insert': 'cd',
                      'attributes': {kSloteSuperscriptAttribute: true},
                    },
                  ],
                },
              },
            ],
          },
        }),
      );
      es.editorStyle = const EditorStyle.mobile();
      es.selection =
          Selection.single(path: [0], startOffset: 3, endOffset: 3).normalized;
      es.updateToggledStyle(kSloteSuperscriptAttribute, false);

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
      );

      final m = sloteCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        position: Position(path: [0], offset: 3),
        textStyleConfiguration: cfg,
      );
      expect(m, isNull);
    },
  );

  testWidgets(
    'sloteEndOfParagraphCaretMetrics uses body metrics when sup toggled off at EOT',
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
                    {'insert': 'ab'},
                    {
                      'insert': 'cd',
                      'attributes': {kSloteSuperscriptAttribute: true},
                    },
                  ],
                },
              },
            ],
          },
        }),
      );
      es.editorStyle = const EditorStyle.mobile();
      es.selection =
          Selection.single(path: [0], startOffset: 4, endOffset: 4).normalized;
      es.updateToggledStyle(kSloteSuperscriptAttribute, false);

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
        lineHeight: 1.5,
      );

      final m = sloteEndOfParagraphCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        textStyleConfiguration: cfg,
      );
      expect(m, isNotNull);
      expect(m!.ignorePreviousCaretYAnchor, isTrue);
      expect(m.dy, 0.0);

      const tightBodyHeightBehavior = TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      );
      final tightBodyPainter = TextPainter(
        text: TextSpan(
          text: 'M',
          style: cfg.text.copyWith(height: null),
        ),
        textDirection: TextDirection.ltr,
        textHeightBehavior: tightBodyHeightBehavior,
      )..layout();
      expect(
        (m.height - tightBodyPainter.height).abs(),
        lessThan(0.02),
      );

      final fullLinePainter = TextPainter(
        text: TextSpan(
          text: 'M',
          style: cfg.text.copyWith(height: cfg.lineHeight),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(m.height, lessThan(fullLinePainter.height));
    },
  );

  testWidgets(
    'sloteEndOfParagraphCaretMetrics EOT: last char sup only — snap, dy 0',
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

      // Plain: "ab" body + "c" superscript. Wrong sliceIndex would read "b" as end run.
      final es = EditorState(
        document: Document.fromJson({
          'document': {
            'type': 'page',
            'children': [
              {
                'type': 'paragraph',
                'data': {
                  'delta': [
                    {'insert': 'ab'},
                    {
                      'insert': 'c',
                      'attributes': {kSloteSuperscriptAttribute: true},
                    },
                  ],
                },
              },
            ],
          },
        }),
      );
      es.editorStyle = const EditorStyle.mobile();
      es.selection =
          Selection.single(path: [0], startOffset: 3, endOffset: 3).normalized;
      es.updateToggledStyle(kSloteSuperscriptAttribute, true);
      es.updateToggledStyle(kSloteSubscriptAttribute, false);

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
        lineHeight: 1.5,
      );

      final m = sloteEndOfParagraphCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        textStyleConfiguration: cfg,
      );
      expect(m, isNotNull);
      expect(m!.ignorePreviousCaretYAnchor, isFalse);
      expect(m.dy, 0.0);
    },
  );

  testWidgets(
    'sloteEndOfParagraphCaretMetrics EOT: last char sub only — snap, dy 0',
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
                    {'insert': 'ab'},
                    {
                      'insert': 'c',
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
      es.selection =
          Selection.single(path: [0], startOffset: 3, endOffset: 3).normalized;
      es.updateToggledStyle(kSloteSubscriptAttribute, true);
      es.updateToggledStyle(kSloteSuperscriptAttribute, false);

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
        lineHeight: 1.5,
      );

      final m = sloteEndOfParagraphCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        textStyleConfiguration: cfg,
      );
      expect(m, isNotNull);
      expect(m!.ignorePreviousCaretYAnchor, isFalse);
      expect(m.dy, 0.0);
    },
  );

  testWidgets(
    'sloteEndOfParagraphCaretMetrics returns null at EOT for plain heading (no script)',
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
                'type': 'heading',
                'data': {
                  'delta': [
                    {'insert': 'Header 1'},
                  ],
                  'level': 1,
                },
              },
            ],
          },
        }),
      );
      es.editorStyle = const EditorStyle.mobile();
      es.selection =
          Selection.single(path: [0], startOffset: 8, endOffset: 8).normalized;

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
        lineHeight: 1.5,
      );

      final m = sloteEndOfParagraphCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        textStyleConfiguration: cfg,
      );
      expect(
        m,
        isNull,
        reason:
            'Body-sized EOT probe must not override heading caret from RenderParagraph',
      );
    },
  );

  testWidgets(
    'sloteEndOfParagraphCaretMetrics EOT: toggled sup after sub run — dy 0, not body-sup nudge',
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

      // Body + one superscript char + one subscript char; caret at EOT with
      // superscript toggled on (next insert is sup after sub — not body→sup).
      final es = EditorState(
        document: Document.fromJson({
          'document': {
            'type': 'page',
            'children': [
              {
                'type': 'paragraph',
                'data': {
                  'delta': [
                    {'insert': 'ab'},
                    {
                      'insert': 'c',
                      'attributes': {kSloteSuperscriptAttribute: true},
                    },
                    {
                      'insert': 'd',
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
      es.selection =
          Selection.single(path: [0], startOffset: 4, endOffset: 4).normalized;
      es.updateToggledStyle(kSloteSuperscriptAttribute, true);
      es.updateToggledStyle(kSloteSubscriptAttribute, false);

      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);

      final cfg = TextStyleConfiguration(
        text: const TextStyle(fontSize: 16),
        lineHeight: 1.5,
      );

      final m = sloteEndOfParagraphCaretMetrics(
        context: ctx,
        editorState: es,
        node: node!,
        textStyleConfiguration: cfg,
      );
      expect(m, isNotNull);
      expect(m!.dy, 0.0);
      expect(m.ignorePreviousCaretYAnchor, isFalse);
      expect(m.caretYAnchorPlainTextOffset, 3);
    },
  );
}

