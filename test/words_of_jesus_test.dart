import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('UsfmParser Words of Jesus (wj) Tokenization', () {
    test('Correctly identifies words inside \\wj ... \\wj*', () {
      final line = UsfmLine(
        bookChapterVerse: 40003015,
        text:
            r'\wj “Let it be so now,”\wj* Jesus replied. \wj “It is fitting for us to fulfill all righteousness in this way.”\wj* Then John permitted Him.',
        format: ParagraphFormat.p,
      );

      final wjIds = <int>{};
      final elements = UsfmParser.getWords(line, 0, wordsOfJesusIds: wjIds);
      final words = elements.whereType<Word>().toList();

      // Words inside first wj span
      expect(words[0].text, equals('“Let'));
      expect(wjIds.contains(words[0].id), isTrue);
      expect(words[1].text, equals('it'));
      expect(wjIds.contains(words[1].id), isTrue);
      expect(words[2].text, equals('be'));
      expect(wjIds.contains(words[2].id), isTrue);
      expect(words[3].text, equals('so'));
      expect(wjIds.contains(words[3].id), isTrue);
      expect(words[4].text, equals('now,”'));
      expect(wjIds.contains(words[4].id), isTrue);

      // Words between wj spans
      expect(words[5].text, equals('Jesus'));
      expect(wjIds.contains(words[5].id), isFalse);
      expect(words[6].text, equals('replied.'));
      expect(wjIds.contains(words[6].id), isFalse);

      // Words inside second wj span
      expect(words[7].text, equals('“It'));
      expect(wjIds.contains(words[7].id), isTrue);
      expect(words[18].text, equals('way.”'));
      expect(wjIds.contains(words[18].id), isTrue);

      // Words after second wj span
      expect(words[19].text, equals('Then'));
      expect(wjIds.contains(words[19].id), isFalse);
      expect(words[20].text, equals('John'));
      expect(wjIds.contains(words[20].id), isFalse);
      expect(words[21].text, equals('permitted'));
      expect(wjIds.contains(words[21].id), isFalse);
      expect(words[22].text, equals('Him.'));
      expect(wjIds.contains(words[22].id), isFalse);

      // Also verify via UsfmParser.parse
      final passage = UsfmParser.parse([line]);
      expect(passage.wordsOfJesusIds, equals(wjIds));
      expect(passage.paragraphs.first.wordsOfJesusIds, equals(wjIds));
    });

    test('Word IDs and word count are identical with or without wj tags', () {
      const rawText =
          r'\wj “Let it be so now,”\wj* Jesus replied. \wj “It is fitting for us to fulfill all righteousness in this way.”\wj* Then John permitted Him.';
      final strippedText = rawText
          .replaceAll(r'\wj*', '')
          .replaceAll(RegExp(r'\\wj\s*'), '');

      final lineWithWj = UsfmLine(
        bookChapterVerse: 40003015,
        text: rawText,
        format: ParagraphFormat.p,
      );
      final lineWithoutWj = UsfmLine(
        bookChapterVerse: 40003015,
        text: strippedText,
        format: ParagraphFormat.p,
      );

      final wordsWithWj =
          UsfmParser.getWords(lineWithWj, 0).whereType<Word>().toList();
      final wordsWithoutWj =
          UsfmParser.getWords(lineWithoutWj, 0).whereType<Word>().toList();

      expect(wordsWithWj.length, equals(wordsWithoutWj.length));
      for (int i = 0; i < wordsWithWj.length; i++) {
        expect(wordsWithWj[i].id, equals(wordsWithoutWj[i].id));
        expect(wordsWithWj[i].text, equals(wordsWithoutWj[i].text));
      }
    });

    test('Footnotes inside wj span preserve wordsOfJesus across footnote', () {
      final line = UsfmLine(
        bookChapterVerse: 44001004,
        text:
            r'He commanded them: \wj “Do not leave Jerusalem,\f + \fr 1:4 \ft Footnote text\f* but wait for the gift.”\wj*',
        format: ParagraphFormat.p,
      );

      final wjIds = <int>{};
      final elements = UsfmParser.getWords(line, 0, wordsOfJesusIds: wjIds);
      final words = elements.whereType<Word>().toList();

      expect(words[0].text, equals('He'));
      expect(wjIds.contains(words[0].id), isFalse);
      expect(words[1].text, equals('commanded'));
      expect(wjIds.contains(words[1].id), isFalse);
      expect(words[2].text, equals('them:'));
      expect(wjIds.contains(words[2].id), isFalse);

      expect(words[3].text, equals('“Do'));
      expect(wjIds.contains(words[3].id), isTrue);
      expect(words[4].text, equals('not'));
      expect(wjIds.contains(words[4].id), isTrue);
      expect(words[5].text, equals('leave'));
      expect(wjIds.contains(words[5].id), isTrue);
      expect(words[6].text, equals('Jerusalem,'));
      expect(wjIds.contains(words[6].id), isTrue);

      // Footnote exists
      expect(elements.whereType<Footnote>().length, equals(1));

      // After footnote, words remain marked as Words of Jesus
      expect(words[7].text, equals('but'));
      expect(wjIds.contains(words[7].id), isTrue);
      expect(words[8].text, equals('wait'));
      expect(wjIds.contains(words[8].id), isTrue);
      expect(words[9].text, equals('for'));
      expect(wjIds.contains(words[9].id), isTrue);
      expect(words[10].text, equals('the'));
      expect(wjIds.contains(words[10].id), isTrue);
      expect(words[11].text, equals('gift.”'));
      expect(wjIds.contains(words[11].id), isTrue);
    });
  });

  group('UsfmWidget Words of Jesus Rendering', () {
    testWidgets('Renders wordsOfJesusStyle when provided and word is in wordsOfJesusIds', (tester) async {
      const wjRed = Color(0xFFB71C1C);
      const normalBlack = Color(0xFF000000);

      final lines = [
        UsfmLine(
          bookChapterVerse: 40003015,
          text: r'Jesus said, \wj “Follow Me.”\wj*',
          format: ParagraphFormat.p,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsfmWidget(
              verseLines: lines,
              selectionController: ScriptureSelectionController(),
              styleBuilder: (format) {
                return UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(color: normalBlack, fontSize: 16),
                  wordsOfJesusStyle: const TextStyle(color: wjRed, fontSize: 16),
                );
              },
            ),
          ),
        ),
      );

      final wordWidgets = tester.widgetList<WordWidget>(find.byType(WordWidget)).toList();
      expect(wordWidgets.length, equals(4));

      // "Jesus" -> normalBlack
      expect(wordWidgets[0].text, equals('Jesus'));
      expect(wordWidgets[0].style.color, equals(normalBlack));

      // "said," -> normalBlack
      expect(wordWidgets[1].text, equals('said,'));
      expect(wordWidgets[1].style.color, equals(normalBlack));

      // "“Follow" -> wjRed
      expect(wordWidgets[2].text, equals('“Follow'));
      expect(wordWidgets[2].style.color, equals(wjRed));

      // "Me.”" -> wjRed
      expect(wordWidgets[3].text, equals('Me.”'));
      expect(wordWidgets[3].style.color, equals(wjRed));
    });

    testWidgets('Renders baseStyle for all words when wordsOfJesusStyle is null', (tester) async {
      const normalBlack = Color(0xFF000000);

      final lines = [
        UsfmLine(
          bookChapterVerse: 40003015,
          text: r'Jesus said, \wj “Follow Me.”\wj*',
          format: ParagraphFormat.p,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsfmWidget(
              verseLines: lines,
              selectionController: ScriptureSelectionController(),
              styleBuilder: (format) {
                return UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(color: normalBlack, fontSize: 16),
                  // wordsOfJesusStyle is null (default)
                );
              },
            ),
          ),
        ),
      );

      final wordWidgets = tester.widgetList<WordWidget>(find.byType(WordWidget)).toList();
      for (final w in wordWidgets) {
        expect(w.style.color, equals(normalBlack));
      }
    });
  });
}
