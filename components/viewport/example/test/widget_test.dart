// Smoke test: example app builds and shows the viewport example screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:viewport_example/main.dart';

void main() {
  testWidgets('Example app builds and shows viewport example title', (WidgetTester tester) async {
    await tester.pumpWidget(const ViewportExampleApp());
    await tester.pump();

    expect(find.text('Viewport Example'), findsOneWidget);
  });
}
