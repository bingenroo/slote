import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Optional caret height when the collapsed caret is at [Node.delta] end
/// ([Selection.startIndex] == [Delta.length]), to avoid Flutter using full-line
/// metrics (e.g. lines with inline widgets or mixed baselines).
///
/// Return a non-null height to replace [RenderParagraph.getFullHeightForCaret];
/// return null to keep default behavior.
typedef EndOfParagraphCaretHeightResolver = double? Function({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required TextStyleConfiguration textStyleConfiguration,
});

class EndOfParagraphCaretMetrics {
  const EndOfParagraphCaretMetrics({
    required this.height,
    this.dy = 0.0,
    this.ignorePreviousCaretYAnchor = false,
  });

  final double height;

  /// Additional vertical adjustment applied to the caret rect's top (y).
  /// Negative moves the caret up; positive moves it down.
  final double dy;

  /// When true, [AppFlowyRichText] applies [dy] even if the caret Y would
  /// normally be snapped to the last in-text glyph (boundary baseline fix).
  ///
  /// Use when [EditorState.toggledStyle] requests superscript/subscript that
  /// differs from the last run — snapping would keep the old script's Y.
  final bool ignorePreviousCaretYAnchor;
}

typedef EndOfParagraphCaretMetricsResolver = EndOfParagraphCaretMetrics? Function({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required TextStyleConfiguration textStyleConfiguration,
});

/// Optional caret metrics resolver for any caret position (not just paragraph end).
///
/// Return non-null to override [RenderParagraph.getFullHeightForCaret] and adjust
/// the caret rect's vertical placement by [EndOfParagraphCaretMetrics.dy].
typedef CaretMetricsResolver = EndOfParagraphCaretMetrics? Function({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  required Position position,
  required TextStyleConfiguration textStyleConfiguration,
});

/// The style of the editor.
///
/// You can customize the style of the editor by passing the [EditorStyle] to
///  the [AppFlowyEditor].
///
class EditorStyle {
  const EditorStyle({
    required this.padding,
    required this.cursorColor,
    required this.dragHandleColor,
    required this.selectionColor,
    required this.textStyleConfiguration,
    required this.textSpanDecorator,
    this.textSpanOverlayBuilder,
    this.magnifierSize = const Size(72, 48),
    this.mobileDragHandleBallSize = const Size(8, 8),
    this.mobileDragHandleWidth = 2.0,
    this.cursorWidth = 2.0,
    this.defaultTextDirection,
    this.enableHapticFeedbackOnAndroid = true,
    this.textScaleFactor = 1.0,
    this.maxWidth,
    this.mobileDragHandleTopExtend,
    this.mobileDragHandleWidthExtend,
    this.mobileDragHandleLeftExtend,
    this.mobileDragHandleHeightExtend,
    this.autoDismissCollapsedHandleDuration = const Duration(seconds: 3),
    this.caretMetrics,
    this.endOfParagraphCaretHeight,
    this.endOfParagraphCaretMetrics,
  });

  // The padding of the editor.
  final EdgeInsets padding;

  // The max width of the editor.
  final double? maxWidth;

  // The cursor color
  final Color cursorColor;

  // The cursor width
  final double cursorWidth;

  // The drag handle color
  // only works on mobile
  // the drag handle color will be ignored on Android.
  final Color dragHandleColor;

  // The selection color
  final Color selectionColor;

  // Customize the text style of the editor.
  //
  // All the text-based components will use this configuration to build their
  //   text style.
  //
  // Notes, this configuration is only for the common config of text style and
  //  it maybe override if the text block has its own [BlockComponentConfiguration].
  final TextStyleConfiguration textStyleConfiguration;

  // Customize the built-in or custom text span.
  //
  // For example, you can add a custom text span for the mention text
  //   or override the built-in text span.
  final TextSpanDecoratorForAttribute? textSpanDecorator;

