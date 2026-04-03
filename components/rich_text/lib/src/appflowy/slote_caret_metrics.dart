import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

  // [sliceAttributes] follows AppFlowy's default rules: for index k>=1 it returns
  // attributes of plaintext character (k-1); for k==0, character 0.
  //
  // Flutter [TextPosition.offset] is the index of the code unit *after* the caret
  // (caret sits before that character). With downstream affinity we want the style
  // of that following character — i.e. plain index `clampedOffset`. That maps to
  // slice index `clampedOffset + 1` (or 0 when offset is 0; both yield char 0).
  //
  // Using `offset - 1` here was off-by-one and made the caret pick the *previous*
  // run at sup/base boundaries (caret before base text still used superscript).
  final int sliceProbe =
      clampedOffset >= plainTextLength
          ? plainTextLength
          : (clampedOffset + 1).clamp(0, plainTextLength);

  Attributes? attrs;
  try {
    attrs = delta.sliceAttributes(sliceProbe);
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

  final selection = editorState.selection;
  final toggled = editorState.toggledStyle;

  final toggledSup = _enabled(toggled[kSloteSuperscriptAttribute]);
  final toggledSub = _enabled(toggled[kSloteSubscriptAttribute]);

  var rawSup = _enabled(attrs[kSloteSuperscriptAttribute]);
  var rawSub = _enabled(attrs[kSloteSubscriptAttribute]);
  final sliceHadSubscript = rawSub;

  // [toggleAttribute] stores explicit `false` when turning script off at a
  // collapsed caret; the slice still reflects the committed run until the user
  // types. Caret should match body (next insert), not the script box.
  if (selection?.isCollapsed == true) {
    final supExplicitOff = toggled[kSloteSuperscriptAttribute] == false;
    final subExplicitOff = toggled[kSloteSubscriptAttribute] == false;
    // When switching sup <-> sub we intentionally set the opposite key to
    // explicit `false` to override slice attributes on the next insert. In that
    // case we must NOT treat the explicit-off as "turn script off to body".
    final switchingToSup = toggledSup && subExplicitOff;
    final switchingToSub = toggledSub && supExplicitOff;
    if (!switchingToSup &&
        !switchingToSub &&
        ((rawSup && supExplicitOff) || (rawSub && subExplicitOff))) {
      return null;
    }
  }

  // If we're in "pending typing style" mode, that should drive caret metrics.
  if (selection?.isCollapsed == true && (toggledSup || toggledSub)) {
    rawSup = toggledSup;
    rawSub = toggledSub;
  }

  // Sup/sub should be mutually exclusive; if both are present, prefer sup
  // (matches span decorator behavior).
  if (rawSup && rawSub) rawSub = false;

  final isSuperscript = rawSup && !rawSub;
  final isSubscript = rawSub && !rawSup;
  if (!isSuperscript && !isSubscript) {
    // if (kDebugMode) {
    //   debugPrint(
    //     'DBG-SLOTE-CARET-METRICS skip offset=$clampedOffset sliceProbe=$sliceProbe '
    //     'plainLen=$plainTextLength keys=${attrs.keys.toList()} '
    //     'rawSup=$rawSup rawSub=$rawSub',
    //   );
    // }
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

  final pendingSubOnBodyBaseline =
      isSubscript &&
      toggledSub &&
      !sliceHadSubscript &&
      selection?.isCollapsed == true;

  final caretDy =
      isSuperscript
          ? m.translateY * SloteSupSubMetrics.superscriptCaretTranslateYFactor
          : pendingSubOnBodyBaseline
          ? SloteSupSubMetrics.subscriptCaretTranslateYPendingBodyBaseline(
              context,
              baseFontSize: baseFontSize,
            )
          : m.translateY;

  return EndOfParagraphCaretMetrics(
    height: painter.height + edgePaddingPx,
    dy: caretDy,
  );
}
