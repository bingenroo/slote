import 'package:appflowy_editor/appflowy_editor.dart';

class CodeBlockKeys {
  CodeBlockKeys._();

  static const String type = 'code';

  static const String delta = blockComponentDelta;

  static const String language = 'language';

  static const String backgroundColor = blockComponentBackgroundColor;

  static const String textDirection = blockComponentTextDirection;
}

Node codeBlockNode({
  String? text,
  Delta? delta,
  String? language,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node> children = const [],
}) {
  return Node(
    type: CodeBlockKeys.type,
    attributes: {
      CodeBlockKeys.delta: (delta ?? (Delta()..insert(text ?? ''))).toJson(),
      CodeBlockKeys.language: language ?? '',
      if (attributes != null) ...attributes,
      if (textDirection != null)
        CodeBlockKeys.textDirection: textDirection,
    },
    children: children,
  );
}

