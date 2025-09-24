import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ParagraphWidget extends MultiChildRenderObjectWidget {
  final TextDirection textDirection;
  final double wordSpacing;
  final double lineSpacing;

  const ParagraphWidget({
    super.key,
    required List<Widget> children,
    this.textDirection = TextDirection.ltr,
    this.wordSpacing = 4.0,
    this.lineSpacing = 4.0,
  }) : super(children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraph(
      textDirection: textDirection,
      wordSpacing: wordSpacing,
      lineSpacing: lineSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderParagraph renderObject,
  ) {
    renderObject
      ..textDirection = textDirection
      ..wordSpacing = wordSpacing
      ..lineSpacing = lineSpacing;
  }
}

class RenderParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ParagraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ParagraphParentData> {
  RenderParagraph({
    TextDirection textDirection = TextDirection.ltr,
    double wordSpacing = 4.0,
    double lineSpacing = 4.0,
  }) : _textDirection = textDirection,
       _wordSpacing = wordSpacing,
       _lineSpacing = lineSpacing;

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _wordSpacing;
  double get wordSpacing => _wordSpacing;
  set wordSpacing(double value) {
    if (_wordSpacing == value) return;
    _wordSpacing = value;
    markNeedsLayout();
  }

  double _lineSpacing;
  double get lineSpacing => _lineSpacing;
  set lineSpacing(double value) {
    if (_lineSpacing == value) return;
    _lineSpacing = value;
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
    // The min intrinsic width is the width of the widest word.
    double maxWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      maxWidth = max(maxWidth, child.getMinIntrinsicWidth(height));
      final ParagraphParentData childParentData =
          child.parentData! as ParagraphParentData;
      child = childParentData.nextSibling;
    }
    return maxWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // The max intrinsic width is the sum of all word widths plus spacing.
    double totalWidth = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      totalWidth += child.getMaxIntrinsicWidth(height);
      final ParagraphParentData childParentData =
          child.parentData! as ParagraphParentData;
      child = childParentData.nextSibling;
      if (child != null) {
        totalWidth += wordSpacing;
      }
    }
    return totalWidth;
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    double currentX = 0;
    double currentY = 0;
    double maxLineHeight = 0;
    double actualContentWidth = 0;
    double currentLineWidth = 0;

    RenderBox? child = firstChild;

    while (child != null) {
      child.layout(
        BoxConstraints(
          minWidth: 0,
          // When laying out words, we want them to take their intrinsic width,
          // but we still pass the maxWidth to allow them to break if they are too wide
          // (e.g., if a single word is wider than constraints.maxWidth).
          maxWidth: constraints.maxWidth,
          minHeight: 0,
          maxHeight: constraints.maxHeight,
        ),
        parentUsesSize: true,
      );

      final double childWidth = child.size.width;
      final double childHeight = child.size.height;

      // Check if the word fits on the current line
      if (currentX + childWidth > constraints.maxWidth && currentX > 0) {
        // Doesn't fit, move to the next line
        actualContentWidth = max(actualContentWidth, currentLineWidth);
        currentX = 0;
        currentY += maxLineHeight + lineSpacing;
        maxLineHeight = 0;
        currentLineWidth = 0;
      }

      // Update max line height
      maxLineHeight = max(maxLineHeight, childHeight);

      // Set the position of the child
      final childParentData = child.parentData! as ParagraphParentData;
      childParentData.offset = Offset(currentX, currentY);

      // Advance currentX
      currentX += childWidth + wordSpacing;
      currentLineWidth += childWidth + wordSpacing;

      child = childParentData.nextSibling;
    }

    // After the loop, account for the last line's width
    actualContentWidth = max(
      actualContentWidth,
      currentLineWidth - wordSpacing,
    );

    // Final height of the paragraph
    size = constraints.constrain(
      Size(actualContentWidth, currentY + maxLineHeight),
    );

    // Now adjust for text direction if it's RTL
    if (_textDirection == TextDirection.rtl) {
      // This is a simplified RTL adjustment. For a more robust solution
      // with mixed LTR/RTL lines, you might need to determine line breaks first
      // and then reverse the order of words within each line.
      // For this example, we'll reverse the X offset for each word.
      RenderBox? rtlChild = firstChild;
      while (rtlChild != null) {
        final childParentData = rtlChild.parentData! as ParagraphParentData;
        childParentData.offset = Offset(
          actualContentWidth - childParentData.offset.dx - rtlChild.size.width,
          childParentData.offset.dy,
        );
        rtlChild = childParentData.nextSibling;
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

class ParagraphParentData extends ContainerBoxParentData<RenderBox> {}
