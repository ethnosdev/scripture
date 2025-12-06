import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scripture Package Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BiblePage(),
    );
  }
}

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  // 1. The Controller manages selection state (start/end IDs)
  final ScriptureSelectionController _selectionController =
      ScriptureSelectionController();

  List<UsfmLine> _lines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the data (simulating a database fetch)
    _loadScriptureData();

    // Listen to selection changes to update the UI (e.g., show copy button)
    _selectionController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  Future<void> _loadScriptureData() async {
    // Simulate DB delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Convert raw data to UsfmLine objects
    final data = MockDatabase.getGenesisOne();

    if (mounted) {
      setState(() {
        _lines = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genesis 1'),
        actions: [
          if (_selectionController.hasSelection) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Selection',
              onPressed: _handleCopy,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear Selection',
              onPressed: () => _selectionController.clear(),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const SizedBox()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // 2. The Main Widget
                child: UsfmWidget(
                  verseLines: _lines,
                  selectionController: _selectionController,

                  // A. Styling: Define how tags (s1, p, q1) look
                  styleBuilder: (format) {
                    // You can create completely custom styles, or use the defaults
                    // provided by the package and override specific properties.
                    return UsfmParagraphStyle.usfmDefaults(
                      format: format,
                      baseStyle: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    );
                  },

                  // B. Handle Word Taps (e.g., Open Dictionary)
                  onWordTapped: (wordId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped word ID: $wordId'),
                        duration: const Duration(milliseconds: 500),
                      ),
                    );
                  },

                  // C. Handle Footnotes (e.g., Show Dialog)
                  onFootnoteTapped: (text) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Footnote'),
                        content: Text(text),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },

                  // D. Handle Selection Gestures (Drag/Long Press)
                  onSelectionRequested: (wordId) {
                    // Logic to select the verse containing this word
                    ScriptureLogic.highlightVerse(
                      _selectionController,
                      _lines,
                      wordId,
                    );
                  },
                ),
              ),
            ),
    );
  }

  void _handleCopy() {
    final text = _selectionController.getSelectedText();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied: "$text"')));
    _selectionController.clear();
  }
}

/// A Mock helper to represent your Database Layer.
class MockDatabase {
  static List<UsfmLine> getGenesisOne() {
    // In a real app, this comes from SQLite.
    // The format matches the ParagraphFormat enum in scripture_core.dart
    return [
      UsfmLine(
        bookChapterVerse: 1001000,
        text: "The Creation",
        format: ParagraphFormat.s1,
      ),
      UsfmLine(
        bookChapterVerse: 1001000,
        text: "John 1:1–5; Hebrews 11:1–3",
        format: ParagraphFormat.r,
      ),
      UsfmLine(
        bookChapterVerse: 1001001,
        text: "In the beginning God created the heavens and the earth.",
        format: ParagraphFormat.m,
      ),
      UsfmLine(bookChapterVerse: 1001001, text: "", format: ParagraphFormat.b),
      UsfmLine(
        bookChapterVerse: 1001002,
        text:
            "Now the earth was formless and void, and darkness was over the surface of the deep. And the Spirit of God was hovering over the surface of the waters.",
        format: ParagraphFormat.m,
      ),
      UsfmLine(
        bookChapterVerse: 1001002,
        text: "The First Day",
        format: ParagraphFormat.s2,
      ),
      // Note: This line contains USFM footnote tokens: \f ... \f*
      UsfmLine(
        bookChapterVerse: 1001003,
        text:
            "And God said, “Let there be light,” \\f + \\fr 1:3 \\ft Cited in 2 Corinthians 4:6\\f* and there was light.",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(
        bookChapterVerse: 1001004,
        text:
            "And God saw that the light was good, and He separated the light from the darkness.",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(
        bookChapterVerse: 1001005,
        text: "God called the light “day,” and the darkness He called “night.”",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(bookChapterVerse: 1001005, text: "", format: ParagraphFormat.b),
      UsfmLine(
        bookChapterVerse: 1001005,
        text:
            "And there was evening, and there was morning—the first day.\\f + \\fr 1:5 \\ft Literally day one\\f*",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(
        bookChapterVerse: 1001005,
        text: "The Second Day",
        format: ParagraphFormat.s2,
      ),
      UsfmLine(
        bookChapterVerse: 1001006,
        text:
            "And God said, “Let there be an expanse \\f + \\fr 1:6 \\ft Or a canopy or a firmament or a vault; also in verses 7, 8, 14, 15, 17, and 20\\f* between the waters, to separate the waters from the waters.”",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(
        bookChapterVerse: 1001007,
        text:
            "So God made the expanse and separated the waters beneath it from the waters above. And it was so.",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(
        bookChapterVerse: 1001008,
        text: "God called the expanse “sky.”",
        format: ParagraphFormat.pmo,
      ),
      UsfmLine(bookChapterVerse: 1001008, text: "", format: ParagraphFormat.b),
      UsfmLine(
        bookChapterVerse: 1001008,
        text: "And there was evening, and there was morning—the second day.",
        format: ParagraphFormat.pmo,
      ),
    ];
  }
}
