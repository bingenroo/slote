import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sloteEditor undo/redo helpers', () {
    testWidgets('canUndo after apply; undo then canRedo', (tester) async {
      final es = EditorState(document: Document.blank(withInitialText: false));
      expect(sloteEditorCanUndo(es), isFalse);
      expect(sloteEditorCanRedo(es), isFalse);

      final t = es.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await es.apply(t);

      expect(sloteEditorCanUndo(es), isTrue);
      expect(sloteEditorCanRedo(es), isFalse);

      sloteEditorUndo(es);
      expect(sloteEditorCanUndo(es), isFalse);
      expect(sloteEditorCanRedo(es), isTrue);

      sloteEditorRedo(es);
      expect(sloteEditorCanUndo(es), isTrue);
      expect(sloteEditorCanRedo(es), isFalse);

      es.dispose();
    });
  });

  group('RichTextEditorController undoRedoListenable', () {
    testWidgets('notifies when canUndo transitions', (tester) async {
      var notifications = 0;
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        debounce: const Duration(milliseconds: 500),
      );
      controller.undoRedoListenable.addListener(() => notifications++);

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'a'));
      await controller.editorState.apply(t);

      expect(notifications, 1);

      final t2 = controller.editorState.transaction;
      t2.insertNode([1], paragraphNode(text: 'b'));
      await controller.editorState.apply(t2);

      // (canUndo, canRedo) unchanged — still undoable, not redoable
      expect(notifications, 1);

      sloteEditorUndo(controller.editorState);
      await tester.pump();
      expect(notifications, 2);

      controller.dispose();
    });

    testWidgets('skips undoRedo notification for inMemoryUpdate', (tester) async {
      var notifications = 0;
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
        debounce: const Duration(milliseconds: 20),
      );
      controller.undoRedoListenable.addListener(() => notifications++);

      final t = controller.editorState.transaction;
      t.insertNode([0], paragraphNode(text: 'x'));
      await controller.editorState.apply(
        t,
        options: const ApplyOptions(inMemoryUpdate: true),
      );

      expect(notifications, 0);
      controller.dispose();
    });

    testWidgets('dispose disposes undoRedoListenable', (tester) async {
      final controller = RichTextEditorController(
        document: Document.blank(withInitialText: false),
      );
      controller.dispose();
      expect(
        () => controller.undoRedoListenable.addListener(() {}),
        throwsFlutterError,
      );
    });
  });
}
