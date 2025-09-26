import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'paragraph.dart';

class PassageWidget extends MultiChildRenderObjectWidget {
  final double paragraphSpacing;

  const PassageWidget({
    super.key,
    required List<ParagraphWidget> children,
    this.paragraphSpacing = 8.0,
  }) : super(children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPassage(paragraphSpacing: paragraphSpacing);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderPassage renderObject,
  ) {
    renderObject.paragraphSpacing = paragraphSpacing;
  }
}

class RenderPassage extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, PassageParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, PassageParentData> {
  RenderPassage({double paragraphSpacing = 8.0})
    : _paragraphSpacing = paragraphSpacing;

  double _paragraphSpacing;
  double get paragraphSpacing => _paragraphSpacing;
  set paragraphSpacing(double value) {
    if (_paragraphSpacing == value) return;
    _paragraphSpacing = value;
    markNeedsLayout();
  }

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
      // Add spacing if there's another paragraph to follow
      if (child != null) {
        totalHeight += paragraphSpacing;
      }
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
    double maxContentWidth = 0.0;
    RenderBox? child = firstChild;

    while (child != null) {
      // Lay out each child (paragraph) with the incoming width constraint
      // but unconstrained height.
      child.layout(
        constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
        parentUsesSize: true,
      );

      final childParentData = child.parentData! as PassageParentData;

      // Position the child at the current vertical offset.
      childParentData.offset = Offset(0, currentY);

      // Update the max width seen so far.
      maxContentWidth = max(maxContentWidth, child.size.width);

      // Advance the vertical offset by the child's height.
      currentY += child.size.height;

      // Move to the next child and add spacing if it exists.
      final nextChild = childParentData.nextSibling;
      if (nextChild != null) {
        currentY += paragraphSpacing;
      }
      child = nextChild;
    }

    // The final size is the widest child's width and the total accumulated height.
    size = Size(maxContentWidth, currentY);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // defaultPaint is sufficient as it iterates through children and paints them
    // at their specified offsets.
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // defaultHitTestChildren works perfectly for this layout.
    return defaultHitTestChildren(result, position: position);
  }
}

class PassageParentData extends ContainerBoxParentData<RenderBox> {}
