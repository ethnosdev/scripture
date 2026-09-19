import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('UsfmParser Words of Jesus (wj) Tokenization', () {
    test('Correctly sets isWordsOfJesus on words inside \\wj ... \\wj*', () {
      final line = UsfmLine(
        bookChapterVerse: 40003015,
        text:
            r'\wj “Let it be so now,”\wj* Jesus replied. \wj “It is fitting for us to fulfill all righteousness in this way.”\wj* Then John permitted Him.',
        format: ParagraphFormat.p,
      );

      final elements = UsfmParser.getWords(line, 0);
      final words = elements.whereType<Word>().toList();

      // Words inside first wj span
      expect(words[0].text, equals('“Let'));
      expect(words[0].isWordsOfJesus, isTrue);
      expect(words[1].text, equals('it'));
      expect(words[1].isWordsOfJesus, isTrue);
      expect(words[2].text, equals('be'));
      expect(words[2].isWordsOfJesus, isTrue);
      expect(words[3].text, equals('so'));
      expect(words[3].isWordsOfJesus, isTrue);
      expect(words[4].text, equals('now,”'));
      expect(words[4].isWordsOfJesus, isTrue);

      // Words between wj spans
      expect(words[5].text, equals('Jesus'));
      expect(words[5].isWordsOfJesus, isFalse);
      expect(words[6].text, equals('replied.'));
      expect(words[6].isWordsOfJesus, isFalse);

      // Words inside second wj span
      expect(words[7].text, equals('“It'));
      expect(words[7].isWordsOfJesus, isTrue);
      expect(words[18].text, equals('way.”'));
      expect(words[18].isWordsOfJesus, isTrue);

      // Words after second wj span
      expect(words[19].text, equals('Then'));
      expect(words[19].isWordsOfJesus, isFalse);
      expect(words[20].text, equals('John'));
      expect(words[20].isWordsOfJesus, isFalse);
      expect(words[21].text, equals('permitted'));
      expect(words[21].isWordsOfJesus, isFalse);
      expect(words[22].text, equals('Him.'));
      expect(words[22].isWordsOfJesus, isFalse);
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

    test('Footnotes inside wj span preserve isWordsOfJesus across footnote', () {
      final line = UsfmLine(
        bookChapterVerse: 44001004,
        text:
            r'He commanded them: \wj “Do not leave Jerusalem,\f + \fr 1:4 \ft Footnote text\f* but wait for the gift.”\wj*',
        format: ParagraphFormat.p,
      );

      final elements = UsfmParser.getWords(line, 0);
      final words = elements.whereType<Word>().toList();

      expect(words[0].text, equals('He'));
      expect(words[0].isWordsOfJesus, isFalse);
      expect(words[1].text, equals('commanded'));
      expect(words[1].isWordsOfJesus, isFalse);
      expect(words[2].text, equals('them:'));
      expect(words[2].isWordsOfJesus, isFalse);

      expect(words[3].text, equals('“Do'));
      expect(words[3].isWordsOfJesus, isTrue);
      expect(words[4].text, equals('not'));
      expect(words[4].isWordsOfJesus, isTrue);
      expect(words[5].text, equals('leave'));
      expect(words[5].isWordsOfJesus, isTrue);
      expect(words[6].text, equals('Jerusalem,'));
      expect(words[6].isWordsOfJesus, isTrue);

      // Footnote exists
      expect(elements.whereType<Footnote>().length, equals(1));

      // After footnote, words remain marked as Words of Jesus
      expect(words[7].text, equals('but'));
      expect(words[7].isWordsOfJesus, isTrue);
      expect(words[8].text, equals('wait'));
      expect(words[8].isWordsOfJesus, isTrue);
      expect(words[9].text, equals('for'));
      expect(words[9].isWordsOfJesus, isTrue);
      expect(words[10].text, equals('the'));
      expect(words[10].isWordsOfJesus, isTrue);
      expect(words[11].text, equals('gift.”'));
      expect(words[11].isWordsOfJesus, isTrue);
    });
  });

  group('UsfmWidget Words of Jesus Rendering', () {
    testWidgets('Renders wordsOfJesusStyle when provided and isWordsOfJesus is true', (tester) async {
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
