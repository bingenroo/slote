import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RichTextEditorController (stability)', () {
    testWidgets('restores pending toggledStyle when caret is first planted',
        (tester) async {
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: true),
      );
      final es = controller.editorState;

      expect(es.selection, isNull);
      applyBiusToggle(es, AppFlowyRichTextKeys.bold);
      await sloteApplyFontFamily(es, 'serif');
      await sloteApplyFontSize(es, 18);

      // Simulate the editor planting a caret selection.
      es.selection =
          Selection.single(path: [0], startOffset: 0, endOffset: 0).normalized;
      (es.selectionNotifier as dynamic).notifyListeners();

      // Let the controller restore pending toggledStyle.
      await tester.pump();

      expect(es.toggledStyle[AppFlowyRichTextKeys.bold], isTrue);
      expect(es.toggledStyle[AppFlowyRichTextKeys.fontFamily], 'serif');
      expect(es.toggledStyle[AppFlowyRichTextKeys.fontSize], 18);

      // Verify IME contract: insertText uses `toggledStyle` for new text.
      final node = es.getNodeAtPath([0]);
      expect(node, isNotNull);
      final tx = es.transaction;
      tx.insertText(
        node!,
        0,
        'x',
        toggledAttributes: es.toggledStyle,
        sliceAttributes: true,
      );
      await es.apply(tx);
      final updated = es.getNodeAtPath([0]);
      expect(updated, isNotNull);
      final delta = updated!.delta;
      expect(delta, isNotNull);
      final first = delta!.iterator..moveNext();
      final op = first.current;
      expect(op, isA<TextInsert>());
      final attrs = (op as TextInsert).attributes;
      expect(attrs?[AppFlowyRichTextKeys.bold], isTrue);

      controller.dispose();
    });

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
