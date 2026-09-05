import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef NoteTapCallback = void Function(String noteId);

/// Data describing an inline note marker to be rendered next to a word.
class NoteMarker {
  final String id;
  final int wordId;
  final String marker;

  const NoteMarker({
    required this.id,
    required this.wordId,
    this.marker = '✎',
  });
}

/// A render widget that displays an inline superscript marker for notes.
class NoteMarkerWidget extends LeafRenderObjectWidget {
  final String id;
  final String marker;
  final TextStyle style;
  final NoteTapCallback? onTap;

  const NoteMarkerWidget({
    super.key,
    required this.id,
    this.marker = '✎',
    this.style = const TextStyle(color: Color(0xFF2196F3), fontSize: 11),
    this.onTap,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderNoteMarker(
      id: id,
      marker: marker,
      style: style,
      onTap: onTap,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderNoteMarker renderObject) {
    renderObject
      ..id = id
      ..marker = marker
      ..style = style
      ..onTap = onTap;
  }
}

class RenderNoteMarker extends RenderBox {
  RenderNoteMarker({
    required String id,
    required String marker,
    required TextStyle style,
    NoteTapCallback? onTap,
  })  : _id = id,
        _marker = marker,
        _style = style,
        _onTap = onTap {
    _textPainter = TextPainter(
      text: TextSpan(text: _marker, style: _style),
      textDirection: TextDirection.ltr,
    );

    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (_onTap != null) {
          _onTap!(_id);
        }
      };
  }

  late final TextPainter _textPainter;
  late final TapGestureRecognizer _tapRecognizer;

  String _id;
  String get id => _id;
  set id(String value) {
    if (_id == value) return;
    _id = value;
  }

  String _marker;
  String get marker => _marker;
  set marker(String value) {
    if (_marker == value) return;
    _marker = value;
    _textPainter.text = TextSpan(text: _marker, style: _style);
    markNeedsLayout();
  }

  TextStyle _style;
  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _textPainter.text = TextSpan(text: _marker, style: _style);
    markNeedsLayout();
  }

  NoteTapCallback? _onTap;
  NoteTapCallback? get onTap => _onTap;
  set onTap(NoteTapCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
  }

  @override
  void performLayout() {
    _textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
    // Add 2px horizontal spacing to separate slightly from preceding word
    size = Size(_textPainter.size.width + 2.0, _textPainter.size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Superscript effect with 2px left offset
    _textPainter.paint(context.canvas, offset + const Offset(2.0, -4.0));
  }

  @override
  bool hitTestSelf(Offset position) {
    // Generously expand hit target to standard mobile touch target (at least 44x44 dp)
    final center = Offset(size.width / 2, size.height / 2);
    final touchTarget = Rect.fromCenter(
      center: center,
      width: size.width < 44.0 ? 44.0 : size.width,
      height: size.height < 44.0 ? 44.0 : size.height,
    );
    return touchTarget.contains(position);
  }

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
