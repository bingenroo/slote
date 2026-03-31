import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'slote_inline_attributes.dart';
import 'slote_sup_sub_metrics.dart';

/// Caret height at paragraph end from [EditorState.toggledStyle] so the I-beam
/// matches the next insert (body vs superscript vs subscript), not full-line
/// metrics when the line mixes script [WidgetSpan]s.
///
/// Pass to [EditorStyle.endOfParagraphCaretHeight].
double? sloteEndOfParagraphCaretHeight({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required TextStyleConfiguration textStyleConfiguration,
}) {
  final m = sloteEndOfParagraphCaretMetrics(
    context: context,
    editorState: editorState,
    node: node,
    textStyleConfiguration: textStyleConfiguration,
  );
  return m?.height;
}

/// Caret metrics at paragraph end from [EditorState.toggledStyle].
///
/// Pass to [EditorStyle.endOfParagraphCaretMetrics].
EndOfParagraphCaretMetrics? sloteEndOfParagraphCaretMetrics({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required TextStyleConfiguration textStyleConfiguration,
}) {
  if (node.delta == null) return null;

  final cfg = textStyleConfiguration;
  final baseFontSize =
      cfg.text.fontSize ?? SloteSupSubMetrics.fallbackBaseFontSize;
  final bodyStyle = cfg.text.copyWith(height: cfg.lineHeight);

  final toggled = editorState.toggledStyle;
  final rawSup = toggled[kSloteSuperscriptAttribute] == true;
  final rawSub = toggled[kSloteSubscriptAttribute] == true;
  final isSuperscript = rawSup && !rawSub;
  final isSubscript = rawSub && !rawSup;

  double dy = 0.0;
  var probeStyle = bodyStyle;
  if (isSuperscript || isSubscript) {
    final m = isSuperscript
        ? SloteSupSubMetrics.superscript(context, baseFontSize: baseFontSize)
        : SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize);
    probeStyle = bodyStyle.copyWith(fontSize: baseFontSize * m.fontScale);
    dy = m.translateY;
  }

  final painter = TextPainter(
    text: TextSpan(text: 'M', style: probeStyle),
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: TextScaler.linear(editorState.editorStyle.textScaleFactor),
  )..layout(maxWidth: double.infinity);

  // Match the script WidgetSpan child padding so the caret doesn't appear cut.
  final edgePaddingPx =
      (isSuperscript || isSubscript) ? (isSuperscript ? -dy : dy) : 0.0;

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: dy,
  );
}
