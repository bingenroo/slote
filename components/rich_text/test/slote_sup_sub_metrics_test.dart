import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_text/rich_text.dart';

void main() {
  testWidgets(
    'SloteSupSubMetrics superscript translateY scales linearly with base font size',
    (tester) async {
      late double dy14;
      late double dy24;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  dy14 = SloteSupSubMetrics.superscript(
                    context,
                    baseFontSize: 14,
                  ).translateY;
                  return const SizedBox.shrink();
                },
              ),
              Builder(
                builder: (context) {
                  dy24 = SloteSupSubMetrics.superscript(
                    context,
                    baseFontSize: 24,
                  ).translateY;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      expect(dy14, lessThan(0));
      expect(dy24, lessThan(dy14));
      expect(dy24 / dy14, closeTo(24 / 14, 1e-6));
    },
  );

  testWidgets(
    'SloteSupSubMetrics subscript translateY scales linearly with base font size',
    (tester) async {
      late double dy14;
      late double dy24;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  dy14 = SloteSupSubMetrics.subscript(
                    context,
                    baseFontSize: 14,
                  ).translateY;
                  return const SizedBox.shrink();
                },
              ),
              Builder(
                builder: (context) {
                  dy24 = SloteSupSubMetrics.subscript(
                    context,
                    baseFontSize: 24,
                  ).translateY;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      expect(dy14, greaterThan(0));
      expect(dy24, greaterThan(dy14));
      expect(dy24 / dy14, closeTo(24 / 14, 1e-6));
    },
  );

  testWidgets(
    'subscriptCaretTranslateYPendingBodyBaseline is larger than in-span translateY',
    (tester) async {
      late double pending;
      late double inSpan;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              inSpan = SloteSupSubMetrics.subscript(
                context,
                baseFontSize: 14,
              ).translateY;
              pending =
                  SloteSupSubMetrics.subscriptCaretTranslateYPendingBodyBaseline(
                context,
                baseFontSize: 14,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(pending, greaterThan(inSpan));
      expect(
        pending - inSpan,
        closeTo(14 * SloteSupSubMetrics.subscriptPendingCaretExtraEm, 1e-6),
      );
    },
  );

  testWidgets(
    'SloteSupSubMetrics applies MediaQuery textScaler to translate distance',
    (tester) async {
      late double dyDefault;
      late double dyScaled;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  dyDefault = SloteSupSubMetrics.superscript(
                    context,
                    baseFontSize: 10,
                  ).translateY;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.25),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                dyScaled = SloteSupSubMetrics.superscript(
                  context,
                  baseFontSize: 10,
                ).translateY;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(dyScaled / dyDefault, closeTo(1.25, 1e-6));
    },
  );
}
