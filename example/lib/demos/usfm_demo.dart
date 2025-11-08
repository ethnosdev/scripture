import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scripture/scripture.dart';
import 'package:collection/collection.dart';
import 'package:scripture/scripture_core.dart';

class UsfmDemo extends StatefulWidget {
  const UsfmDemo({super.key});

  @override
  State<UsfmDemo> createState() => _UsfmDemoState();
}

class _UsfmDemoState extends State<UsfmDemo> {
  PassageWidget? _passage;
  bool _didLoadData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadData) {
      _didLoadData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // final themeTextStyle = Theme.of(context).textTheme.bodyMedium;
    // final usfm = await rootBundle.loadString('assets/01GENBSB.SFM');
    // final paragraphs = _parseUsfm(usfm);
    // if (mounted) {
    //   setState(() {
    //     _passage = buildPassageWidget(paragraphs, style: themeTextStyle!);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USFM Demo')),
      body: SingleChildScrollView(
        child: _passage ?? const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<UsfmParagraph> _parseUsfm(String usfm) {
    final lines = usfm.split('\n');
    final List<Map<String, dynamic>> rawParagraphs = [];
    Map<String, dynamic>? currentRawParagraph;
    int chapter = 0;

    // First pass: group lines into paragraphs
    for (final line in lines) {
      if (line.startsWith('\\c')) {
        chapter = int.tryParse(line.substring(3).trim()) ?? 0;
        if (chapter > 1) break;
        currentRawParagraph = null;
        continue;
      }
      if (chapter != 1) continue;

      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final parts = trimmedLine.split(' ');
      final marker = parts.first.replaceFirst('\\', '');
      final format = ParagraphFormat.values.firstWhereOrNull(
        (e) => e.name == marker,
      );

      if (format != null) {
        currentRawParagraph = {'format': format, 'content': ''};
        rawParagraphs.add(currentRawParagraph);
        currentRawParagraph['content'] = parts.sublist(1).join(' ');
      } else {
        if (currentRawParagraph != null) {
          currentRawParagraph['content'] += ' $trimmedLine';
        }
      }
    }

    // Second pass: parse content of each paragraph
    final List<UsfmParagraph> paragraphs = [];
    int verse = 0;
    int wordIndex = 0;

    for (final rawPara in rawParagraphs) {
      final para = UsfmParagraph(format: rawPara['format'], content: []);
      paragraphs.add(para);
      final content = rawPara['content'] as String;
      final wordsAndMarkers = content.split(RegExp(r'\s+'));

      for (int i = 0; i < wordsAndMarkers.length; i++) {
        final item = wordsAndMarkers[i];
        if (item == '\\v') {
          i++;
          if (i < wordsAndMarkers.length) {
            final verseNum = wordsAndMarkers[i];
            para.content.add(VerseNumber(verseNum));
            verse = int.tryParse(verseNum) ?? verse;
            wordIndex = 0;
          }
        } else if (item.startsWith('\\')) {
          // ignore other markers
        } else if (item.isNotEmpty) {
          final id = '$chapter:$verse:${wordIndex++}';
          para.content.add(Word(text: item, id: id));
        }
      }
    }
    return paragraphs;
  }
}
