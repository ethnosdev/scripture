
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scripture/src/paragraph.dart';
import 'package:scripture/src/passage.dart';
import 'package:scripture/src/verse_number.dart';
import 'package:scripture/src/word.dart';
import 'package:collection/collection.dart';

import '../supplemental/paragraph_format.dart';

class UsfmDemo extends StatefulWidget {
  const UsfmDemo({super.key});

  @override
  State<UsfmDemo> createState() => _UsfmDemoState();
}

class _UsfmDemoState extends State<UsfmDemo> {
  PassageWidget? _passage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final usfm = await rootBundle.loadString('assets/01GENBSB.SFM');
    final paragraphs = _parseUsfm(usfm);
    setState(() {
      _passage = _buildPassage(paragraphs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USFM Demo'),
      ),
      body: SingleChildScrollView(
        child: _passage ?? const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<_UsfmParagraph> _parseUsfm(String usfm) {
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
      final format = ParagraphFormat.values.firstWhereOrNull((e) => e.name == marker);

      if (format != null) {
        currentRawParagraph = {'format': format, 'content': ''};
        rawParagraphs.add(currentRawParagraph);
        currentRawParagraph['content'] = parts.sublist(1).join(' ');
      } else {
        if (currentRawParagraph != null) {
          currentRawParagraph['content'] += ' ' + trimmedLine;
        }
      }
    }

    // Second pass: parse content of each paragraph
    final List<_UsfmParagraph> paragraphs = [];
    int verse = 0;
    int wordIndex = 0;

    for (final rawPara in rawParagraphs) {
      final para = _UsfmParagraph(rawPara['format'], []);
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
          para.content.add(Word(item, id));
        }
      }
    }
    return paragraphs;
  }

  PassageWidget _buildPassage(List<_UsfmParagraph> paragraphs) {
    const baseStyle = TextStyle(fontSize: 16, color: Colors.black);

    return PassageWidget(
      children: paragraphs.map((p) {
        final List<Widget> children = p.content.map((item) {
          if (item is Word) {
            return WordWidget(
              text: item.text,
              id: item.id,
              style: baseStyle,
              onTap: (text, id) {
                print('Tapped word: "$text" (id: $id)');
              },
            );
          } else if (item is VerseNumber) {
            return VerseNumberWidget(
              number: item.number,
              style: baseStyle,
              scale: 0.7,
              padding: const EdgeInsets.only(right: 4.0),
            );
          }
          return Container();
        }).toList();
        return ParagraphWidget(children: children);
      }).toList(),
    );
  }
}

class _UsfmParagraph {
  final ParagraphFormat format;
  final List<dynamic> content;

  _UsfmParagraph(this.format, this.content);
}

class Word {
  final String text;
  final String id;
  Word(this.text, this.id);
}

class VerseNumber {
  final String number;
  VerseNumber(this.number);
}
