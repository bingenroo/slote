import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rich_text_example/app.dart';

void main() {
  group('Rich text example (stability)', () {
    testWidgets('app builds and shows title', (WidgetTester tester) async {
      await tester.pumpWidget(const RichTextEditorApp());
      await tester.pump();

      expect(find.text('Rich text'), findsWidgets);
    });

    testWidgets('formatting toolbar tooltips are present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const RichTextEditorApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byTooltip('Bold'), findsOneWidget);
      expect(find.byTooltip('Italic'), findsOneWidget);
      expect(find.byTooltip('Underline'), findsOneWidget);
      expect(find.byTooltip('Strikethrough'), findsOneWidget);
      expect(find.byTooltip('Link'), findsOneWidget);
      expect(find.byTooltip('Highlight'), findsOneWidget);
      expect(find.byTooltip('Text color'), findsOneWidget);
      expect(find.byTooltip('Clear formatting'), findsOneWidget);
      expect(find.byTooltip('Heading style'), findsOneWidget);
      expect(find.byTooltip('Align left'), findsOneWidget);
      expect(find.byTooltip('Justify'), findsOneWidget);
    });

    testWidgets('tearing down app after pump does not throw',
        (WidgetTester tester) async {
      await tester.pumpWidget(const RichTextEditorApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(const ColoredBox(color: Colors.black));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
