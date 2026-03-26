import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'slote_inline_attributes.dart';
import 'slote_format_drawers.dart';

/// Slote link behavior: **quick tap** opens the URL via [editorLaunchUrl] without
/// first selecting the span; **long press** (~500ms) opens the link format drawer.
///
/// Assign [editorLaunchUrl] in the app (e.g. in `main()`) for reliable
/// `url_launcher` behavior; stock AppFlowy mobile code calls `safeLaunchUrl`
/// directly and always selects on tap-down.
TextSpan sloteTextSpanDecoratorForAttribute(
  BuildContext context,
  Node node,
  int index,
  TextInsert text,
  TextSpan before,
  TextSpan after,
) {
  final attributes = text.attributes;
  if (attributes == null) {
    return before;
  }
  final href = attributes[AppFlowyRichTextKeys.href] as String?;
  final isSuperscript = attributes[kSloteSuperscriptAttribute] == true;
  final isSubscript = attributes[kSloteSubscriptAttribute] == true;

  final needsTypographyOverride = isSuperscript || isSubscript;
  final baseStyle = before.style;
  final typographyStyle = (() {
    if (!needsTypographyOverride || baseStyle == null) return baseStyle;
    return baseStyle.copyWith(
      // Keep attempting OpenType super/sub when supported by the font.
      fontFeatures: [
        ...?baseStyle.fontFeatures,
        if (isSuperscript) const FontFeature.superscripts(),
        if (isSubscript) const FontFeature.subscripts(),
      ],
    );
  })();

  if (href == null) {
    if (!needsTypographyOverride) return before;
    final dy = isSuperscript ? -5.0 : 4.0;
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Text(text.text, style: typographyStyle),
          ),
        ),
      ],
    );
  }

  final editorState = context.read<EditorState>();
  Timer? longPressTimer;

  final recognizer = TapGestureRecognizer()
    ..onTapDown = (_) {
      longPressTimer = Timer(const Duration(milliseconds: 500), () {
        longPressTimer = null;
        if (!context.mounted) return;
        showSloteLinkFormatDrawer(editorState, hostContext: context);
      });
    }
    ..onTapUp = (_) {
      if (longPressTimer != null && longPressTimer!.isActive) {
        longPressTimer!.cancel();
        longPressTimer = null;
        unawaited(editorLaunchUrl(href));
      }
    }
    ..onTapCancel = () {
      longPressTimer?.cancel();
      longPressTimer = null;
    };

  return TextSpan(
    style: typographyStyle,
    text: text.text,
    recognizer: recognizer,
    mouseCursor: SystemMouseCursors.click,
  );
}
