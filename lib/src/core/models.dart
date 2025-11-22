import 'paragraph_format.dart';

class ParagraphElement {}

class Word extends ParagraphElement {
  final String text;
  final int id;
  Word({required this.text, required this.id});
}

class VerseNumber extends ParagraphElement {
  final String number;
  VerseNumber(this.number);
}

class Footnote extends ParagraphElement {
  final String text;
  Footnote(this.text);
}

class PassageElement {}

class UsfmParagraph extends PassageElement {
  final List<ParagraphElement> content;
  final ParagraphFormat format;
  UsfmParagraph({required this.content, required this.format});
}

// class Passage {
//   final List<PassageElement> paragraphs;
//   Passage(this.paragraphs);
// }

class UsfmPassage {
  final List<UsfmParagraph> paragraphs;
  UsfmPassage(this.paragraphs);

  bool _isAppending = false;

  void append(List<ParagraphElement> elements, ParagraphFormat format) {
    if (!_isAppending ||
        paragraphs.isEmpty ||
        paragraphs.last.format != format) {
      paragraphs.add(UsfmParagraph(content: elements, format: format));
    } else {
      paragraphs.last.content.addAll(elements);
    }
    _isAppending = true;
  }

  void commit([List<ParagraphElement>? elements, ParagraphFormat? format]) {
    assert(
      (elements != null && format != null) ||
          (elements == null && format == null),
    );
    _isAppending = false;
    if (elements != null && format != null) {
      append(elements, format);
    }
  }
}
