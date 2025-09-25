import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ParagraphWidget extends MultiChildRenderObjectWidget {
  final TextDirection textDirection;
  final double wordSpacing;
  final double lineSpacing;
  final double firstLineIndent;
  final double subsequentLinesIndent;

  const ParagraphWidget({
    super.key,
    required super.children,
    this.textDirection = TextDirection.ltr,
    this.wordSpacing = 4.0,
    this.lineSpacing = 4.0,
    this.firstLineIndent = 0.0,
    this.subsequentLinesIndent = 0.0,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraph(
      textDirection: textDirection,
      wordSpacing: wordSpacing,
      lineSpacing: lineSpacing,
      firstLineIndent: firstLineIndent,
      subsequentLinesIndent: subsequentLinesIndent,
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
      ..lineSpacing = lineSpacing
      ..firstLineIndent = firstLineIndent
      ..subsequentLinesIndent = subsequentLinesIndent;
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
    double firstLineIndent = 0.0,
    double subsequentLinesIndent = 0.0,
  }) : _textDirection = textDirection,
       _wordSpacing = wordSpacing,
       _lineSpacing = lineSpacing,
       _firstLineIndent = firstLineIndent,
       _subsequentLinesIndent = subsequentLinesIndent;

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
      if (child != null) {
        totalWidth += wordSpacing;
      }
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

    double currentX = _firstLineIndent;
    double currentY = 0;
    double maxLineHeight = 0;
    double actualContentWidth = 0;

    RenderBox? child = firstChild;

    while (child != null) {
      child.layout(
        BoxConstraints(maxWidth: constraints.maxWidth),
        parentUsesSize: true,
      );

      final double childWidth = child.size.width;
      final double childHeight = child.size.height;
      final double currentLineIndent = (currentY == 0)
          ? _firstLineIndent
          : _subsequentLinesIndent;

      // Check if the word fits on the current line.
      // We don't wrap if it's the very first word on a line, even if it overflows.
      if (currentX > currentLineIndent &&
          currentX + childWidth > constraints.maxWidth) {
        // Doesn't fit, move to the next line
        actualContentWidth = max(
          actualContentWidth,
          currentX - wordSpacing,
        ); // Record width of completed line
        currentX = _subsequentLinesIndent;
        currentY += maxLineHeight + lineSpacing;
        maxLineHeight = 0;
      }

      // Update max line height
      maxLineHeight = max(maxLineHeight, childHeight);

      // Set the position of the child
      final childParentData = child.parentData! as ParagraphParentData;
      childParentData.offset = Offset(currentX, currentY);

      // Advance currentX
      currentX += childWidth + wordSpacing;

      child = childParentData.nextSibling;
    }

    // After the loop, account for the last line's width
    actualContentWidth = max(
      actualContentWidth,
      currentX - wordSpacing, // Subtract trailing space
    );

    // Final height of the paragraph
    size = constraints.constrain(
      Size(actualContentWidth, currentY + maxLineHeight),
    );

    // RTL adjustment remains the same, as it operates on the final calculated positions.
    if (_textDirection == TextDirection.rtl) {
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
