import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('UsfmParser Footnote Extraction', () {
    test('Strips standard USFM tags and asterisk cleanly', () {
      final line = UsfmLine(
        bookChapterVerse: 1001003,
        text:
            r'Let there be light,\f + \fr 1:3 \ft Cited in \ref 2 Corinthians 4:6\ref*\f*',
        format: ParagraphFormat.p,
      );

      final elements = UsfmParser.getWords(line, 0);

      // Find the footnote element
      final footnote = elements.whereType<Footnote>().first;

      // Ensure the '\ref*' asterisk was removed and standard text remains
      expect(footnote.text, equals('Cited in 2 Corinthians 4:6'));
    });

    test('Strips machine-readable pipe references (BibleHub fix)', () {
      final line = UsfmLine(
        bookChapterVerse: 1001003,
        text:
            r'Let there be light,\f + \fr 1:3 \ft Cited in \ref 2 Corinthians 4:6|2CO 4:6\ref*\f*',
        format: ParagraphFormat.p,
      );

      final elements = UsfmParser.getWords(line, 0);

      // Find the footnote element
      final footnote = elements.whereType<Footnote>().first;

      // Ensure BOTH the '|2CO 4:6' and the '\ref*' were removed entirely
      expect(footnote.text, equals('Cited in 2 Corinthians 4:6'));
    });

    test('Leaves normal asterisks alone if not part of a tag', () {
      final line = UsfmLine(
        bookChapterVerse: 1001003,
        text: r'Test footnote\f + \ft See note * below\f*',
        format: ParagraphFormat.p,
      );

      final elements = UsfmParser.getWords(line, 0);
      final footnote = elements.whereType<Footnote>().first;

      // Ensure an asterisk used as normal text isn't accidentally destroyed
      expect(footnote.text, equals('See note * below'));
    });
  });
}
