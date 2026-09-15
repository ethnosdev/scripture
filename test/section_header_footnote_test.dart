import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('Section Header Footnote Interactivity', () {
    testWidgets(
      'Tapping the word before a footnote marker in a section header triggers onFootnoteTapped',
      (tester) async {
        String? tappedFootnote;
        final lines = [
          UsfmLine(
            bookChapterVerse: 1001000,
            text: 'The Creation',
            format: ParagraphFormat.s1,
          ),
          UsfmLine(
            bookChapterVerse: 1001000,
            text: 'John 1:1–5; Hebrews 11:1–3',
            format: ParagraphFormat.r,
          ),
          UsfmLine(
            bookChapterVerse: 1001001,
            text: 'In the beginning God created the heavens and the earth.',
            format: ParagraphFormat.p,
          ),
        ];
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                onFootnoteTapped: (text) => tappedFootnote = text,
                styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        // Find the word 'Creation' in the section header
        final creationFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == 'Creation',
        );
        expect(creationFinder, findsOneWidget);

        // Tapping 'Creation' should trigger the cross reference footnote callback
        await tester.tap(creationFinder);
        expect(tappedFootnote, equals('John 1:1–5; Hebrews 11:1–3'));

        // Tapping the footnote marker '*' itself also works
        tappedFootnote = null;
        final markerFinder = find.byType(FootnoteWidget);
        expect(markerFinder, findsOneWidget);
        await tester.tap(markerFinder);
        expect(tappedFootnote, equals('John 1:1–5; Hebrews 11:1–3'));

        // Tapping 'The' (which has no footnote) does not trigger footnote
        tappedFootnote = null;
        final theFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == 'The',
        );
        expect(theFinder, findsOneWidget);
        await tester.tap(theFinder);
        expect(tappedFootnote, isNull);
      },
    );

    testWidgets(
      'Tapping the word before an inline footnote marker in a section header triggers onFootnoteTapped',
      (tester) async {
        String? tappedFootnote;
        final lines = [
          UsfmLine(
            bookChapterVerse: 1001000,
            text: r'The Beginning\f + \ft Footnote for heading\f*',
            format: ParagraphFormat.s1,
          ),
        ];
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                onFootnoteTapped: (text) => tappedFootnote = text,
                styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        final beginningFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == 'Beginning',
        );
        expect(beginningFinder, findsOneWidget);

        await tester.tap(beginningFinder);
        expect(tappedFootnote, equals('Footnote for heading'));
      },
    );

    testWidgets(
      'Tapping word before footnote with active selection clears selection without triggering callback',
      (tester) async {
        String? tappedFootnote;
        final lines = [
          UsfmLine(
            bookChapterVerse: 1001000,
            text: 'The Creation',
            format: ParagraphFormat.s1,
          ),
          UsfmLine(
            bookChapterVerse: 1001000,
            text: 'John 1:1–5; Hebrews 11:1–3',
            format: ParagraphFormat.r,
          ),
          UsfmLine(
            bookChapterVerse: 1001001,
            text: 'In the beginning God created the heavens and the earth.',
            format: ParagraphFormat.p,
          ),
        ];
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                onFootnoteTapped: (text) => tappedFootnote = text,
                styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        // Select a range in verse 1
        controller.selectRange(1001001000, 1001001002);
        await tester.pump();
        expect(controller.hasSelection, isTrue);

        // Tap 'Creation'
        final creationFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == 'Creation',
        );
        await tester.tap(creationFinder);
        await tester.pump();

        // Selection should be cleared and footnote should NOT be opened
        expect(controller.hasSelection, isFalse);
        expect(tappedFootnote, isNull);
      },
    );
  });
}
