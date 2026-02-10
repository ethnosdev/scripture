import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  // Helper to build the widget under test
  Widget buildTestApp({
    required TextDirection direction,
    required List<UsfmLine> lines,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: UsfmWidget(
            verseLines: lines,
            selectionController: ScriptureSelectionController(),
            styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
              format: format,
              baseStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  group('Verse Number Padding Directionality', () {
    final testLines = [
      UsfmLine(
        bookChapterVerse: 1001001,
        text: "In the beginning",
        format: ParagraphFormat.p,
      ),
    ];

    testWidgets('LTR: Padding is on the RIGHT of the number', (tester) async {
      await tester.pumpWidget(
        buildTestApp(direction: TextDirection.ltr, lines: testLines),
      );

      // 1. Find the VerseNumberWidget
      final verseWidgetFinder = find.byType(VerseNumberWidget);
      expect(verseWidgetFinder, findsOneWidget);

      // 2. Get the widget instance
      final VerseNumberWidget widget = tester.widget(verseWidgetFinder);

      // 3. Verify Padding
      // In LTR, "end" padding resolves to "right"
      expect(
        widget.padding.right,
        equals(4.0),
        reason: "LTR should have right padding",
      );
      expect(
        widget.padding.left,
        equals(0.0),
        reason: "LTR should not have left padding",
      );
    });

    testWidgets('RTL: Padding is on the LEFT of the number', (tester) async {
      await tester.pumpWidget(
        buildTestApp(direction: TextDirection.rtl, lines: testLines),
      );

      // 1. Find the VerseNumberWidget
      final verseWidgetFinder = find.byType(VerseNumberWidget);
      expect(verseWidgetFinder, findsOneWidget);

      // 2. Get the widget instance
      final VerseNumberWidget widget = tester.widget(verseWidgetFinder);

      // 3. Verify Padding
      // In RTL, "end" padding resolves to "left"
      expect(
        widget.padding.left,
        equals(4.0),
        reason: "RTL should have left padding",
      );
      expect(
        widget.padding.right,
        equals(0.0),
        reason: "RTL should not have right padding",
      );
    });
  });
}