  /// Customize the text span overlay builder.
  final AppFlowyTextSpanOverlayBuilder? textSpanOverlayBuilder;

  final String? defaultTextDirection;

  // The size of the magnifier.
  // Only works on mobile.
  final Size magnifierSize;

  // mobile drag handler size.
  // Only works on mobile.
  final Size mobileDragHandleBallSize;

  /// The extend of the mobile drag handle.
  ///
  /// By default, the hit test area of drag handle is the ball size.
  /// If you want to extend the hit test area, you can set this value.
  ///
  /// For example, if you set this value to 10, the hit test area of drag handle
  /// will be the ball size + 10 * 2.
  final double? mobileDragHandleTopExtend;
  final double? mobileDragHandleLeftExtend;
  final double? mobileDragHandleWidthExtend;
  final double? mobileDragHandleHeightExtend;

  /// The auto-dismiss time of the collapsed handle.
  ///
  /// The collapsed handle will be dismissed when no user interaction is detected.
  ///
  /// Only works on Android.
  final Duration autoDismissCollapsedHandleDuration;

  final double mobileDragHandleWidth;

  // only works on android
  // enable haptic feedback when updating selection by dragging the drag handler
  final bool enableHapticFeedbackOnAndroid;

  final double textScaleFactor;

  /// If set, [AppFlowyRichText] may use this to size/position the caret at any
  /// caret position (e.g. to avoid full-line metrics around inline widgets).
  final CaretMetricsResolver? caretMetrics;

  /// If set, [AppFlowyRichText] may use this to size the caret at paragraph end.
  final EndOfParagraphCaretHeightResolver? endOfParagraphCaretHeight;

  /// If set, [AppFlowyRichText] may use this to size/position the caret at
  /// paragraph end.
  final EndOfParagraphCaretMetricsResolver? endOfParagraphCaretMetrics;

  const EditorStyle.desktop({
    EdgeInsets? padding,
    Color? cursorColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    this.textSpanOverlayBuilder,
    this.defaultTextDirection,
    this.cursorWidth = 2.0,
    this.textScaleFactor = 1.0,
    this.maxWidth,
    this.caretMetrics,
    this.endOfParagraphCaretHeight,
    this.endOfParagraphCaretMetrics,
  })  : padding = padding ?? const EdgeInsets.symmetric(horizontal: 100),
        cursorColor = cursorColor ?? const Color(0xFF00BCF0),
        selectionColor =
            selectionColor ?? const Color.fromARGB(53, 111, 201, 231),
        textStyleConfiguration = textStyleConfiguration ??
            const TextStyleConfiguration(
              text: TextStyle(fontSize: 16, color: Colors.black),
            ),
        textSpanDecorator =
            textSpanDecorator ?? defaultTextSpanDecoratorForAttribute,
        magnifierSize = Size.zero,
        mobileDragHandleBallSize = Size.zero,
        mobileDragHandleWidth = 0.0,
        enableHapticFeedbackOnAndroid = false,
        dragHandleColor = Colors.transparent,
        mobileDragHandleTopExtend = null,
        mobileDragHandleWidthExtend = null,
        mobileDragHandleLeftExtend = null,
        mobileDragHandleHeightExtend = null,
        autoDismissCollapsedHandleDuration = const Duration(seconds: 0);

