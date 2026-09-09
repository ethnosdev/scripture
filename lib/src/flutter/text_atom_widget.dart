import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'passage.dart';
import 'word.dart';

class TextAtomWidget extends MultiChildRenderObjectWidget {
  const TextAtomWidget({super.key, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTextAtom(textDirection: Directionality.of(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderTextAtom renderObject) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class TextAtomParentData extends ContainerBoxParentData<RenderBox> {}

class RenderTextAtom extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextAtomParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextAtomParentData> {
  RenderTextAtom({TextDirection textDirection = TextDirection.ltr})
    : _textDirection = textDirection;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Returns the Word ID if the [localOffset] hits a RenderWord child.
  int? getWordAtOffset(Offset localOffset) {
    // Iterate children in reverse (standard hit-test order)
    RenderBox? child = lastChild;
    while (child != null) {
      final parentData = child.parentData as TextAtomParentData;

      // Convert local offset to child's coordinate system
      final offsetInChild = localOffset - parentData.offset;

      // Check if the point is within the child's bounds
      final bool hit =
          offsetInChild.dx >= 0 &&
          offsetInChild.dx < child.size.width &&
          offsetInChild.dy >= 0 &&
          offsetInChild.dy < child.size.height;

      if (hit) {
        if (child is RenderWord) {
          return child.id;
        }
        return null;
      }

      child = parentData.previousSibling;
    }
    return null;
  }

  /// Returns the geometry (bounding box and text direction) of the word with [wordId]
  /// in text atom coordinates.
  WordGeometry? getWordGeometry(int wordId) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as TextAtomParentData;
      if (child is RenderWord && child.id == wordId) {
        return WordGeometry(
          rect: parentData.offset & child.size,
          direction: child.textDirection,
        );
      }
      child = parentData.nextSibling;
    }
    return null;
  }

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

    // 1. First pass: Layout children and position them logically (LTR)
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);

      final childParentData = child.parentData as TextAtomParentData;
      childParentData.offset = Offset(currentX, 0);

      currentX += child.size.width;
      maxLineHeight = max(maxLineHeight, child.size.height);
      child = childParentData.nextSibling;
    }

    size = Size(currentX, maxLineHeight);

    // 2. Second pass: If RTL, flip the x-coordinates relative to the total width.
    // This moves the first child (e.g. Verse Number) to the far Right.
    if (_textDirection == TextDirection.rtl) {
      child = firstChild;
      while (child != null) {
        final childParentData = child.parentData as TextAtomParentData;

        // NewX = ContainerWidth - OriginalX - ChildWidth
        final flippedX =
            size.width - childParentData.offset.dx - child.size.width;

        childParentData.offset = Offset(flippedX, 0);
        child = childParentData.nextSibling;
      }
    }
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
