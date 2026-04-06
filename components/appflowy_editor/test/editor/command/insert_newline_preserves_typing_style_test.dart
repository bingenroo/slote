import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insertNewLine() formatting propagation', () {
    test('Reseeds toggledStyle from caret attributes after Enter', () async {
      final attrs = <String, dynamic>{
        AppFlowyRichTextKeys.bold: true,
        AppFlowyRichTextKeys.italic: true,
        AppFlowyRichTextKeys.fontSize: 24,
        AppFlowyRichTextKeys.textColor: '#00FF00',
        AppFlowyRichTextKeys.backgroundColor: '#FFC0CB',
      };

      final document = Document.blank(withInitialText: false);
      final editorState = EditorState(document: document);

      final delta = Delta()..insert('Hello', attributes: attrs);
      final node = paragraphNode(
        attributes: {
          'delta': delta.toJson(),
        },
      );
      document.insert([0], [node]);

      editorState.selection = Selection.collapsed(
        Position(
          path: [0],
          offset: delta.length,
        ),
      );

      final applied = await editorState.insertNewLine();
      expect(applied, isTrue);

      // After Enter, selection moved to the new paragraph (clearing toggledStyle),
      // then insertNewLine() should reseed it from the caret's slice attributes.
      expect(editorState.toggledStyle, containsPair(AppFlowyRichTextKeys.bold, true));
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.italic, true),
      );
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.fontSize, 24),
      );
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.textColor, '#00FF00'),
      );
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.backgroundColor, '#FFC0CB'),
      );
    });

    test('Keeps typing style across multiple consecutive Enters', () async {
      final attrs = <String, dynamic>{
        AppFlowyRichTextKeys.bold: true,
        AppFlowyRichTextKeys.italic: true,
        AppFlowyRichTextKeys.fontSize: 24,
        AppFlowyRichTextKeys.textColor: '#00FF00',
        AppFlowyRichTextKeys.backgroundColor: '#FFC0CB',
      };

      final document = Document.blank(withInitialText: false);
      final editorState = EditorState(document: document);

      final delta = Delta()..insert('Hello', attributes: attrs);
      final node = paragraphNode(
        attributes: {
          'delta': delta.toJson(),
        },
      );
      document.insert([0], [node]);

      editorState.selection = Selection.collapsed(
        Position(
          path: [0],
          offset: delta.length,
        ),
      );

      // First Enter: moves to new empty paragraph but keeps typing style.
      expect(await editorState.insertNewLine(), isTrue);
      expect(editorState.selection?.start.path, [1]);
      expect(editorState.toggledStyle, containsPair(AppFlowyRichTextKeys.fontSize, 24));

      // Second Enter on an empty paragraph: should still keep typing style.
      expect(await editorState.insertNewLine(), isTrue);
      expect(editorState.selection?.start.path, [2]);
      expect(editorState.toggledStyle, containsPair(AppFlowyRichTextKeys.bold, true));
      expect(editorState.toggledStyle, containsPair(AppFlowyRichTextKeys.italic, true));
      expect(editorState.toggledStyle, containsPair(AppFlowyRichTextKeys.fontSize, 24));
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.textColor, '#00FF00'),
      );
      expect(
        editorState.toggledStyle,
        containsPair(AppFlowyRichTextKeys.backgroundColor, '#FFC0CB'),
      );
    });
  });
}

