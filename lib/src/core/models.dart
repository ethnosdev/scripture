import 'paragraph_format.dart';

class ParagraphElement {}

class Word extends ParagraphElement {
  final String text;
  final String id;
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

class Passage {
  final List<PassageElement> paragraphs;
  Passage(this.paragraphs);
}
