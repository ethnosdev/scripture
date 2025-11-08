import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TextAtomWidget extends MultiChildRenderObjectWidget {
  const TextAtomWidget({super.key, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTextAtom();
  }

  @override
  void updateRenderObject(BuildContext context, RenderTextAtom renderObject) {
    // No properties to update on RenderTextAtom itself
  }
}

class TextAtomParentData extends ContainerBoxParentData<RenderBox> {}

class RenderTextAtom extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextAtomParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextAtomParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextAtomParentData) {
      child.parentData = TextAtomParentData();
    }
  }

  @override
  void performLayout() {
    double currentX = 0.0;
    double maxLineHeight = 0.0;

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      (child.parentData as BoxParentData).offset = Offset(currentX, 0);
      currentX += child.size.width;
      maxLineHeight = max(maxLineHeight, child.size.height);
      child = childAfter(child);
    }

    size = Size(currentX, maxLineHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
