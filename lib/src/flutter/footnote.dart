import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// The callback provides the full footnote text.
typedef FootnoteCallback = void Function(String text);

class FootnoteWidget extends LeafRenderObjectWidget {
  final String marker; // The character to display (e.g., "*")
  final String text; // The full text for the callback
  final TextStyle style;
  final FootnoteCallback? onTap;

  const FootnoteWidget({
    super.key,
    required this.marker,
    required this.text,
    this.style = const TextStyle(color: Color(0xFF0000FF), fontSize: 12),
    this.onTap,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFootnote(
      marker: marker,
      text: text,
      style: style,
      onTap: onTap,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFootnote renderObject) {
    renderObject
      ..marker = marker
      ..text = text
      ..style = style
      ..onTap = onTap;
  }
}

class RenderFootnote extends RenderBox {
  RenderFootnote({
    required String marker,
    required String text,
    required TextStyle style,
    FootnoteCallback? onTap,
  }) : _marker = marker,
       _text = text,
       _style = style,
       _onTap = onTap {
    _textPainter = TextPainter(
      text: TextSpan(text: _marker, style: _style),
      textDirection: TextDirection.ltr,
    );

    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (_onTap != null) {
          _onTap!(_text); // Call back with the FULL text
        }
      };
  }

  late final TextPainter _textPainter;
  late final TapGestureRecognizer _tapRecognizer;

  String _marker;
  String get marker => _marker;
  set marker(String value) {
    if (_marker == value) return;
    _marker = value;
    _textPainter.text = TextSpan(text: _marker, style: _style);
    markNeedsLayout();
  }

  // The full text is stored but not rendered.
  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
  }

  TextStyle _style;
  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _textPainter.text = TextSpan(text: _marker, style: _style);
    markNeedsLayout();
  }

  FootnoteCallback? _onTap;
  FootnoteCallback? get onTap => _onTap;
  set onTap(FootnoteCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
    _tapRecognizer.onTap = () {
      if (value != null) {
        value(_text);
      }
    };
  }

  @override
  void performLayout() {
    _textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
    size = _textPainter.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Optional: Add a slight vertical offset for a superscript effect.
    _textPainter.paint(context.canvas, offset + const Offset(0, -4));
  }

  @override
  bool hitTestSelf(Offset position) => size.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tapRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _tapRecognizer.dispose();
    super.detach();
  }
}
