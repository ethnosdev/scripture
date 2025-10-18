import 'package:flutter/widgets.dart';

import 'models.dart';
import 'paragraph.dart';
import 'passage.dart';
import 'verse_number.dart';
import 'word.dart';

PassageWidget buildPassageWidget(List<UsfmParagraph> paragraphs) {
  const baseStyle = TextStyle(fontSize: 16, color: Color(0xFF000000));

  final passageChildren = <ParagraphWidget>[];
  for (final paragraph in paragraphs) {
    final paragraphChildren = <Widget>[];
    for (final element in paragraph.content) {
      if (element is Word) {
        final word = WordWidget(
          text: element.text,
          id: element.id,
          style: baseStyle,
          onTap: (text, id) {
            print('Tapped word: "$text" (id: $id)');
          },
        );
        paragraphChildren.add(word);
      } else if (element is VerseNumber) {
        final verse = VerseNumberWidget(
          number: element.number,
          style: baseStyle,
          scale: 0.7,
          padding: const EdgeInsets.only(right: 4.0),
        );
        paragraphChildren.add(verse);
      } else if (element is Footnote) {
        print('Footnote: ${element.text}');
      } else {
        // do nothing for now.
      }
    }
    final paragraphWidget = ParagraphWidget(children: paragraphChildren);
    passageChildren.add(paragraphWidget);
  }

  return PassageWidget(children: passageChildren);
}
