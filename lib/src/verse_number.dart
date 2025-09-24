import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef VerseNumberCallback = void Function(String number);

class VerseNumberWidget extends LeafRenderObjectWidget {
  final String number;
  final TextStyle style;
  final double scale;
  final EdgeInsets padding;
  final VerseNumberCallback? onTap;
  final VerseNumberCallback? onLongPress;

  const VerseNumberWidget({
    super.key,
    required this.number,
    required this.style,
    this.scale = 0.7,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderVerseNumber(
      number: number,
      style: style,
      scale: scale,
      padding: padding,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderVerseNumber renderObject,
  ) {
    renderObject
      ..number = number
      ..style = style
      ..scale = scale
      ..padding = padding
      ..onTap = onTap
      ..onLongPress = onLongPress;
  }
}

class RenderVerseNumber extends RenderBox {
  RenderVerseNumber({
    required String number,
    required TextStyle style,
    required double scale,
    required EdgeInsets padding,
    VerseNumberCallback? onTap,
    VerseNumberCallback? onLongPress,
  }) : _number = number,
       _style = style,
       _scale = scale,
       _padding = padding,
       _onTap = onTap,
       _onLongPress = onLongPress {
    _numberPainter = TextPainter(textDirection: TextDirection.ltr);
    _baseHeightPainter = TextPainter(textDirection: TextDirection.ltr);

    _updatePainters();

    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (_onTap != null) {
          _onTap!(_number);
        }
      };

    _longPressRecognizer = LongPressGestureRecognizer()
      ..onLongPress = () {
        if (_onLongPress != null) {
          _onLongPress!(_number);
        }
      };
  }

  late final TextPainter _numberPainter;
  late final TextPainter _baseHeightPainter;

  late final TapGestureRecognizer _tapRecognizer;
  late final LongPressGestureRecognizer _longPressRecognizer;

  String _number;
  String get number => _number;
  set number(String value) {
    if (_number == value) return;
    _number = value;
    _updatePainters();
    markNeedsLayout();
  }

  TextStyle _style;
  TextStyle get style => _style;
  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _updatePainters();
    markNeedsLayout();
  }

  double _scale;
  double get scale => _scale;
  set scale(double value) {
    if (_scale == value) return;
    _scale = value;
    _updatePainters();
    markNeedsLayout();
  }

  EdgeInsets _padding;
  EdgeInsets get padding => _padding;
  set padding(EdgeInsets value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  VerseNumberCallback? _onTap;
  VerseNumberCallback? get onTap => _onTap;
  set onTap(VerseNumberCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
    _tapRecognizer.onTap = () {
      if (value != null) {
        value(_number);
      }
    };
  }

  VerseNumberCallback? _onLongPress;
  VerseNumberCallback? get onLongPress => _onLongPress;
  set onLongPress(VerseNumberCallback? value) {
    if (_onLongPress == value) return;
    _onLongPress = value;
    _longPressRecognizer.onLongPress = () {
      if (value != null) {
        value(_number);
      }
    };
  }

  /// Creates the derived style for the verse number.
  TextStyle get _scaledStyle {
    final baseFontSize = _style.fontSize ?? 14.0; // Provide a fallback.
    return _style.copyWith(fontSize: baseFontSize * _scale);
  }

  /// Updates both painters whenever a relevant property changes.
  void _updatePainters() {
    _numberPainter.text = TextSpan(text: _number, style: _scaledStyle);
    _baseHeightPainter.text = TextSpan(text: 'A', style: _style);
  }

  @override
  void performLayout() {
    _numberPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);
    _baseHeightPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);

    final width = _padding.horizontal + _numberPainter.width;
    // The widget's height is determined by the un-scaled base style.
    final height = _baseHeightPainter.height;

    size = Size(width, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final numberOffset = offset + Offset(_padding.left, 0);
    _numberPainter.paint(context.canvas, numberOffset);
  }

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
    super.detach();
  }
}
