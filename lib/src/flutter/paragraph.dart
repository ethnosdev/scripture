import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'space_widget.dart';

class ParagraphWidget extends MultiChildRenderObjectWidget {
  final double firstLineIndent;
  final double subsequentLinesIndent;
  final TextAlign textAlign;

  const ParagraphWidget({
    super.key,
    required super.children,
    this.firstLineIndent = 0.0,
    this.subsequentLinesIndent = 0.0,
    this.textAlign = TextAlign.start,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraph(
      firstLineIndent: firstLineIndent,
      subsequentLinesIndent: subsequentLinesIndent,
      textAlign: textAlign,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderParagraph renderObject,
  ) {
    renderObject
      ..firstLineIndent = firstLineIndent
      ..subsequentLinesIndent = subsequentLinesIndent
      ..textAlign = textAlign;
  }
}

class RenderParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ParagraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ParagraphParentData> {
  RenderParagraph({
    double firstLineIndent = 0.0,
    double subsequentLinesIndent = 0.0,
    TextAlign textAlign = TextAlign.start,
  }) : _firstLineIndent = firstLineIndent,
       _subsequentLinesIndent = subsequentLinesIndent,
       _textAlign = textAlign;

  double _firstLineIndent;
  double get firstLineIndent => _firstLineIndent;
  set firstLineIndent(double value) {
    if (_firstLineIndent == value) return;
    _firstLineIndent = value;
    markNeedsLayout();
  }

  double _subsequentLinesIndent;
  double get subsequentLinesIndent => _subsequentLinesIndent;
  set subsequentLinesIndent(double value) {
    if (_subsequentLinesIndent == value) return;
    _subsequentLinesIndent = value;
    markNeedsLayout();
  }

  TextAlign _textAlign;
  TextAlign get textAlign => _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ParagraphParentData) {
      child.parentData = ParagraphParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double maxWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      maxWidth = max(maxWidth, child.getMinIntrinsicWidth(height));
      final ParagraphParentData childParentData =
          child.parentData! as ParagraphParentData;
      child = childParentData.nextSibling;
    }
    return max(maxWidth, max(_firstLineIndent, _subsequentLinesIndent));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double totalWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      totalWidth += child.getMaxIntrinsicWidth(height);
      final ParagraphParentData childParentData =
          child.parentData! as ParagraphParentData;
      child = childParentData.nextSibling;
    }
    // The max width is based on a single line, so we only need the first line indent.
    return totalWidth + _firstLineIndent;
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final double paragraphWidth = constraints.maxWidth;
    double currentX = _firstLineIndent;
    double currentY = 0;
    double maxLineHeight = 0;

    final List<RenderBox> currentLineChildren = [];

    RenderBox? child = firstChild;

    while (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);

      final double childWidth = child.size.width;
      final double childHeight = child.size.height;
      final double currentLineIndent = (currentY == 0)
          ? _firstLineIndent
          : _subsequentLinesIndent;

      // Skip leading spaces at the beginning of a line.
      final bool isAtStartOfLine = currentX == currentLineIndent;
      final bool isChildASpace = child is RenderSpace;
      if (isChildASpace && isAtStartOfLine) {
        child = (child.parentData as ParagraphParentData).nextSibling;
        continue;
      }

      // Check if the current child overflows the line.
      if (currentX > currentLineIndent &&
          currentX + childWidth > paragraphWidth) {
        // 1. Align the completed line (shift children if Center/Right)
        _alignLine(
          currentLineChildren,
          currentLineIndent,
          currentX,
          paragraphWidth,
        );
        currentLineChildren.clear();

        // 2. Move to next line
        currentX = _subsequentLinesIndent;
        currentY += maxLineHeight;
        maxLineHeight = 0;

        // Re-check for leading space after wrapping. If so, skip it.
        if (isChildASpace) {
          child = (child.parentData as ParagraphParentData).nextSibling;
          continue;
        }
      }

      // Position the child (initially Left Aligned)
      final childParentData = child.parentData! as ParagraphParentData;
      childParentData.offset = Offset(currentX, currentY);

      // Add to buffer for later alignment
      currentLineChildren.add(child);

      // Update max line height for the current line.
      maxLineHeight = max(maxLineHeight, childHeight);

      // Advance the horizontal cursor.
      currentX += childWidth;

      child = childParentData.nextSibling;
    }

    // Align the final line
    final double lastLineIndent = (currentY == 0)
        ? _firstLineIndent
        : _subsequentLinesIndent;
    _alignLine(currentLineChildren, lastLineIndent, currentX, paragraphWidth);

    size = Size(paragraphWidth, currentY + maxLineHeight);
  }

  void _alignLine(
    List<RenderBox> lineChildren,
    double indent,
    double usedWidth,
    double maxWidth,
  ) {
    // only handling LTR text for now
    if (_textAlign == TextAlign.left ||
        _textAlign == TextAlign.start ||
        lineChildren.isEmpty) {
      return;
    }
    // Calculate empty space on the line.
    // usedWidth includes the indent and all words.
    // Example: Max 100. Indent 10. Words take 50. usedWidth = 60.
    // Free space = 100 - 60 = 40.
    final double freeSpace = maxWidth - usedWidth;

    double shift = 0;

    if (_textAlign == TextAlign.center) {
      shift = freeSpace / 2;
    } else if (_textAlign == TextAlign.right) {
      shift = freeSpace;
    }

    if (shift == 0) return;

    // Apply shift to all children on this line
    for (final child in lineChildren) {
      final parentData = child.parentData as ParagraphParentData;
      parentData.offset += Offset(shift, 0);
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

class ParagraphParentData extends ContainerBoxParentData<RenderBox> {}
