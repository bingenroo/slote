import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'slote_inline_attributes.dart';
import 'slote_sup_sub_metrics.dart';

const _kSloteScriptCaretTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

/// Plain-text offset at the boundary **after** the last superscript character
/// (caret between char [offset]-1 and [offset]). [AppFlowyRichText] must pair
/// this with [TextAffinity.upstream] when the next glyph is subscript so
/// [RenderParagraph.getOffsetForCaret] uses the superscript line, not downstream
/// subscript metrics.
int? _sloteLastSuperscriptBoundaryPlainOffset(Delta delta, int plainLen) {
  if (plainLen == 0) return null;
  for (var k = plainLen; k >= 1; k--) {
    final attrs = delta.sliceAttributes(k);
    if (attrs != null &&
        attrs[kSloteSuperscriptAttribute] == true &&
        attrs[kSloteSubscriptAttribute] != true) {
      return k;
    }
  }
  return null;
}

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
  // [sliceAttributes]: for k>=1 returns attrs of plaintext char (k-1). To read
  // the last character at index plainLen-1, pass plainLen (same mapping as
  // [sloteCaretMetrics] for boundary offsets).
  final int sliceIndex = plainLen == 0 ? 0 : plainLen;
  final Attributes? endAttrs =
      (delta.isEmpty) ? null : delta.sliceAttributes(sliceIndex);

  var endRunSup = endAttrs?[kSloteSuperscriptAttribute] == true;
  var endRunSub = endAttrs?[kSloteSubscriptAttribute] == true;
  if (endRunSup && endRunSub) endRunSub = false;

  final toggled = editorState.toggledStyle;
  final toggledSup = toggled[kSloteSuperscriptAttribute] == true;
  final toggledSub = toggled[kSloteSubscriptAttribute] == true;

  final selection = editorState.selection;
  final bool caretAtEndOfThisNode =
      selection != null &&
      selection.isCollapsed &&
      selection.start.path.equals(node.path) &&
      selection.start.offset == plainLen;

  final toggledDiffersFromLastRun =
      (toggledSup != endRunSup) || (toggledSub != endRunSub);

  /// [toggleAttribute] left the key at explicit `false` while the last run is
  /// still script — next character uses body; caret must not stay on the
  /// script line or snap to the previous glyph there.
  final pendingBodyAfterScriptOff =
      caretAtEndOfThisNode &&
      ((endRunSup &&
              toggled[kSloteSuperscriptAttribute] == false &&
              // If switching to sub, don't force body.
              toggled[kSloteSubscriptAttribute] != true) ||
          (endRunSub &&
              toggled[kSloteSubscriptAttribute] == false &&
              // If switching to sup, don't force body.
              toggled[kSloteSuperscriptAttribute] != true));

  /// Next insert uses toggled sub when the last committed run is not yet
  /// subscript (body or superscript). [RenderParagraph]'s EOT caret may need
  /// [subscriptCaretTranslateYPendingBodyBaseline] — see merge in AppFlowy rich
  /// text. When the last run **is** already subscript, snap + [dy] 0.
  final pendingSubOnBodyBaseline =
      caretAtEndOfThisNode && toggledSub && !endRunSub;

  /// Next insert is superscript but the last committed run is still **body**
  /// (neither script). Do not use this when the last run is subscript: that
  /// needs [dy] 0 so the EOT merge can align with the sub glyph (the
  /// body-baseline sup nudge is wrong for sub → sup toggles).
  final pendingSupOnBodyBaseline =
      caretAtEndOfThisNode && toggledSup && !endRunSup && !endRunSub;

  final pendingSupAfterSubscriptRun =
      caretAtEndOfThisNode &&
      toggledSup &&
      !toggledSub &&
      endRunSub &&
      !endRunSup;
  final caretYAnchorPlainTextOffset =
      pendingSupAfterSubscriptRun
          ? _sloteLastSuperscriptBoundaryPlainOffset(delta, plainLen)
          : null;

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

  // Heading blocks and inline fontSize runs use different metrics than
  // [textStyleConfiguration.text]. This resolver previously always returned a
  // body-sized TextPainter probe at EOT; AppFlowyRichText then did
  // min(probe, previousGlyph), which kept the short height and clipped the
  // caret on headings. Delegate to RenderParagraph when we are not fixing
  // superscript/subscript or pending-body-after-script EOT behavior.
  if (!pendingBodyAfterScriptOff && !isSuperscript && !isSubscript) {
    return null;
  }

  // Only ignore the previous glyph for EOT merges when we rely on synthetic
  // [dy] from the body baseline. If the last run is already script, keep snap.
  // When [caretYAnchorPlainTextOffset] is set, AppFlowy uses anchor Y instead —
  // do not set ignore (height cap uses previous glyph usefully).
  final ignorePreviousCaretYAnchor =
      caretAtEndOfThisNode &&
      caretYAnchorPlainTextOffset == null &&
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
    final m =
        isSuperscript
            ? SloteSupSubMetrics.superscript(
              context,
              baseFontSize: baseFontSize,
            )
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
                ? SloteSupSubMetrics.subscriptCaretTranslateYPendingBodyBaseline(
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

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: dy,
    ignorePreviousCaretYAnchor: ignorePreviousCaretYAnchor,
    caretYAnchorPlainTextOffset: caretYAnchorPlainTextOffset,
  );
}
