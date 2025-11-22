import 'package:scripture/scripture.dart'; // for ScriptureSelectionController
import 'package:scripture/scripture_core.dart';

import 'usfm_line.dart';
import 'usfm_parser.dart'; // for UsfmLine

/// Helper logic for manipulating selections based on content.
class ScriptureLogic {
  /// Calculates the range for a specific verse given a wordId within it,
  /// then applies it to the controller.
  static void highlightVerse(
    ScriptureSelectionController controller,
    List<UsfmLine> lines,
    String wordIdText,
  ) {
    final wordId = int.tryParse(wordIdText);
    if (wordId == null) return;

    final targetVerseRef = wordId ~/ 1000;
    String? startId;
    String? endId;

    // Logic extracted from your original _handleWordLongPress
    // Simplified slightly for readability, but identical logic.
    int currentVerseNum = -1;
    int currentWordOffset = 0;

    for (final line in lines) {
      if (line.format == ParagraphFormat.b ||
          line.format == ParagraphFormat.r) {
        continue;
      }

      bool isBiblicalText = line.format.isBiblicalText;

      if (isBiblicalText) {
        if (line.verse != currentVerseNum) {
          currentVerseNum = line.verse;
          currentWordOffset = 0;
        }
      }

      // Check for match
      if (line.bookChapterVerse == targetVerseRef) {
        // We rely on UsfmParser's counting logic implicitly here,
        // or we can reuse the parser's counting method to be safe.
        // For performance, we do a lightweight count here:
        final words = _countWordsInLine(line, currentWordOffset);
        for (final w in words) {
          startId ??= w.id;
          endId = w.id;
        }
      }

      // Increment offset
      final wordCount = _countWordsInLine(line, 0).length;
      currentWordOffset += wordCount;
    }

    if (startId != null && endId != null) {
      controller.selectRange(startId!, endId!);
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
