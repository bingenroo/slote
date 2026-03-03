// Smoke test: test app builds and shows the viewport test screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:slote_viewport_test/main.dart';

void main() {
  testWidgets('Test app builds and shows viewport test title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Slote Viewport Test'), findsOneWidget);
  });
}