  const EditorStyle.mobile({
    EdgeInsets? padding,
    Color? cursorColor,
    Color? dragHandleColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    this.textSpanOverlayBuilder,
    this.defaultTextDirection,
    this.magnifierSize = const Size(72, 48),
    this.mobileDragHandleBallSize = const Size(8, 8),
    this.mobileDragHandleWidth = 2.0,
    this.cursorWidth = 2.0,
    this.enableHapticFeedbackOnAndroid = true,
    this.textScaleFactor = 1.0,
    this.maxWidth,
    this.mobileDragHandleTopExtend,
    this.mobileDragHandleWidthExtend,
    this.mobileDragHandleLeftExtend,
    this.mobileDragHandleHeightExtend,
    this.autoDismissCollapsedHandleDuration = const Duration(seconds: 3),
    this.caretMetrics,
    this.endOfParagraphCaretHeight,
    this.endOfParagraphCaretMetrics,
  })  : padding = padding ?? const EdgeInsets.symmetric(horizontal: 20),
        cursorColor = cursorColor ?? const Color(0xFF00BCF0),
        dragHandleColor = dragHandleColor ?? const Color(0xFF00BCF0),
        selectionColor =
            selectionColor ?? const Color.fromARGB(53, 111, 201, 231),
        textStyleConfiguration = textStyleConfiguration ??
            const TextStyleConfiguration(
              text: TextStyle(fontSize: 16, color: Colors.black),
            ),
        textSpanDecorator =
            textSpanDecorator ?? mobileTextSpanDecoratorForAttribute;

  EditorStyle copyWith({
    EdgeInsets? padding,
    Color? cursorColor,
    Color? dragHandleColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    AppFlowyTextSpanOverlayBuilder? textSpanOverlayBuilder,
    String? defaultTextDirection,
    Size? magnifierSize,
    Size? mobileDragHandleBallSize,
    double? mobileDragHandleWidth,
    bool? enableHapticFeedbackOnAndroid,
    double? cursorWidth,
    double? textScaleFactor,
    double? maxWidth,
    double? mobileDragHandleTopExtend,
    double? mobileDragHandleWidthExtend,
    double? mobileDragHandleLeftExtend,
    double? mobileDragHandleHeightExtend,
    Duration? autoDismissCollapsedHandleDuration,
    CaretMetricsResolver? caretMetrics,
    EndOfParagraphCaretHeightResolver? endOfParagraphCaretHeight,
    EndOfParagraphCaretMetricsResolver? endOfParagraphCaretMetrics,
  }) {
    return EditorStyle(
      padding: padding ?? this.padding,
      cursorColor: cursorColor ?? this.cursorColor,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      selectionColor: selectionColor ?? this.selectionColor,
      textStyleConfiguration:
          textStyleConfiguration ?? this.textStyleConfiguration,
      textSpanDecorator: textSpanDecorator ?? this.textSpanDecorator,
      textSpanOverlayBuilder:
          textSpanOverlayBuilder ?? this.textSpanOverlayBuilder,
      defaultTextDirection: defaultTextDirection,
      magnifierSize: magnifierSize ?? this.magnifierSize,
      mobileDragHandleBallSize:
          mobileDragHandleBallSize ?? this.mobileDragHandleBallSize,
      mobileDragHandleWidth:
          mobileDragHandleWidth ?? this.mobileDragHandleWidth,
      enableHapticFeedbackOnAndroid:
          enableHapticFeedbackOnAndroid ?? this.enableHapticFeedbackOnAndroid,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      maxWidth: maxWidth ?? this.maxWidth,
      mobileDragHandleTopExtend:
          mobileDragHandleTopExtend ?? this.mobileDragHandleTopExtend,
      mobileDragHandleWidthExtend:
          mobileDragHandleWidthExtend ?? this.mobileDragHandleWidthExtend,
      mobileDragHandleLeftExtend:
          mobileDragHandleLeftExtend ?? this.mobileDragHandleLeftExtend,
      mobileDragHandleHeightExtend:
          mobileDragHandleHeightExtend ?? this.mobileDragHandleHeightExtend,
      autoDismissCollapsedHandleDuration: autoDismissCollapsedHandleDuration ??
          this.autoDismissCollapsedHandleDuration,
      caretMetrics: caretMetrics ?? this.caretMetrics,
      endOfParagraphCaretHeight:
          endOfParagraphCaretHeight ?? this.endOfParagraphCaretHeight,
      endOfParagraphCaretMetrics:
          endOfParagraphCaretMetrics ?? this.endOfParagraphCaretMetrics,
    );
  }
}
