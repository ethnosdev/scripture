import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef WordWidgetCallback = void Function(String text, String id);

class WordWidget extends LeafRenderObjectWidget {
  final String text;
  final int id;
  final TextStyle style;
  final VoidCallback? onTap;

  const WordWidget({
    super.key,
    required this.text,
    required this.id,
    this.style = const TextStyle(color: Color(0xFF000000), fontSize: 14),
    this.onTap,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWord(
      text: text,
      id: id,
      style: style,
      textDirection: Directionality.of(context),
      onTap: onTap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderWord renderObject,
  ) {
    renderObject
      ..text = text
      ..id = id
      ..style = style
      ..textDirection = Directionality.of(context)
      ..onTap = onTap;
  }
}

class RenderWord extends RenderBox {
  RenderWord({
    required String text,
    required int id,
    required TextStyle style,
    required TextDirection textDirection,
    VoidCallback? onTap,
  }) : _text = text,
       _id = id,
       _style = style,
       _textDirection = textDirection,
       _onTap = onTap {
    _textPainter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: _textDirection,
    );
    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _onTap?.call();
      };
  }

  late final TextPainter _textPainter;
  late final TapGestureRecognizer _tapRecognizer;

  VoidCallback? _onTap;
  VoidCallback? get onTap => _onTap;
  set onTap(VoidCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
  }

  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    _textPainter.text = TextSpan(text: _text, style: _style);
    markNeedsLayout();
  }

  int _id;
  int get id => _id;
  set id(int value) {
    if (_id == value) return;
    _id = value;
    markNeedsPaint();
  }

  TextStyle _style;
  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _textPainter.text = TextSpan(text: _text, style: _style);
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _textPainter.textDirection = value;
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

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent && _onTap != null) {
      _tapRecognizer.addPointer(event);
    }
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }
}
