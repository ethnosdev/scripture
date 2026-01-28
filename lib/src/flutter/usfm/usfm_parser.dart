import 'package:scripture/scripture_core.dart';

import 'usfm_line.dart';

/// Handles parsing USFM lines into a structured Passage model.
class UsfmParser {
  /// Tokenizes lines into a UsfmPassage.
  static UsfmPassage parse(
    List<UsfmLine> verseLines, {
    bool showHeadings = true,
  }) {
    UsfmPassage passage = UsfmPassage([]);
    int currentVerseNum = -1;
    int currentWordOffset = 0;

    for (final line in verseLines) {
      // Logic from your _buildPassage method
      switch (line.format) {
        case ParagraphFormat.b:
          passage.commit([], line.format);
        case ParagraphFormat.r:
          if (passage.paragraphs.isNotEmpty &&
              passage.paragraphs.last.content.isNotEmpty) {
            final footnote = Footnote(line.text);
            passage.paragraphs.last.content.add(footnote);
          }
        case ParagraphFormat.p:
        case ParagraphFormat.m:
        case ParagraphFormat.pmo:
          if (line.verse != currentVerseNum) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            currentVerseNum = line.verse;
            currentWordOffset = 0;
          }
          final words = getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.append(words, line.format);
        case ParagraphFormat.q1:
        case ParagraphFormat.q2:
        case ParagraphFormat.li1:
        case ParagraphFormat.li2:
        case ParagraphFormat.qr:
        case ParagraphFormat.pc:
          if (line.verse != currentVerseNum) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            currentVerseNum = line.verse;
            currentWordOffset = 0;
          }
          final words = getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.append(words, line.format);
          passage.commit();
        case ParagraphFormat.d:
          final words = getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.commit(words, line.format);
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
        case ParagraphFormat.ms:
        case ParagraphFormat.mr:
        case ParagraphFormat.qa:
          if (!showHeadings) {
            passage.commit();
            continue;
          }
          final words = getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.commit(words, line.format);
      }
    }
    passage.commit();
    return passage;
  }

  static List<ParagraphElement> getWords(UsfmLine line, int startOffset) {
    final text = line.text;
    final id = line.bookChapterVerse;
    final list = <ParagraphElement>[];
    int wordId = (id * 1000) + startOffset;

    final tokenizer = RegExp(r'(\\f.+?\\f\*)|(\s+)|([^\s\\]+)');
    final matches = tokenizer.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0)!;
      if (match.group(1) != null) {
        final cleanText = _extractUsfmFootnoteText(fullMatch);
        if (cleanText.isNotEmpty) list.add(Footnote(cleanText));
      } else if (match.group(3) != null) {
        list.add(Word(text: fullMatch, id: wordId));
        wordId++;
      }
    }
    return list;
  }

  static String _extractUsfmFootnoteText(String rawUsfm) {
    var content = rawUsfm.replaceAll(RegExp(r'^\\f\s*[+-]?\s*|\\f\*$'), '');
    content = content.replaceAll(RegExp(r'\\fr\s*[^\\\\]*'), '');
    content = content.replaceAll(RegExp(r'\\[a-z0-9]+\s*'), '');
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
