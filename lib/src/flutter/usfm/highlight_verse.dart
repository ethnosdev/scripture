import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

/// Helper logic for manipulating selections based on content.
class ScriptureLogic {
  /// Calculates the range for a specific verse given a wordId within it,
  /// then applies it to the controller.
  static void highlightVerse(
    ScriptureSelectionController controller,
    List<UsfmLine> lines,
    int wordId,
  ) {
    if (wordId < 0) return;
    final targetVerseRef = wordId ~/ 1000;
    int? startId;
    int? endId;

    int currentVerseNum = -1;
    int currentWordOffset = 0;

    for (final line in lines) {
      if (!line.format.isBiblicalText ||
          line.format == ParagraphFormat.b) {
        continue;
      }

      if (line.verse != currentVerseNum) {
        currentVerseNum = line.verse;
        currentWordOffset = 0;
      }

      final words = _countWordsInLine(line, currentWordOffset);

      // Check for match
      if (line.bookChapterVerse == targetVerseRef) {
        for (final w in words) {
          if (w.id >= 0) {
            startId ??= w.id;
            endId = w.id;
          }
        }
      }

      // Increment offset
      currentWordOffset += words.length;
    }

    if (startId != null && endId != null) {
      controller.selectRange(startId, endId);
    }
  }

  static List<Word> _countWordsInLine(UsfmLine line, int startOffset) {
    // A lightweight version of _getWords that just counts/IDs words
    // This duplicates logic slightly but keeps dependencies clean
    // unless we expose _getWords publically from UsfmParser.
    // Ideally, make UsfmParser._getWords public static.
    // For now, let's assume UsfmParser._getWords is made public:
    return UsfmParser.getWords(line, startOffset).whereType<Word>().toList();
  }
}
