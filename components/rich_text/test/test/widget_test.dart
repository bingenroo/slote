// Smoke test: test app builds and shows the rich text test screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:slote_rich_text_test/main.dart';

void main() {
  testWidgets('Test app builds and shows rich text test title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Slote Rich Text Test'), findsOneWidget);
  });
}
