// Smoke test: example app builds and shows the rich text example screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:rich_text_example/main.dart';

void main() {
  testWidgets('Example app builds and shows rich text example title', (WidgetTester tester) async {
    await tester.pumpWidget(const RichTextExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Rich Text Example'), findsOneWidget);
  });
}
