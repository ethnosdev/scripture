import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

typedef FootnoteTapCallback = void Function(String footnoteText);
typedef UsfmStyleBuilder = UsfmParagraphStyle Function(ParagraphFormat format);

class UsfmWidget extends StatefulWidget {
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
  State<UsfmWidget> createState() => _UsfmWidgetState();
}

class _UsfmWidgetState extends State<UsfmWidget> {
  late UsfmPassage _passage;
  final Map<int, String> _wordFootnoteMap = {};

  @override
  void initState() {
    super.initState();
    _prepareContent();
  }

  @override
  void didUpdateWidget(covariant UsfmWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-parse if the actual text lines have changed
    if (oldWidget.verseLines != widget.verseLines ||
        oldWidget.showHeadings != widget.showHeadings) {
      _prepareContent();
    }
  }

  void _prepareContent() {
    _passage = UsfmParser.parse(
      widget.verseLines,
      showHeadings: widget.showHeadings,
    );
    _wordFootnoteMap.clear();
    for (final paragraph in _passage.paragraphs) {
      final elements = paragraph.content;
      for (int i = 0; i < elements.length - 1; i++) {
        final current = elements[i];
        final next = elements[i + 1];
        // Look ahead for Footnotes
        if (current is Word && next is Footnote) {
          _wordFootnoteMap[current.id] = next.text;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableScripture(
      controller: widget.selectionController,
      onWordTapped: (int wordId) {
        if (_wordFootnoteMap.containsKey(wordId)) {
          widget.onFootnoteTapped?.call(_wordFootnoteMap[wordId]!);
        } else {
          widget.onWordTapped?.call(wordId);
        }
      },
      onSelectionRequested: widget.onSelectionRequested,
      child: PassageWidget(
        children: _buildParagraphWidgets(context, _passage.paragraphs),
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
      final pStyle = widget.styleBuilder(paragraph.format);

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
          selectionController: widget.selectionController,
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
            widget.footnoteMarkerStyle ??
            style.copyWith(color: Theme.of(context).colorScheme.primary);
        atom = TextAtomWidget(
          children: [
            WordWidget(text: current.text, id: current.id, style: style),
            FootnoteWidget(
              marker: '*',
              text: next.text,
              style: footnoteStyle,
              onTap: widget.onFootnoteTapped,
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
