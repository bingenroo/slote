import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'slote_inline_attributes.dart';
import 'slote_format_drawers.dart';
import 'slote_sup_sub_metrics.dart';

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
        if (!needsTypographyOverride || baseStyle == null) return baseStyle;
        final m = supSubMetrics!;
        return baseStyle.copyWith(
          // Keep attempting OpenType super/sub when supported by the font.
          fontFeatures: [
            ...?baseStyle.fontFeatures,
            if (isSuperscript) const FontFeature.superscripts(),
            if (isSubscript) const FontFeature.subscripts(),
          ],
          fontSize: baseFontSize * m.fontScale,
        );
      })();

  final dy = supSubMetrics?.translateY ?? 0.0;

  Widget supSubGlyph(String t, TextStyle? s) {
    return Text(
      t,
      style: s,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }

  if (href == null) {
    if (!needsTypographyOverride) return before;
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: supSubGlyph(text.text, typographyStyle),
          ),
        ),
      ],
    );
  }

  final editorState = context.read<EditorState>();
  Timer? longPressTimer;

  // Use GestureDetector inside a WidgetSpan so we can baseline-shift
  // superscripts/subscripts even for linked spans.
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: MouseRegion(
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
            child: Transform.translate(
              offset: Offset(0, dy),
              child: supSubGlyph(text.text, typographyStyle),
            ),
          ),
        ),
      ),
    ],
  );
}
