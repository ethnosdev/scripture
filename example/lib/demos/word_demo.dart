import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';

class WordDemo extends StatelessWidget {
  const WordDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Demo')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          child: WordWidget(
            text: 'Hello',
            id: 1,
            style: const TextStyle(fontSize: 24, color: Colors.black),
            // onTap: (text, id) {
            //   _showMessage(context, 'Tap: "$text", id: $id');
            // },
            // onLongPress: (text, id) {
            //   _showMessage(context, 'Long press: "$text", id: $id');
            // },
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
