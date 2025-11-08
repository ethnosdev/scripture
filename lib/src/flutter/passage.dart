import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PassageWidget extends MultiChildRenderObjectWidget {
  const PassageWidget({super.key, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPassage();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderPassage renderObject,
  ) {}
}

class RenderPassage extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, PassageParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, PassageParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! PassageParentData) {
      child.parentData = PassageParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double maxWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      maxWidth = max(maxWidth, child.getMinIntrinsicWidth(height));
      final childParentData = child.parentData! as PassageParentData;
      child = childParentData.nextSibling;
    }
    return maxWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double maxWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      maxWidth = max(maxWidth, child.getMaxIntrinsicWidth(height));
      final childParentData = child.parentData! as PassageParentData;
      child = childParentData.nextSibling;
    }
    return maxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double totalHeight = 0.0;
    RenderBox? child = firstChild;
    if (child == null) return 0.0;

    while (child != null) {
      totalHeight += child.getMinIntrinsicHeight(width);
      final childParentData = child.parentData! as PassageParentData;
      child = childParentData.nextSibling;
    }
    return totalHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    // For a vertical layout, min and max intrinsic height are the same.
    return computeMinIntrinsicHeight(width);
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    double currentY = 0.0;
    final double contentWidth = constraints.maxWidth;
    RenderBox? child = firstChild;

    while (child != null) {
      child.layout(
        BoxConstraints.tightFor(width: contentWidth),
        parentUsesSize: true,
      );
      final childParentData = child.parentData! as PassageParentData;
      childParentData.offset = Offset(0, currentY);
      currentY += child.size.height;
      final nextChild = childParentData.nextSibling;
      child = nextChild;
    }

    size = Size(contentWidth, currentY);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // defaultPaint is sufficient as it iterates through children and paints them
    // at their specified offsets.
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class PassageParentData extends ContainerBoxParentData<RenderBox> {}
