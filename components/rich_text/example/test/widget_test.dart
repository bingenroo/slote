import 'package:flutter_test/flutter_test.dart';

import 'package:rich_text_example/app.dart';

void main() {
  testWidgets('app builds and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const RichTextEditorApp());
    await tester.pump();

    expect(find.text('Rich text'), findsWidgets);
  });
}
