import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'selection_controller.dart';

typedef WordWidgetCallback = void Function(String text, String id);

class WordWidget extends LeafRenderObjectWidget {
  final String text;
  final String id;
  final TextStyle style;
  final WordWidgetCallback? onTap;
  final WordWidgetCallback? onLongPress;
  final ScriptureSelectionController? selectionController;

  const WordWidget({
    super.key,
    required this.text,
    required this.id,
    this.style = const TextStyle(color: Color(0xFF000000), fontSize: 14),
    this.onTap,
    this.onLongPress,
    this.selectionController,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWord(
      text: text,
      id: id,
      style: style,
      onTap: onTap,
      onLongPress: onLongPress,
      selectionController: selectionController,
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
      ..onTap = onTap
      ..onLongPress = onLongPress
      ..selectionController = selectionController;
  }
}

class RenderWord extends RenderBox {
  RenderWord({
    required String text,
    required String id,
    required TextStyle style,
    WordWidgetCallback? onTap,
    WordWidgetCallback? onLongPress,
    ScriptureSelectionController? selectionController,
  }) : _text = text,
       _id = id,
       _style = style,
       _onTap = onTap,
       _onLongPress = onLongPress,
       _selectionController = selectionController {
    _textPainter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: TextDirection.ltr,
    );

    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (_onTap != null) {
          _onTap!(_text, _id);
        }
      };

    _longPressRecognizer = LongPressGestureRecognizer()
      ..onLongPress = () {
        if (_onLongPress != null) {
          _onLongPress!(_text, _id);
        }
      };
  }

  late final TextPainter _textPainter;

  late final TapGestureRecognizer _tapRecognizer;
  late final LongPressGestureRecognizer _longPressRecognizer;

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

  WordWidgetCallback? _onTap;
  WordWidgetCallback? get onTap => _onTap;
  set onTap(WordWidgetCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
    _tapRecognizer.onTap = () {
      if (value != null) {
        value(_text, _id);
      }
    };
  }

  WordWidgetCallback? _onLongPress;
  WordWidgetCallback? get onLongPress => _onLongPress;
  set onLongPress(WordWidgetCallback? value) {
    if (_onLongPress == value) return;
    _onLongPress = value;
    _longPressRecognizer.onLongPress = () {
      if (value != null) {
        value(_text, _id);
      }
    };
  }

  ScriptureSelectionController? _selectionController;
  ScriptureSelectionController? get selectionController => _selectionController;
  set selectionController(ScriptureSelectionController? value) {
    if (_selectionController == value) return;
    if (attached) _selectionController?.removeListener(markNeedsPaint);
    _selectionController = value;
    if (attached) _selectionController?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _selectionController?.addListener(markNeedsPaint);
  }

  // --- RenderBox Overrides ---

  @override
  void performLayout() {
    _textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
    size = _textPainter.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);
  }

  // --- Gesture Handling Overrides ---

  @override
  bool hitTestSelf(Offset position) {
    return size.contains(position);
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tapRecognizer.addPointer(event);
      _longPressRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _tapRecognizer.dispose();
    _longPressRecognizer.dispose();
    _selectionController?.removeListener(markNeedsPaint);
    super.detach();
  }
}
