// import 'package:flutter/widgets.dart';

// import '../core/models.dart';
// import 'footnote.dart';
// import 'paragraph.dart';
// import 'passage.dart';
// import 'space_widget.dart';
// import 'text_atom_widget.dart';
// import 'verse_number.dart';
// import 'word.dart';

// PassageWidget buildPassageWidget(
//   List<UsfmParagraph> paragraphs, {
//   required TextStyle style,
// }) {
//   final passageChildren = <ParagraphWidget>[];
//   for (final paragraph in paragraphs) {
//     final paragraphChildren = <Widget>[];
//     final elements = paragraph.content;

//     for (int i = 0; i < elements.length; i++) {
//       final currentElement = elements[i];
//       final List<Widget> atomChildren = [];

//       // Grouping Logic
//       if (currentElement is VerseNumber &&
//           i + 1 < elements.length &&
//           elements[i + 1] is Word) {
//         // VerseNumber followed by Word
//         atomChildren.add(
//           VerseNumberWidget(
//             number: currentElement.number,
//             style: style,
//             scale: 0.7,
//             padding: const EdgeInsets.only(right: 4.0),
//           ),
//         );
//         final nextWord = elements[i + 1] as Word;
//         atomChildren.add(
//           WordWidget(
//             text: nextWord.text,
//             id: nextWord.id,
//             style: style,
//             onTap: (text, id) {
//               print('Tapped word: "$text" (id: $id)');
//             },
//           ),
//         );
//         i++; // Skip the next element as it's already processed
//       } else if (currentElement is Word &&
//           i + 1 < elements.length &&
//           elements[i + 1] is Footnote) {
//         // Word followed by Footnote
//         atomChildren.add(
//           WordWidget(
//             text: currentElement.text,
//             id: currentElement.id,
//             style: style,
//             onTap: (text, id) {
//               print('Tapped word: "$text" (id: $id)');
//             },
//           ),
//         );
//         final nextFootnote = elements[i + 1] as Footnote;
//         atomChildren.add(FootnoteWidget(text: nextFootnote.text, style: style));
//         i++; // Skip the next element as it's already processed
//       } else if (currentElement is Word) {
//         // Standalone Word
//         atomChildren.add(
//           WordWidget(
//             text: currentElement.text,
//             id: currentElement.id,
//             style: style,
//             onTap: (text, id) {
//               print('Tapped word: "$text" (id: $id)');
//             },
//           ),
//         );
//       } else if (currentElement is VerseNumber) {
//         // Standalone VerseNumber (should not happen often, but handle it)
//         atomChildren.add(
//           VerseNumberWidget(
//             number: currentElement.number,
//             style: style,
//             scale: 0.7,
//             padding: const EdgeInsets.only(right: 4.0),
//           ),
//         );
//       } else if (currentElement is Footnote) {
//         // Standalone Footnote (should not happen often, but handle it)
//         atomChildren.add(
//           FootnoteWidget(text: currentElement.text, style: style),
//         );
//       }
//       // Add other element types here if needed, wrapping them in TextAtomWidget

//       if (atomChildren.isNotEmpty) {
//         paragraphChildren.add(TextAtomWidget(children: atomChildren));

//         // Spacing Logic
//         if (i + 1 < elements.length) {
//           final nextElement = elements[i + 1];
//           // A space is needed if the next element is a Word or VerseNumber.
//           // A space is *not* needed if the next element is a Footnote.
//           if (nextElement is Word || nextElement is VerseNumber) {
//             paragraphChildren.add(const SpaceWidget(width: 4.0));
//           }
//         }
//       }
//     }
//     final paragraphWidget = ParagraphWidget(children: paragraphChildren);
//     passageChildren.add(paragraphWidget);
//   }

//   return PassageWidget(children: passageChildren);
// }
