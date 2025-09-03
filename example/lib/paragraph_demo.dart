import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';

class ParagraphDemo extends StatelessWidget {
  const ParagraphDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paragraph Detail')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          child: ParagraphWidget(
            words: [
              WordWidget(
                text: 'Hello',
                id: '1',
                style: const TextStyle(fontSize: 24, color: Colors.black),
                onTap: (text, id) {
                  _showMessage(context, 'Tap: "$text", id: $id');
                },
                onLongPress: (text, id) {
                  _showMessage(context, 'Long press: "$text", id: $id');
                },
              ),
              WordWidget(
                text: 'World',
                id: '2',
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
