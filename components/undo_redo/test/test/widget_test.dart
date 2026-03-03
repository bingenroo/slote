// Smoke test: test app builds and shows the undo/redo test screen title.

import 'package:flutter_test/flutter_test.dart';

import 'package:slote_undo_redo_test/main.dart';

void main() {
  testWidgets('Test app builds and shows undo/redo test title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Slote Undo/Redo Test'), findsOneWidget);
  });
}
