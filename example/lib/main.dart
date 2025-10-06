import 'package:example/demos/paragraph_demo.dart';
import 'package:example/demos/passage_demo.dart';
import 'package:example/demos/usfm_demo.dart';
import 'package:example/demos/word_demo.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('scripture package demo')),
      body: ListView(
        children: [
          ListTile(
            title: Text('WordWidget'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WordDemo()),
              );
            },
          ),
          ListTile(
            title: Text('ParagraphWidget'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParagraphDemo()),
              );
            },
          ),
          ListTile(
            title: Text('PassageWidget'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PassageDemo()),
              );
            },
          ),
          ListTile(
            title: Text('USFM Demo'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsfmDemo()),
              );
            },
          ),
        ],
      ),
    );
  }
}
