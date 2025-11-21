import 'package:flutter/widgets.dart';

typedef WordWidgetCallback = void Function(String text, String id);

class WordWidget extends LeafRenderObjectWidget {
  final String text;
  final String id;
  final TextStyle style;

  const WordWidget({
    super.key,
    required this.text,
    required this.id,
    this.style = const TextStyle(color: Color(0xFF000000), fontSize: 14),
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWord(text: text, id: id, style: style);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderWord renderObject,
  ) {
    renderObject
      ..text = text
      ..id = id
      ..style = style;
  }
}

class RenderWord extends RenderBox {
  RenderWord({
    required String text,
    required String id,
    required TextStyle style,
  }) : _text = text,
       _id = id,
       _style = style {
    _textPainter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: TextDirection.ltr,
    );
  }

  late final TextPainter _textPainter;

  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    _textPainter.text = TextSpan(text: _text, style: _style);
    markNeedsLayout();
  }

  String _id;
  String get id => _id;
  set id(String value) {
    if (_id == value) return;
    _id = value;
  }

  TextStyle _style;
  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _textPainter.text = TextSpan(text: _text, style: _style);
    markNeedsLayout();
  }

  @override
  void performLayout() {
    _textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
    size = _textPainter.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);
  }
}
