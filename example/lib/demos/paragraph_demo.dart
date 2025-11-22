import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ParagraphDemo extends StatefulWidget {
  const ParagraphDemo({super.key});

  @override
  State<ParagraphDemo> createState() => _ParagraphDemoState();
}

class _ParagraphDemoState extends State<ParagraphDemo> {
  final textToDisplay =
      'Now the earth was formless and void, '
      'and darkness was over the surface of the deep. And the Spirit of God '
      'was hovering over the surface of the waters.';

  List<Word> wordList = [];

  @override
  void initState() {
    super.initState();
    final words = textToDisplay.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      wordList.add(Word(id: i, text: word));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paragraph Demo')),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.red)),
        child: ParagraphWidget(
          children: [
            for (final word in wordList)
              WordWidget(
                text: word.text,
                id: word.id,
                style: const TextStyle(fontSize: 24, color: Colors.black),
                // onTap: (text, id) {
                //   _showMessage(context, 'Tap: "$text", id: $id');
                // },
                // onLongPress: (text, id) {
                //   _showMessage(context, 'Long press: "$text", id: $id');
                // },
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
