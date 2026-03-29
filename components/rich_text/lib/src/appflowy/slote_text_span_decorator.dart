import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'slote_inline_attributes.dart';
import 'slote_format_drawers.dart';
import 'slote_sup_sub_metrics.dart';

const _kSloteScriptTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

/// Script-sized [Text] with layout padding for inline [WidgetSpan]s.
///
/// Plain sup/sub uses **one [WidgetSpan] per UTF-16 code unit** (same count as
/// [TextInsert.length]) so selection offsets match layout. A single [TextStyle]
/// cannot apply [TextStyle.baselineShift] on current stable Flutter.
/// Link+script uses a
/// single [WidgetSpan] for the whole run (same alignment and padding rules).
///
/// Superscript: [PlaceholderAlignment.aboveBaseline] + bottom [edgePaddingPx].
/// Subscript: [PlaceholderAlignment.belowBaseline] + top [edgePaddingPx].
Widget _sloteScriptSpanChild({
  required String text,
  required TextStyle? style,
  required bool isSuperscript,
  /// Logical px; superscript: bottom inset, subscript: top inset.
  required double edgePaddingPx,
}) {
  final textWidget = Text(
    text,
    style: style,
    textHeightBehavior: _kSloteScriptTextHeight,
  );
  if (edgePaddingPx <= 0) {
    return textWidget;
  }
  return isSuperscript
      ? Padding(
          padding: EdgeInsets.only(bottom: edgePaddingPx),
          child: textWidget,
        )
      : Padding(
          padding: EdgeInsets.only(top: edgePaddingPx),
          child: textWidget,
        );
}

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
  final rawIsSuperscript = attributes[kSloteSuperscriptAttribute] == true;
  final rawIsSubscript = attributes[kSloteSubscriptAttribute] == true;

  // Sup and sub are mutually exclusive; prefer superscript if corrupted.
  final isSuperscript = rawIsSuperscript && !rawIsSubscript;
  final isSubscript = rawIsSubscript && !rawIsSuperscript;

  final needsTypographyOverride = isSuperscript || isSubscript;
  final baseStyle = before.style;
  final baseFontSize =
      baseStyle?.fontSize ??
      DefaultTextStyle.of(context).style.fontSize ??
      SloteSupSubMetrics.fallbackBaseFontSize;

  final supSubMetrics = !needsTypographyOverride
      ? null
      : (isSuperscript
            ? SloteSupSubMetrics.superscript(context, baseFontSize: baseFontSize)
            : SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize));

  final typographyStyle =
      (() {
        if (!needsTypographyOverride) return baseStyle;
        final m = supSubMetrics!;
        final defaultStyle = DefaultTextStyle.of(context).style;
        final effectiveBase = baseStyle ?? defaultStyle;
        // Omit OpenType superscripts/subscripts: they resize/shift glyphs and
        // fight our explicit em-based positioning (reference apps use full-size
        // letters shifted on the line, not smaller OT alternates).
        return effectiveBase.copyWith(
          fontSize: baseFontSize * m.fontScale,
          color: baseStyle?.color ?? defaultStyle.color,
        );
      })();

  final dy = supSubMetrics?.translateY ?? 0.0;
  // [PlaceholderAlignment.baseline] ignores em-based shift; above/below
  // baseline + padding track [SloteSupSubMetrics.translateY].
  final scriptEdgePad =
      needsTypographyOverride ? (isSuperscript ? -dy : dy) : 0.0;
  final PlaceholderAlignment scriptPlaceholderAlignment = !needsTypographyOverride
      ? PlaceholderAlignment.baseline
      : (isSuperscript
            ? PlaceholderAlignment.aboveBaseline
            : PlaceholderAlignment.belowBaseline);

  if (href == null) {
    if (!needsTypographyOverride) return before;
    final t = text.text;
    return TextSpan(
      children: [
        for (var i = 0; i < t.length; i++)
          WidgetSpan(
            alignment: scriptPlaceholderAlignment,
            baseline: TextBaseline.alphabetic,
            child: _sloteScriptSpanChild(
              text: t.substring(i, i + 1),
              style: typographyStyle,
              isSuperscript: isSuperscript,
              edgePaddingPx: scriptEdgePad,
            ),
          ),
      ],
    );
  }

  final editorState = context.read<EditorState>();
  Timer? longPressTimer;

  Widget linkGestureChild(Widget child) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          longPressTimer = Timer(const Duration(milliseconds: 500), () {
            longPressTimer = null;
            if (!context.mounted) return;
            showSloteLinkFormatDrawer(editorState, hostContext: context);
          });
        },
        onTapUp: (_) {
          if (longPressTimer != null && longPressTimer!.isActive) {
            longPressTimer!.cancel();
            longPressTimer = null;
            unawaited(editorLaunchUrl(href));
          }
        },
        onTapCancel: () {
          longPressTimer?.cancel();
          longPressTimer = null;
        },
        child: child,
      ),
    );
  }

  // GestureDetector inside [WidgetSpan]. Link+script uses one placeholder;
  // caret may not address individual chars inside multi-char script.
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: scriptPlaceholderAlignment,
        baseline: TextBaseline.alphabetic,
        child: linkGestureChild(
          needsTypographyOverride
              ? _sloteScriptSpanChild(
                  text: text.text,
                  style: typographyStyle,
                  isSuperscript: isSuperscript,
                  edgePaddingPx: scriptEdgePad,
                )
              : Text(
                  text.text,
                  style: typographyStyle,
                  textHeightBehavior: _kSloteScriptTextHeight,
                ),
        ),
      ),
    ],
  );
}
