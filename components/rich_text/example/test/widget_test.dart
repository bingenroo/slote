import 'package:flutter_test/flutter_test.dart';

import 'package:rich_text_example/main.dart';

void main() {
  testWidgets('example builds and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFlowyEditorExampleApp());
    await tester.pump();

    expect(find.text('AppFlowy Editor Example'), findsWidgets);
  });
}
