// Smoke test: example app builds and shows the draw example screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:draw_example/main.dart';

void main() {
  testWidgets('Example app builds and shows draw example title', (WidgetTester tester) async {
    await tester.pumpWidget(const DrawExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Draw Example'), findsOneWidget);
  });
}
