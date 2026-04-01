import 'package:appflowy_editor/appflowy_editor.dart';

class CalloutBlockKeys {
  CalloutBlockKeys._();

  static const String type = 'callout';

  static const String delta = blockComponentDelta;

  /// Semantic callout kind (e.g. info, warning). Rendering may choose styling.
  static const String kind = 'kind';

  static const String backgroundColor = blockComponentBackgroundColor;

  static const String textDirection = blockComponentTextDirection;
}

Node calloutNode({
  String? text,
  Delta? delta,
  String kind = 'info',
  String? textDirection,
  Attributes? attributes,
  Iterable<Node> children = const [],
}) {
  return Node(
    type: CalloutBlockKeys.type,
    attributes: {
      CalloutBlockKeys.delta: (delta ?? (Delta()..insert(text ?? ''))).toJson(),
      CalloutBlockKeys.kind: kind,
      if (attributes != null) ...attributes,
      if (textDirection != null)
        CalloutBlockKeys.textDirection: textDirection,
    },
    children: children,
  );
}

