// Smoke test: test app builds and shows the draw test screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:slote_draw_test/main.dart';

void main() {
  testWidgets('Test app builds and shows draw test title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Slote Draw Test'), findsOneWidget);
  });
}
