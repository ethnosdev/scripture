import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

typedef FootnoteTapCallback = void Function(String footnoteText);
typedef UsfmStyleBuilder = UsfmParagraphStyle Function(ParagraphFormat format);

class UsfmWidget extends StatelessWidget {
  final List<UsfmLine> verseLines;
  final ScriptureSelectionController selectionController;
  final FootnoteTapCallback? onFootnoteTapped;
  final void Function(int wordId)? onWordTapped;
  final void Function(int wordId)? onSelectionRequested;
  final bool showHeadings;
  final UsfmStyleBuilder styleBuilder;
  final TextStyle? footnoteMarkerStyle;

  const UsfmWidget({
    super.key,
    required this.verseLines,
    required this.selectionController,
    required this.styleBuilder,
    this.onFootnoteTapped,
    this.footnoteMarkerStyle,
    this.onWordTapped,
    this.onSelectionRequested,
    this.showHeadings = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Parse Data
    final passage = UsfmParser.parse(verseLines, showHeadings: showHeadings);

    // 2. Build Widget Tree
    return SelectableScripture(
      controller: selectionController,
      onWordTapped: onWordTapped,
      onSelectionRequested: onSelectionRequested,
      child: PassageWidget(
        children: _buildParagraphWidgets(context, passage.paragraphs),
      ),
    );
  }

  List<Widget> _buildParagraphWidgets(
    BuildContext context,
    List<UsfmParagraph> paragraphs,
  ) {
    final children = <Widget>[];

    for (final paragraph in paragraphs) {
      // 1. Get the complete style/layout definition
      final pStyle = styleBuilder(paragraph.format);

      // 2. Build children using the style
      final pChildren = _getParagraphChildren(context, paragraph, pStyle);

      // 3. Handle spacing (b) or standard paragraph
      if (paragraph.format == ParagraphFormat.b) {
        _addSpacing(children);
        continue;
      }

      // add spacing before headers
      if (!paragraph.format.isBiblicalText) {
        _addSpacing(children);
      }

      // 4. Create Widget - No giant switch statement needed anymore!
      // The logic is encapsulated in pStyle
      children.add(
        ParagraphWidget(
          selectionController: selectionController,
          textAlign: pStyle.textAlign,
          firstLineIndent: pStyle.firstLineIndent,
          subsequentLinesIndent: pStyle.subsequentLinesIndent,
          selectable: pStyle.selectable,
          children: pChildren,
        ),
      );

      // Add spacing after headers or qr if needed
      if (!paragraph.format.isBiblicalText ||
          paragraph.format == ParagraphFormat.qr) {
        _addSpacing(children);
      }
    }
    return children;
  }

  void _addSpacing(List<Widget> children) {
    if (children.isEmpty || children.last is SizedBox) return;
    children.add(const SizedBox(height: 16.0));
  }

  List<Widget> _getParagraphChildren(
    BuildContext context,
    UsfmParagraph paragraph,
    UsfmParagraphStyle pStyle,
  ) {
    final widgets = <Widget>[];
    final elements = paragraph.content;

    // Use styles from the object
    final style = pStyle.textStyle;
    final verseStyle = pStyle.verseNumberStyle;

    for (int i = 0; i < elements.length; i++) {
      final current = elements[i];
      Widget? atom;

      // Atom Logic (Verse+Word or Word+Footnote)
      if (current is VerseNumber &&
          i + 1 < elements.length &&
          elements[i + 1] is Word) {
        final next = elements[i + 1] as Word;
        atom = TextAtomWidget(
          children: [
            VerseNumberWidget(
              number: current.number,
              style: verseStyle,
              padding: const EdgeInsets.only(right: 4.0),
            ),
            WordWidget(text: next.text, id: next.id, style: style),
          ],
        );
        i++;
      } else if (current is Word &&
          i + 1 < elements.length &&
          elements[i + 1] is Footnote) {
        final next = elements[i + 1] as Footnote;
        final footnoteStyle =
            footnoteMarkerStyle ??
            style.copyWith(color: Theme.of(context).colorScheme.primary);
        atom = TextAtomWidget(
          children: [
            WordWidget(text: current.text, id: current.id, style: style),
            FootnoteWidget(
              marker: '*',
              text: next.text,
              style: footnoteStyle,
              onTap: onFootnoteTapped,
            ),
          ],
        );
        i++;
      } else if (current is Word) {
        atom = TextAtomWidget(
          children: [
            WordWidget(text: current.text, id: current.id, style: style),
          ],
        );
      } else if (current is VerseNumber) {
        atom = TextAtomWidget(
          children: [
            VerseNumberWidget(number: current.number, style: verseStyle),
          ],
        );
      }

      if (atom != null) {
        widgets.add(atom);
        // Spacing logic
        if (i + 1 < elements.length) {
          final next = elements[i + 1];
          if (next is! Footnote) widgets.add(const SpaceWidget(width: 4.0));
        }
      }
    }
    return widgets;
  }
}
