import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('Footnote Punctuation Handling', () {
    testWidgets(
      'UsfmWidget keeps footnote marker and trailing punctuation in same atom with no space',
      (tester) async {
        String? tappedFootnote;
        final lines = [
          UsfmLine(
            bookChapterVerse: 41012011,
            text:
                r'and it is marvelous in our eyes’\f + \fr 12:11 \ft Psalm 118:22–23\f*?”',
            format: ParagraphFormat.q2,
          ),
        ];
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                onFootnoteTapped: (text) => tappedFootnote = text,
                styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        // Find the TextAtomWidget that contains the FootnoteWidget
        final atomFinder = find.ancestor(
          of: find.byType(FootnoteWidget),
          matching: find.byType(TextAtomWidget),
        );
        expect(atomFinder, findsOneWidget);

        // Within this atom, verify children: WordWidget('eyes’'), FootnoteWidget('*'), WordWidget('?”')
        final textAtom = tester.widget<TextAtomWidget>(atomFinder);
        expect(textAtom.children.length, equals(3));
        expect((textAtom.children[0] as WordWidget).text, equals('eyes’'));
        expect((textAtom.children[1] as FootnoteWidget).marker, equals('*'));
        expect((textAtom.children[2] as WordWidget).text, equals('?”'));

        // Verify there is no SpaceWidget after the atom (since it ends the verse)
        final passageFinder = find.byType(PassageWidget);
        expect(passageFinder, findsOneWidget);

        // Tapping either the word 'eyes’' or punctuation '?”' triggers the footnote callback
        final eyesFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == 'eyes’',
        );
        await tester.tap(eyesFinder);
        expect(tappedFootnote, equals('Psalm 118:22–23'));

        tappedFootnote = null;
        final punctFinder = find.byWidgetPredicate(
          (w) => w is WordWidget && w.text == '?”',
        );
        await tester.tap(punctFinder);
        expect(tappedFootnote, equals('Psalm 118:22–23'));

        // Verify selection controller produces correct text without space before '?”'
        final words = UsfmParser.getWords(lines.first, 0).whereType<Word>().toList();
        controller.selectRange(words.first.id, words.last.id);
        expect(
          controller.getSelectedText(),
          equals('and it is marvelous in our eyes’?”'),
        );
      },
    );

    testWidgets(
      'UsfmWidget adds space after trailing punctuation if followed by another word',
      (tester) async {
        final lines = [
          UsfmLine(
            bookChapterVerse: 13006062,
            text:
                r'The Gershomites\f + \fr 6:62 \ft Gershonites\f*, according to their clans',
            format: ParagraphFormat.p,
          ),
        ];
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UsfmWidget(
                verseLines: lines,
                selectionController: controller,
                styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        // Atom contains Gershomites, *, and comma
        final atomFinder = find.ancestor(
          of: find.byType(FootnoteWidget),
          matching: find.byType(TextAtomWidget),
        );
        expect(atomFinder, findsOneWidget);
        final textAtom = tester.widget<TextAtomWidget>(atomFinder);
        expect(textAtom.children.length, equals(3));
        expect((textAtom.children[0] as WordWidget).text, equals('Gershomites'));
        expect((textAtom.children[1] as FootnoteWidget).marker, equals('*'));
        expect((textAtom.children[2] as WordWidget).text, equals(','));

        // Verify that SpaceWidgets exist between atoms
        expect(find.byType(SpaceWidget), findsWidgets);

        // Verify selection controller output for the line
        final words = UsfmParser.getWords(lines.first, 0).whereType<Word>().toList();
        controller.selectRange(words.first.id, words.last.id);
        expect(
          controller.getSelectedText(),
          equals('The Gershomites, according to their clans'),
        );
      },
    );
  });
}
