import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  testWidgets('UsfmWidget renders note marker and triggers callback', (tester) async {
    String? tappedNoteId;
    final lines = [
      UsfmLine(
        bookChapterVerse: 1001001,
        text: 'In the beginning God created the heavens and the earth.',
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
            highlights: const [
              HighlightRange(startId: 1001001000, endId: 1001001002, color: Colors.yellow),
            ],
            noteMarkers: const [
              NoteMarker(id: 'note-123', wordId: 1001001002),
            ],
            onNoteTapped: (id) => tappedNoteId = id,
            styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
              format: format,
              baseStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NoteMarkerWidget), findsOneWidget);
    await tester.tap(find.byType(NoteMarkerWidget));
    expect(tappedNoteId, 'note-123');
  });
}
