import 'package:flutter/widgets.dart';

class FootnoteWidget extends StatelessWidget {
  final String text;
  final TextStyle style;

  const FootnoteWidget({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.copyWith(
        fontStyle: FontStyle.italic,
        fontSize: style.fontSize! * 0.7,
      ),
    );
  }
}
