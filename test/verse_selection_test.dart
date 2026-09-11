import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('UsfmParser word IDs and verse numbering', () {
    test('Psalm 23: descriptive title \\d and poetry \\q1 have distinct sequential IDs', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'The LORD Is My Shepherd',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'Ezekiel 34:11–24; John 10:1–21',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'A Psalm of David.',
          format: ParagraphFormat.d,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: r'The LORD is my shepherd;\f + \fr 23:1 \ft See \ref Revelation 7:17\ref*.\f*',
          format: ParagraphFormat.q1,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'I shall not want.',
          format: ParagraphFormat.q2,
        ),
        UsfmLine(
          bookChapterVerse: 19023002,
          text: 'He makes me lie down in green pastures;',
          format: ParagraphFormat.q1,
        ),
      ];

      final passage = UsfmParser.parse(lines, showHeadings: true);

      // Verify heading words have id == -1
      final s1Paragraph = passage.paragraphs.firstWhere(
        (p) => p.format == ParagraphFormat.s1,
      );
      final s1Words = s1Paragraph.content.whereType<Word>().toList();
      for (final w in s1Words) {
        expect(w.id, equals(-1));
      }

      // Title words: 4 words, IDs 19023001000..19023001003
      final dParagraph = passage.paragraphs.firstWhere(
        (p) => p.format == ParagraphFormat.d,
      );
      final dWords = dParagraph.content.whereType<Word>().toList();
      expect(dWords.map((w) => w.text).toList(), ['A', 'Psalm', 'of', 'David.']);
      expect(dWords.map((w) => w.id).toList(), [
        19023001000,
        19023001001,
        19023001002,
        19023001003,
      ]);

      // q1 paragraph has verse number 1, and its words start at offset 4 (no collision!)
      final q1Paragraph = passage.paragraphs.firstWhere(
        (p) => p.format == ParagraphFormat.q1,
      );
      final hasVerseNumber = q1Paragraph.content.any(
        (el) => el is VerseNumber && el.number == '1',
      );
      expect(hasVerseNumber, isTrue);

      final q1Words = q1Paragraph.content.whereType<Word>().toList();
      expect(q1Words.map((w) => w.text).toList(), ['The', 'LORD', 'is', 'my', 'shepherd;']);
      expect(q1Words.map((w) => w.id).toList(), [
        19023001004,
        19023001005,
        19023001006,
        19023001007,
        19023001008,
      ]);

      // q2 paragraph continues verse 1
      final q2Paragraph = passage.paragraphs.firstWhere(
        (p) => p.format == ParagraphFormat.q2,
      );
      final q2Words = q2Paragraph.content.whereType<Word>().toList();
      expect(q2Words.map((w) => w.text).toList(), ['I', 'shall', 'not', 'want.']);
      expect(q2Words.map((w) => w.id).toList(), [
        19023001009,
        19023001010,
        19023001011,
        19023001012,
      ]);

      // Verse 2 q1 paragraph has verse number 2, and starts at offset 0
      final v2Paragraph = passage.paragraphs.lastWhere(
        (p) => p.format == ParagraphFormat.q1,
      );
      final v2Words = v2Paragraph.content.whereType<Word>().toList();
      expect(v2Words.first.id, equals(19023002000));
    });

    test('Philippians 2:4: heading \\s1 words receive id -1 and do not affect verse offsets', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Each of you should look not only to your own interests, but also to the interests of others.',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'The Mind of Christ',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Isaiah 52:13–15',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 50002005,
          text: 'Let this mind be in you which was also in Christ Jesus:',
          format: ParagraphFormat.p,
        ),
      ];

      final passage = UsfmParser.parse(lines, showHeadings: true);

      // Verify heading words have id == -1
      final s1Paragraph = passage.paragraphs.firstWhere(
        (p) => p.format == ParagraphFormat.s1,
      );
      for (final w in s1Paragraph.content.whereType<Word>()) {
        expect(w.id, equals(-1));
      }

      // Verse 5 starts at offset 0
      final v5Paragraph = passage.paragraphs.lastWhere(
        (p) => p.format == ParagraphFormat.p,
      );
      final v5Words = v5Paragraph.content.whereType<Word>().toList();
      expect(v5Words.first.id, equals(50002005000));
    });
  });

  group('ScriptureLogic.highlightVerse', () {
    test('Psalm 23:1 highlights entire verse from title \\d to end of poetry \\q2', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'The LORD Is My Shepherd',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'Ezekiel 34:11–24; John 10:1–21',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'A Psalm of David.',
          format: ParagraphFormat.d,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: r'The LORD is my shepherd;\f + \fr 23:1 \ft See \ref Revelation 7:17\ref*.\f*',
          format: ParagraphFormat.q1,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'I shall not want.',
          format: ParagraphFormat.q2,
        ),
        UsfmLine(
          bookChapterVerse: 19023002,
          text: 'He makes me lie down in green pastures;',
          format: ParagraphFormat.q1,
        ),
      ];

      final controller = ScriptureSelectionController();

      // Long press on "The" (19023001004)
      ScriptureLogic.highlightVerse(controller, lines, 19023001004);

      expect(controller.hasSelection, isTrue);
      // Start ID is first word of \d ("A")
      expect(controller.startId, equals(19023001000));
      // End ID is last word of \q2 ("want.")
      expect(controller.endId, equals(19023001012));
    });

    test('Philippians 2:4: highlighting verse 4 bounds only verse 4 text, excluding \\s1', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Each of you should look not only to your own interests, but also to the interests of others.',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'The Mind of Christ',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Isaiah 52:13–15',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 50002005,
          text: 'Let this mind be in you which was also in Christ Jesus:',
          format: ParagraphFormat.p,
        ),
      ];

      final controller = ScriptureSelectionController();

      // Highlight verse 4
      ScriptureLogic.highlightVerse(controller, lines, 50002004000);

      expect(controller.hasSelection, isTrue);
      expect(controller.startId, equals(50002004000));
      // 18 words in verse 4 (offset 0..17)
      expect(controller.endId, equals(50002004017));
    });
  });

  group('Selection Handles in UsfmWidget', () {
    testWidgets('Psalm 23: start handle on title \\d and end handle on last word of \\q2', (tester) async {
      final lines = [
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'The LORD Is My Shepherd',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 19023000,
          text: 'Ezekiel 34:11–24; John 10:1–21',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'A Psalm of David.',
          format: ParagraphFormat.d,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'The LORD is my shepherd;',
          format: ParagraphFormat.q1,
        ),
        UsfmLine(
          bookChapterVerse: 19023001,
          text: 'I shall not want.',
          format: ParagraphFormat.q2,
        ),
      ];

      final controller = ScriptureSelectionController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                showHeadings: true,
                styleBuilder: (format) {
                  return UsfmParagraphStyle.usfmDefaults(
                    format: format,
                    baseStyle: const TextStyle(fontSize: 16),
                  );
                },
                onSelectionRequested: (wordId) {
                  ScriptureLogic.highlightVerse(controller, lines, wordId);
                },
              ),
            ),
          ),
        ),
      );

      // Request selection for verse 1
      ScriptureLogic.highlightVerse(controller, lines, 19023001004);
      await tester.pump();

      expect(controller.hasSelection, isTrue);
      expect(controller.startId, equals(19023001000));
      expect(controller.endId, equals(19023001012));

      final renderPassage = tester.renderObject(find.byType(PassageWidget)) as RenderPassage;

      final startGeom = renderPassage.getWordGeometry(controller.startId!);
      final endGeom = renderPassage.getWordGeometry(controller.endId!);

      // Both start and end geometries MUST be found!
      expect(startGeom, isNotNull);
      expect(endGeom, isNotNull);

      // Start handle is on "A" in the descriptive title (first line of verse 1)
      // End handle is on "want." in q2 (below start handle)
      expect(endGeom!.rect.top, greaterThan(startGeom!.rect.top));
    });

    testWidgets('Philippians 2:4: end handle is at end of verse 4, not on subsequent heading \\s1', (tester) async {
      final lines = [
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Each of you should look not only to your own interests, but also to the interests of others.',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'The Mind of Christ',
          format: ParagraphFormat.s1,
        ),
        UsfmLine(
          bookChapterVerse: 50002004,
          text: 'Isaiah 52:13–15',
          format: ParagraphFormat.r,
        ),
        UsfmLine(
          bookChapterVerse: 50002005,
          text: 'Let this mind be in you which was also in Christ Jesus:',
          format: ParagraphFormat.p,
        ),
      ];

      final controller = ScriptureSelectionController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                showHeadings: true,
                styleBuilder: (format) {
                  return UsfmParagraphStyle.usfmDefaults(
                    format: format,
                    baseStyle: const TextStyle(fontSize: 16),
                  );
                },
                onSelectionRequested: (wordId) {
                  ScriptureLogic.highlightVerse(controller, lines, wordId);
                },
              ),
            ),
          ),
        ),
      );

      // Highlight verse 4
      ScriptureLogic.highlightVerse(controller, lines, 50002004000);
      await tester.pump();

      expect(controller.hasSelection, isTrue);
      expect(controller.startId, equals(50002004000));
      expect(controller.endId, equals(50002004017));

      final renderPassage = tester.renderObject(find.byType(PassageWidget)) as RenderPassage;

      final startGeom = renderPassage.getWordGeometry(controller.startId!);
      final endGeom = renderPassage.getWordGeometry(controller.endId!);

      expect(startGeom, isNotNull);
      expect(endGeom, isNotNull);

      // Ensure geometry of heading words returns null (unselectable heading)
      expect(renderPassage.getWordGeometry(-1), isNull);
    });
  });
}
