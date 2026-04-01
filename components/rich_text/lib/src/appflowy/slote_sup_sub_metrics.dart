import 'package:flutter/widgets.dart';

/// Typography for Slote superscript / subscript spans.
///
/// Shifts are expressed in fractions of the **parent** run’s font size (after
/// [TextScaler]), matching word-processor-style emulation. See Flutter
/// [flutter/flutter#10906](https://github.com/flutter/flutter/issues/10906).
class SloteSupSubMetrics {
  const SloteSupSubMetrics({required this.fontScale, required this.translateY});

  /// Factor applied to [baseFontSize] for the script-sized run (before scaler).
  final double fontScale;

  /// Vertical layout shift (negative raises superscript, positive lowers subscript).
  ///
  /// Used with [WidgetSpan] + padding (link+script and per UTF-16 code unit plain script).
  final double translateY;

  /// Logical parent font size (from [TextStyle.fontSize] or fallback).
  static const double fallbackBaseFontSize = 14.0;

  static const double _supFontScale = 0.7;
  static const double _subFontScale = 0.7;

  /// Extra raise as a fraction of scaled parent em (bottom padding under the
  /// script with [PlaceholderAlignment.aboveBaseline]; scales with [TextScaler]).
  static const double superscriptRaiseEm = 0.6;

  /// Lower distance as a fraction of scaled parent em (~4px at 14pt).
  static const double subscriptLowerEm = 0.05;

  /// Extra drop (as a fraction of scaled parent em) added to the subscript
  /// caret when the glyph box is still on the **body** baseline — e.g. toggled
  /// subscript at paragraph end before the first sub character exists.
  ///
  /// [translateY] alone matches top padding **inside** the [WidgetSpan]; real
  /// subscript glyphs sit lower because [PlaceholderAlignment.belowBaseline]
  /// shifts the whole placeholder. This term approximates that drop for the
  /// caret (tuned so pending EOT [dy] matches [RenderParagraph] snap Y once
  /// subscript exists; ~0.9·em at typical mobile scale with 16px scaled body).
  static const double subscriptPendingCaretExtraEm = 0.9;

  /// Multiplier on [translateY] when nudging the **editing caret** inside
  /// superscript runs (general caret resolver + end-of-paragraph metrics).
  ///
  /// [WidgetSpan] with [PlaceholderAlignment.aboveBaseline] already moves the
  /// caret into the placeholder; applying the full layout [translateY] again
  /// tends to float the caret above the script glyphs.
  static const double superscriptCaretTranslateYFactor = 0.42;

  static SloteSupSubMetrics superscript(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final scaledEm = MediaQuery.textScalerOf(context).scale(baseFontSize);
    return SloteSupSubMetrics(
      fontScale: _supFontScale,
      translateY: -superscriptRaiseEm * scaledEm,
    );
  }

  static SloteSupSubMetrics subscript(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final scaledEm = MediaQuery.textScalerOf(context).scale(baseFontSize);
    return SloteSupSubMetrics(
      fontScale: _subFontScale,
      translateY: subscriptLowerEm * scaledEm,
    );
  }

  /// Caret [dy] when subscript is pending but the caret has not entered a
  /// subscript [WidgetSpan] yet (body-line caret coordinates).
  static double subscriptCaretTranslateYPendingBodyBaseline(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final m = subscript(context, baseFontSize: baseFontSize);
    final scaledEm = MediaQuery.textScalerOf(context).scale(baseFontSize);
    return m.translateY + subscriptPendingCaretExtraEm * scaledEm;
  }
}
