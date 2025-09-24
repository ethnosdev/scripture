import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';

import 'word.dart';

class PassageDemo extends StatefulWidget {
  const PassageDemo({super.key});

  @override
  State<PassageDemo> createState() => _PassageDemoState();
}

class _PassageDemoState extends State<PassageDemo> {
  final paragraph1 =
      'Now the earth was formless and void, '
      'and darkness was over the surface of the deep. And the Spirit of God '
      'was hovering over the surface of the waters.';
  final paragraph2 =
      'Thus the heavens and the earth were completed in all '
      'their vast array. And by the seventh day God had finished the work He '
      'had been doing; so on that day He rested from all His work.';

  List<Word> p1Words = [];
  List<Word> p2Words = [];

  @override
  void initState() {
    super.initState();
    var words = paragraph1.split(' ');

    int wordIndex = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      p1Words.add(Word(id: wordIndex.toString(), text: word));
      wordIndex++;
    }

    words = paragraph2.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      p2Words.add(Word(id: wordIndex.toString(), text: word));
      wordIndex++;
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(fontSize: 24, color: Colors.black);
    const verseNumberStyle = TextStyle(fontSize: 14, color: Colors.blueGrey);

    return Scaffold(
      appBar: AppBar(title: const Text('Passage Demo')),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.red)),
        child: PassageWidget(
          paragraphSpacing: 20,
          children: [
            ParagraphWidget(
              children: [
                VerseNumberWidget(
                  number: '2',
                  style: verseNumberStyle,
                  baseStyle: baseStyle,
                  padding: const EdgeInsets.only(right: 2.0),
                  onTap: (number) {
                    _showMessage(context, 'Tapped verse $number');
                  },
                ),
                for (final word in p1Words)
                  WordWidget(
                    text: word.text,
                    id: word.id,
                    style: const TextStyle(fontSize: 24, color: Colors.black),
                    onTap: (text, id) {
                      _showMessage(context, 'Tap: "$text", id: $id');
                    },
                    onLongPress: (text, id) {
                      _showMessage(context, 'Long press: "$text", id: $id');
                    },
                  ),
              ],
            ),
            ParagraphWidget(
              children: [
                VerseNumberWidget(
                  number: '3',
                  style: verseNumberStyle,
                  baseStyle: baseStyle,
                  padding: const EdgeInsets.only(right: 2.0),
                  onTap: (number) {
                    _showMessage(context, 'Tapped verse $number');
                  },
                ),
                for (final word in p2Words)
                  WordWidget(
                    text: word.text,
                    id: word.id,
                    style: const TextStyle(fontSize: 24, color: Colors.black),
                    onTap: (text, id) {
                      _showMessage(context, 'Tap: "$text", id: $id');
                    },
                    onLongPress: (text, id) {
                      _showMessage(context, 'Long press: "$text", id: $id');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(milliseconds: 500)),
    );
  }
}
