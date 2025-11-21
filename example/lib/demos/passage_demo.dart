import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Passage Demo')),
      body: Container(
        // padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(border: Border.all(color: Colors.red)),
        child: PassageWidget(
          // paragraphSpacing: 20,
          children: [
            // Example 1: Standard paragraph indent
            ParagraphWidget(
              firstLineIndent: 30.0,
              children: [
                VerseNumberWidget(
                  number: '2',
                  style: baseStyle.copyWith(color: Colors.blueGrey),
                  scale: 0.6,
                  padding: const EdgeInsets.only(right: 2.0),
                  onTap: (number) =>
                      _showMessage(context, 'Tapped verse $number'),
                ),
                for (final word in p1Words)
                  WordWidget(
                    text: word.text,
                    id: word.id,
                    style: baseStyle,
                    // onTap: (text, id) =>
                    //     _showMessage(context, 'Tap: "$text", id: $id'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Example 2: Hanging indent
            ParagraphWidget(
              subsequentLinesIndent: 40.0,
              children: [
                VerseNumberWidget(
                  number: '3',
                  style: baseStyle.copyWith(color: Colors.blueGrey),
                  scale: 0.6,
                  padding: const EdgeInsets.only(right: 2.0),
                  onTap: (number) =>
                      _showMessage(context, 'Tapped verse $number'),
                ),
                for (final word in p2Words)
                  WordWidget(
                    text: word.text,
                    id: word.id,
                    style: baseStyle,
                    // onTap: (text, id) =>
                    //     _showMessage(context, 'Tap: "$text", id: $id'),
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
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}
