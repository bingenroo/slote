import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RichTextEditorController (stability)', () {
    testWidgets('debounces onDocumentJsonChanged after apply', (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 40),
      );

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(t);

      expect(emitted, isEmpty);
      await tester.pump(const Duration(milliseconds: 50));
      expect(emitted.length, 1);
      expect(emitted.single['document'], isNotNull);

      controller.dispose();
    });

    testWidgets('skips inMemoryUpdate transactions', (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 20),
      );

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(
        t,
        options: const ApplyOptions(inMemoryUpdate: true),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(emitted, isEmpty);

      controller.dispose();
    });

    testWidgets('dispose cancels pending debounced emit', (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 500),
      );

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(t);

      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(emitted, isEmpty);
    });

    testWidgets('flushDocumentNotification emits immediately', (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 500),
      );

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(t);

      expect(emitted, isEmpty);
      controller.flushDocumentNotification();
      expect(emitted.length, 1);

      controller.dispose();
    });

    testWidgets('null onDocumentJsonChanged completes apply and pump safely',
        (tester) async {
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: null,
        debounce: const Duration(milliseconds: 20),
      );

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(t);
      await tester.pump(const Duration(milliseconds: 100));

      controller.dispose();
    });

    testWidgets('rapid applies coalesce to one debounced emit', (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 40),
      );

      var t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'a'));
      await controller.editorState.apply(t);

      t = controller.editorState.transaction;
      t.insertNode([1], paragraphNode(text: 'b'));
      await controller.editorState.apply(t);

      expect(emitted, isEmpty);
      await tester.pump(const Duration(milliseconds: 50));
      expect(emitted.length, 1);
      expect(emitted.single['document'], isNotNull);

      controller.dispose();
    });

    testWidgets('flushDocumentNotification after dispose does not throw',
        (tester) async {
      final emitted = <Map<String, Object>>[];
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        onDocumentJsonChanged: emitted.add,
        debounce: const Duration(milliseconds: 500),
      );

      controller.dispose();
      expect(() => controller.flushDocumentNotification(), returnsNormally);
      await tester.pump(const Duration(milliseconds: 100));
      expect(emitted, isEmpty);
    });
  });
}
