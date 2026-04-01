import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'slote_inline_attributes.dart';
import 'slote_sup_sub_metrics.dart';

const _kSloteScriptCaretTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

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

  // Determine caret style at paragraph end.
  //
  // - When the caret is at the end and the user has an active typing style
  //   (toggled sup/sub), prefer that (caret should match the next insert).
  // - Otherwise, fall back to the actual style of the last character (so moving
  //   to the end of an existing run matches that run).
  final delta = node.delta!;
  final plainLen = delta.toPlainText().length;
  final int sliceIndex = plainLen == 0 ? 0 : (plainLen - 1);
  final Attributes? endAttrs =
      (delta.isEmpty) ? null : delta.sliceAttributes(sliceIndex);

  final toggled = editorState.toggledStyle;
  final toggledSup = toggled[kSloteSuperscriptAttribute] == true;
  final toggledSub = toggled[kSloteSubscriptAttribute] == true;

  final selection = editorState.selection;
  final bool caretAtEndOfThisNode = selection != null &&
      selection.isCollapsed &&
      selection.start.path.equals(node.path) &&
      selection.start.offset == plainLen;

  bool rawSup;
  bool rawSub;
  if (caretAtEndOfThisNode && (toggledSup || toggledSub)) {
    rawSup = toggledSup;
    rawSub = toggledSub;
  } else {
    rawSup = endAttrs?[kSloteSuperscriptAttribute] == true;
    rawSub = endAttrs?[kSloteSubscriptAttribute] == true;
    if (endAttrs == null) {
      rawSup = toggledSup;
      rawSub = toggledSub;
    }
  }

  // Sup/sub should be mutually exclusive; if both are present, prefer sup.
  if (rawSup && rawSub) rawSub = false;

  final isSuperscript = rawSup && !rawSub;
  final isSubscript = rawSub && !rawSup;

  double dy = 0.0;
  var probeStyle = bodyStyle;
  var probeTextHeightBehavior = const TextHeightBehavior();
  if (isSuperscript || isSubscript) {
    final m = isSuperscript
        ? SloteSupSubMetrics.superscript(context, baseFontSize: baseFontSize)
        : SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize);
    // Measure scripts tightly: avoid inheriting line-height leading.
    probeStyle = bodyStyle.copyWith(
      fontSize: baseFontSize * m.fontScale,
      height: null,
    );
    dy = m.translateY;
    probeTextHeightBehavior = _kSloteScriptCaretTextHeight;
  }

  final painter = TextPainter(
    text: TextSpan(text: 'M', style: probeStyle),
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: TextScaler.linear(editorState.editorStyle.textScaleFactor),
    textHeightBehavior: probeTextHeightBehavior,
  )..layout(maxWidth: double.infinity);

  // Keep subscript padding to avoid clipping; avoid large superscript padding
  // which makes the caret appear too tall.
  final edgePaddingPx = isSubscript ? dy : 0.0;

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: dy,
  );
}
