## 0.9.0 - 2026-09-08

- Support selecting the note icon.

## 0.8.0 - 2026-09-08

- Add selection handles to selection.

## 0.7.0 - 2026-09-05

- Change `HighlightRange` startId and endId to `int` for performance and consistency with word IDs.
- Add `NoteMarker` model and `NoteMarkerWidget` with expanded 44x44 dp hit testing.
- Add `highlights` and `noteMarkers` support to `UsfmWidget`.
- Add `onNoteTapped` and `onAmbiguousTapped` callbacks to `UsfmWidget`.
- Fix highlight double-blending / darker overlapping seams between stacked poetic lines in `ParagraphWidget`.

## 0.6.0 - 2026-09-04

- Fix missing footnote issue.
- Don't add vertical space between consecutive same title headings.
- Leave \fqa inline tags for downstream apps (for italics within footnotes).
- Center \qa text by default.
- Add tests.

## 0.5.0 - 2026-09-03

- Strip footnote ref tags.

## 0.4.0 - 2026-02-10

- Add RTL directionality support.

## 0.3.0 - 2026-01-29

- Fix paragraph meaning. 
- Add support for ms1 and ms2 tags.
- Add support for pi1 tags.
- Add support for mi tags.
- Add support for sp tags.

## 0.2.0 - 2026-01-28

- Add support for \p paragraph marker.

## 0.1.1 - 2025-12-06

- Move HighlightRange out of scripture_core because it has a dart:ui dependency.

## 0.1.0 - 2025-12-06

- **Initial release.**
- Added core rendering engine using custom `RenderBox` implementations (`PassageWidget`, `ParagraphWidget`, `WordWidget`).
- Added `UsfmWidget` for automatic parsing and rendering of USFM Bible data.
- Added `ScriptureSelectionController` for handling ID-based text selection across complex widget trees.
- Added support for interactive footnotes and verse numbers.
- Added `scripture_core` library exposing data models (`UsfmLine`, `ParagraphFormat`) for Dart-only usage (e.g., database generation tools).
- Implemented word-level interaction (tap, long-press, and drag selection).
- Added customizable styling via `UsfmParagraphStyle`.