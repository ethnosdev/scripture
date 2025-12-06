## 0.1.0

- **Initial release.**
- Added core rendering engine using custom `RenderBox` implementations (`PassageWidget`, `ParagraphWidget`, `WordWidget`).
- Added `UsfmWidget` for automatic parsing and rendering of USFM Bible data.
- Added `ScriptureSelectionController` for handling ID-based text selection across complex widget trees.
- Added support for interactive footnotes and verse numbers.
- Added `scripture_core` library exposing data models (`UsfmLine`, `ParagraphFormat`) for Dart-only usage (e.g., database generation tools).
- Implemented word-level interaction (tap, long-press, and drag selection).
- Added customizable styling via `UsfmParagraphStyle`.