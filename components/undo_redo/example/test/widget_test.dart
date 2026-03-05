// Smoke test: example app builds and shows the undo/redo example screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:undo_redo_example/main.dart';

void main() {
  testWidgets('Example app builds and shows undo/redo example title', (WidgetTester tester) async {
    await tester.pumpWidget(const UndoRedoExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Undo/Redo Example'), findsOneWidget);
  });
}
