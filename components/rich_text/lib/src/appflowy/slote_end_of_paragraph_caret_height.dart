import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
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

  var endRunSup = endAttrs?[kSloteSuperscriptAttribute] == true;
  var endRunSub = endAttrs?[kSloteSubscriptAttribute] == true;
  if (endRunSup && endRunSub) endRunSub = false;

  final toggled = editorState.toggledStyle;
  final toggledSup = toggled[kSloteSuperscriptAttribute] == true;
  final toggledSub = toggled[kSloteSubscriptAttribute] == true;

  final selection = editorState.selection;
  final bool caretAtEndOfThisNode = selection != null &&
      selection.isCollapsed &&
      selection.start.path.equals(node.path) &&
      selection.start.offset == plainLen;

  final toggledDiffersFromLastRun =
      (toggledSup != endRunSup) || (toggledSub != endRunSub);

  /// [toggleAttribute] left the key at explicit `false` while the last run is
  /// still script — next character uses body; caret must not stay on the
  /// script line or snap to the previous glyph there.
  final pendingBodyAfterScriptOff = caretAtEndOfThisNode &&
      ((endRunSup && toggled[kSloteSuperscriptAttribute] == false) ||
          (endRunSub && toggled[kSloteSubscriptAttribute] == false));

  /// Next insert uses toggled sub/sup but the last committed run is still body
  /// (or the other script). [RenderParagraph]'s EOT caret stays on the body
  /// line — use [subscriptCaretTranslateYPendingBodyBaseline] / sup nudge and
  /// skip snapping to the previous glyph.
  ///
  /// When the last run **is** already subscript, the previous index caret Y
  /// matches the real script line; snapping is correct and [dy] must be 0.
  final pendingSubOnBodyBaseline =
      caretAtEndOfThisNode && toggledSub && !endRunSub;
  final pendingSupOnBodyBaseline =
      caretAtEndOfThisNode && toggledSup && !endRunSup;

  bool rawSup;
  bool rawSub;
  if (pendingBodyAfterScriptOff) {
    rawSup = false;
    rawSub = false;
  } else if (caretAtEndOfThisNode && (toggledSup || toggledSub)) {
    rawSup = toggledSup;
    rawSub = toggledSub;
  } else {
    rawSup = endRunSup;
    rawSub = endRunSub;
    if (endAttrs == null) {
      rawSup = toggledSup;
      rawSub = toggledSub;
    }
  }

  // Sup/sub should be mutually exclusive; if both are present, prefer sup.
  if (rawSup && rawSub) rawSub = false;

  final isSuperscript = rawSup && !rawSub;
  final isSubscript = rawSub && !rawSup;

  // Only ignore the previous glyph for EOT merges when we rely on synthetic
  // [dy] from the body baseline. If the last run is already script, keep snap.
  final ignorePreviousCaretYAnchor = caretAtEndOfThisNode &&
      (pendingSubOnBodyBaseline ||
          pendingSupOnBodyBaseline ||
          pendingBodyAfterScriptOff ||
          ((toggledSup || toggledSub) && toggledDiffersFromLastRun));

  double dy = 0.0;
  double edgePaddingPx = 0.0;
  var probeStyle = bodyStyle;
  var probeTextHeightBehavior = const TextHeightBehavior();

  // Next insert is body but the last committed glyph is still script. Use the
  // same tight vertical box as mid-line body carets ([RenderParagraph] EOT at a
  // body offset), not the full cfg.line-height strut (~fontSize * lineHeight).
  if (pendingBodyAfterScriptOff) {
    probeStyle = bodyStyle.copyWith(height: null);
    probeTextHeightBehavior = _kSloteScriptCaretTextHeight;
  }

  if (isSuperscript || isSubscript) {
    final m = isSuperscript
        ? SloteSupSubMetrics.superscript(context, baseFontSize: baseFontSize)
        : SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize);
    // Measure scripts tightly: avoid inheriting line-height leading.
    probeStyle = bodyStyle.copyWith(
      fontSize: baseFontSize * m.fontScale,
      height: null,
    );
    if (isSubscript) edgePaddingPx = m.translateY;
    dy =
        isSuperscript
            ? (pendingSupOnBodyBaseline
                ? m.translateY *
                    SloteSupSubMetrics.superscriptCaretTranslateYFactor
                : 0.0)
            : isSubscript
                ? (pendingSubOnBodyBaseline
                    ? SloteSupSubMetrics
                        .subscriptCaretTranslateYPendingBodyBaseline(
                        context,
                        baseFontSize: baseFontSize,
                      )
                    : 0.0)
                : m.translateY;
    probeTextHeightBehavior = _kSloteScriptCaretTextHeight;
  }

  final painter = TextPainter(
    text: TextSpan(text: 'M', style: probeStyle),
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: TextScaler.linear(editorState.editorStyle.textScaleFactor),
    textHeightBehavior: probeTextHeightBehavior,
  )..layout(maxWidth: double.infinity);

  // Keep subscript padding to avoid clipping; avoid large superscript padding
  // which makes the caret appear too tall. [edgePaddingPx] is in-span
  // [translateY] only, not the larger pending-body subscript caret [dy].

  if (kDebugMode) {
    final scaledEm = MediaQuery.textScalerOf(context).scale(baseFontSize);
    final pendingExtraPx =
        SloteSupSubMetrics.subscriptPendingCaretExtraEm * scaledEm;
    debugPrint(
      'DBG-EOT-CARET plainLen=$plainLen sliceIndex=$sliceIndex '
      'caretAtEnd=$caretAtEndOfThisNode off=${selection?.start.offset} '
      'endRunSup=$endRunSup endRunSub=$endRunSub '
      'toggledSup=$toggledSup toggledSub=$toggledSub '
      'toggledDiffers=$toggledDiffersFromLastRun '
      'pendSubBody=$pendingSubOnBodyBaseline pendSupBody=$pendingSupOnBodyBaseline '
      'ignorePrevYAnchor=$ignorePreviousCaretYAnchor '
      'isSup=$isSuperscript isSub=$isSubscript '
      'scaledEm=${scaledEm.toStringAsFixed(2)} '
      'inSpanTy=${isSubscript ? SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize).translateY.toStringAsFixed(2) : "n/a"} '
      'pendingExtraPx=${isSubscript ? pendingExtraPx.toStringAsFixed(2) : "n/a"} '
      'dy=${dy.toStringAsFixed(2)} h=${(painter.height + edgePaddingPx).toStringAsFixed(2)}',
    );
  }

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: dy,
    ignorePreviousCaretYAnchor: ignorePreviousCaretYAnchor,
  );
}
