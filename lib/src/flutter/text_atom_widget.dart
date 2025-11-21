import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'word.dart';

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
  /// Returns the Word ID if the [localOffset] hits a RenderWord child.
  String? getWordAtOffset(Offset localOffset) {
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
        // If we hit a Footnote or VerseNumber, we return null immediately
        // so we don't accidentally select a word "under" it (unlikely in this layout)
        return null;
      }

      child = parentData.previousSibling;
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
