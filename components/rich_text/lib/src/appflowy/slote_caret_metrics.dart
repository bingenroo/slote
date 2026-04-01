import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'slote_inline_attributes.dart';
import 'slote_sup_sub_metrics.dart';

const _kSloteScriptCaretTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

/// General caret metrics override for Slote superscript/subscript runs.
///
/// This prevents Flutter from using full-line caret metrics when lines include
/// inline script [WidgetSpan]s, and ensures the caret height matches the script
/// glyph run (plus the same edge padding used by the WidgetSpan child).
EndOfParagraphCaretMetrics? sloteCaretMetrics({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required Position position,
  required TextStyleConfiguration textStyleConfiguration,
}) {
  // Ensure custom script keys participate in Delta.sliceAttributes even when
  // callers construct EditorState directly (e.g. tests, utilities).
  ensureSloteAppFlowyRichTextKeysRegistered();

  final delta = node.delta;
  if (delta == null || delta.isEmpty) return null;

  // Clamp offset to valid plain-text range.
  final plainTextLength = delta.toPlainText().length;
  final clampedOffset = position.offset.clamp(0, plainTextLength);

  // Caret at offset N sits between characters; prefer the style of the character
  // just before the caret so the caret matches the run you're in.
  final int probeIndex = (clampedOffset <= 0) ? 0 : (clampedOffset - 1);

  Attributes? attrs;
  try {
    attrs = delta.sliceAttributes(probeIndex);
  } catch (_) {
    attrs = null;
  }
  if (attrs == null || attrs.isEmpty) return null;

  bool _enabled(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return true; // any other non-null value counts as enabled
  }

  var rawSup = _enabled(attrs[kSloteSuperscriptAttribute]);
  var rawSub = _enabled(attrs[kSloteSubscriptAttribute]);
  // Sup/sub should be mutually exclusive; if both are present, prefer sup
  // (matches span decorator behavior).
  if (rawSup && rawSub) rawSub = false;

  final isSuperscript = rawSup && !rawSub;
  final isSubscript = rawSub && !rawSup;
  if (!isSuperscript && !isSubscript) {
    if (kDebugMode) {
      debugPrint(
        'DBG-SLOTE-CARET-METRICS skip offset=$clampedOffset keys=${attrs.keys.toList()}',
      );
    }
    return null;
  }

  final cfg = textStyleConfiguration;
  final baseFontSize =
      cfg.text.fontSize ?? SloteSupSubMetrics.fallbackBaseFontSize;
  // IMPORTANT: do not inherit line-height leading for scripts; measure the
  // script glyph run tightly (matches WidgetSpan Text behavior).
  final bodyStyle = cfg.text.copyWith(height: cfg.lineHeight);

  final m =
      isSuperscript
          ? SloteSupSubMetrics.superscript(context, baseFontSize: baseFontSize)
          : SloteSupSubMetrics.subscript(context, baseFontSize: baseFontSize);

  final probeStyle = bodyStyle.copyWith(
    fontSize: baseFontSize * m.fontScale,
    height: null,
  );

  final painter = TextPainter(
    text: TextSpan(text: 'M', style: probeStyle),
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: TextScaler.linear(editorState.editorStyle.textScaleFactor),
    textHeightBehavior: _kSloteScriptCaretTextHeight,
  )..layout(maxWidth: double.infinity);

  // For subscript, include the small top padding so the caret isn't clipped.
  // For superscript, do NOT include the large bottom padding (it's used to
  // position the WidgetSpan on the line, but it makes the caret too tall).
  final edgePaddingPx = isSuperscript ? 0.0 : m.translateY;

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: m.translateY,
  );
}
