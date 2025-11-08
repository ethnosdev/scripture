import 'package:flutter/widgets.dart';

class SpaceWidget extends LeafRenderObjectWidget {
  const SpaceWidget({super.key, required this.width});

  final double width;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSpace(width: width);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSpace renderObject) {
    renderObject.width = width;
  }
}

class RenderSpace extends RenderBox {
  RenderSpace({required double width}) : _width = width;

  double get width => _width;
  double _width;
  set width(double value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    size = Size(width, 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // A space is invisible.
  }
}
