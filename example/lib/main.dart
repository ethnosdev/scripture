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
  final ScriptureSelectionController _selectionController =
      ScriptureSelectionController();

  List<UsfmLine> _lines = [];
  bool _isRtl = false;

  @override
  void initState() {
    super.initState();
    _loadScriptureData();

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
    // Choose data based on language toggle
    final data = _isRtl
        ? MockDatabase.getArabicGenesisOne()
        : MockDatabase.getGenesisOne();

    if (mounted) {
      setState(() {
        _lines = data;
        _selectionController.clear();
      });
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isRtl = !_isRtl;
    });
    _loadScriptureData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRtl ? 'التكوين ١' : 'Genesis 1'),
        actions: [
          // Language Switcher Button
          TextButton.icon(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.language),
            label: Text(_isRtl ? "LTR" : "RTL"),
          ),

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
      // Directionality is crucial here.
      // It propagates the RTL setting down to the Paragraph and TextAtom render objects.
      body: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: UsfmWidget(
              verseLines: _lines,
              selectionController: _selectionController,
              styleBuilder: (format) {
                return UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    color: Colors.black87,
                    fontFamily: _isRtl ? 'Arial' : null,
                  ),
                );
              },
              onWordTapped: (wordId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped word ID: $wordId'),
                    duration: const Duration(milliseconds: 500),
                  ),
                );
              },
              onFootnoteTapped: (text) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_isRtl ? 'حاشية' : 'Footnote'),
                    content: Text(text),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_isRtl ? 'إغلاق' : 'Close'),
                      ),
                    ],
                  ),
                );
              },
              onSelectionRequested: (wordId) {
                ScriptureLogic.highlightVerse(
                  _selectionController,
                  _lines,
                  wordId,
                );
              },
            ),
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

class MockDatabase {
  // Original English Data
  static List<UsfmLine> getGenesisOne() {
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

  // Arabic Van Dyke Data (with varied styles)
  static List<UsfmLine> getArabicGenesisOne() {
    return [
      // Major Section Heading (s1)
      UsfmLine(
        bookChapterVerse: 1001000,
        text: "البدء",
        format: ParagraphFormat.s1,
      ),
      // Standard Paragraph (p) - Verse 1
      UsfmLine(
        bookChapterVerse: 1001001,
        text: "فِي ٱلْبَدْءِ خَلَقَ ٱللهُ ٱلسَّمَاوَاتِ وَٱلْأَرْضَ.",
        format: ParagraphFormat.p,
      ),
      // Standard Paragraph (p) - Verse 2
      UsfmLine(
        bookChapterVerse: 1001002,
        text:
            "وَكَانَتِ ٱلْأَرْضُ خَرِبَةً وَخَالِيَةً، وَعَلَى وَجْهِ ٱلْغَمْرِ ظُلْمَةٌ، وَرُوحُ ٱللهِ يَرِفُّ عَلَى وَجْهِ ٱلْمِيَاهِ.",
        format: ParagraphFormat.p,
      ),
      // Standard Paragraph (p) - Verse 3
      UsfmLine(
        bookChapterVerse: 1001003,
        text: "وَقَالَ ٱللهُ: «لِيَكُنْ نُورٌ»، فَكَانَ نُورٌ.",
        format: ParagraphFormat.p,
      ),
      // Verse 4
      UsfmLine(
        bookChapterVerse: 1001004,
        text:
            "وَرَأَى ٱللهُ ٱلنُّورَ أَنَّهُ حَسَنٌ. وَفَصَلَ ٱللهُ بَيْنَ ٱلنُّورِ وَٱلظُّلْمَةِ.",
        format: ParagraphFormat.p,
      ),
      // Verse 5
      UsfmLine(
        bookChapterVerse: 1001005,
        text:
            "وَدَعَا ٱللهُ ٱلنُّورَ نَهَارًا، وَٱلظُّلْمَةُ دَعَاهَا لَيْلًا. وَكَانَ مَسَاءٌ وَكَانَ صَبَاحٌ يَوْمًا وَاحِدًا.",
        format: ParagraphFormat.p,
      ),
    ];
  }
}
