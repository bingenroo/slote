// Smoke test: app builds and shows the main app bar title.

import 'package:flutter_test/flutter_test.dart';

import 'package:slote/main.dart';

void main() {
  testWidgets('App builds and shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Slote'), findsOneWidget);
  });
}
