import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'selection_controller.dart';
import 'space_widget.dart';
import 'text_atom_widget.dart';
import 'word.dart';

class ParagraphWidget extends MultiChildRenderObjectWidget {
  final double firstLineIndent;
  final double subsequentLinesIndent;
  final TextAlign textAlign;
  final ScriptureSelectionController? selectionController;
  final Color highlightColor;
  final bool selectable;

  const ParagraphWidget({
    super.key,
    required super.children,
    this.firstLineIndent = 0.0,
    this.subsequentLinesIndent = 0.0,
    this.textAlign = TextAlign.start,
    this.selectionController,
    this.highlightColor = const Color(0x4D2196F3),
    this.selectable = true,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParagraph(
      firstLineIndent: firstLineIndent,
      subsequentLinesIndent: subsequentLinesIndent,
      textAlign: textAlign,
      selectionController: selectionController,
      highlightColor: highlightColor,
      selectable: selectable,
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
      ..textAlign = textAlign
      ..selectionController = selectionController
      ..highlightColor = highlightColor
      ..selectable = selectable;
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
    ScriptureSelectionController? selectionController,
    Color highlightColor = const Color(0x4D2196F3),
    bool selectable = true,
  }) : _firstLineIndent = firstLineIndent,
       _subsequentLinesIndent = subsequentLinesIndent,
       _textAlign = textAlign,
       _selectionController = selectionController,
       _highlightColor = highlightColor,
       _selectable = selectable;

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

  Color _highlightColor;
  Color get highlightColor => _highlightColor;
  set highlightColor(Color value) {
    if (_highlightColor == value) return;
    _highlightColor = value;
    if (_selectionController?.hasSelection == true) markNeedsPaint();
  }

  ScriptureSelectionController? _selectionController;
  ScriptureSelectionController? get selectionController => _selectionController;
  set selectionController(ScriptureSelectionController? value) {
    if (_selectionController == value) return;
    if (attached) _selectionController?.removeListener(markNeedsPaint);
    _selectionController = value;
    if (attached) _selectionController?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  bool _selectable;
  bool get selectable => _selectable;
  set selectable(bool value) {
    if (_selectable == value) return;
    _selectable = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _selectionController?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _selectionController?.removeListener(markNeedsPaint);
    super.detach();
  }

  /// Returns the Word ID at the given [localOffset].
  String? getWordAtOffset(Offset localOffset) {
    RenderBox? child = lastChild;
    while (child != null) {
      final parentData = child.parentData as ParagraphParentData;
      final offsetInChild = localOffset - parentData.offset;

      // Quick bounds check
      final bool inBounds =
          offsetInChild.dx >= 0 &&
          offsetInChild.dx < child.size.width &&
          offsetInChild.dy >= 0 &&
          offsetInChild.dy < child.size.height;

      if (inBounds) {
        if (child is RenderTextAtom) {
          // Recursively check inside the atom
          final id = child.getWordAtOffset(offsetInChild);
          if (id != null) return id;
        } else if (child is RenderWord) {
          return child.id;
        } else {
          // Hit a Space or other element
          return null;
        }
      }

      child = parentData.previousSibling;
    }
    return null;
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
    // 1. Paint Highlights (Background)
    if (_selectable &&
        _selectionController != null &&
        _selectionController!.hasSelection) {
      _paintSelection(context, offset);
    }

    // 2. Paint Text (Foreground)
    defaultPaint(context, offset);
  }

  void _paintSelection(PaintingContext context, Offset paragraphOffset) {
    final startId = int.tryParse(_selectionController!.startId ?? '');
    final endId = int.tryParse(_selectionController!.endId ?? '');
    if (startId == null || endId == null) return;

    final Paint paint = Paint()
      ..color = _highlightColor
      ..style = PaintingStyle.fill;

    // We will collect all selected rects here
    final List<Rect> selectedRects = [];

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as ParagraphParentData;
      final childOffset = paragraphOffset + childParentData.offset;

      if (child is RenderWord) {
        _collectWordRect(child, childOffset, startId, endId, selectedRects);
      } else if (child is RenderTextAtom) {
        _collectAtomRects(child, childOffset, startId, endId, selectedRects);
      }
      child = childParentData.nextSibling;
    }

    if (selectedRects.isEmpty) return;

    // MERGE LOGIC: Combine rects that are on the same line and adjacent/overlapping
    final Path selectionPath = Path();

    if (selectedRects.isNotEmpty) {
      // Sort by Y then X to ensure safe processing order
      selectedRects.sort((a, b) {
        final dy = a.top.compareTo(b.top);
        if (dy != 0) return dy;
        return a.left.compareTo(b.left);
      });

      Rect? currentRun;

      for (final rect in selectedRects) {
        if (currentRun == null) {
          currentRun = rect;
          continue;
        }

        // Check if this rect is on the same "line" (vertical overlap)
        // We use a slight tolerance for float precision
        final isSameLine =
            (rect.top - currentRun.top).abs() < 5.0 &&
            (rect.bottom - currentRun.bottom).abs() < 5.0;

        if (isSameLine) {
          // Expand the current run to include this rect
          currentRun = currentRun.expandToInclude(rect);
        } else {
          // New line detected: commit the previous run and start a new one
          selectionPath.addRect(currentRun);
          currentRun = rect;
        }
      }
      // Add the final run
      if (currentRun != null) {
        selectionPath.addRect(currentRun);
      }
    }

    context.canvas.drawPath(selectionPath, paint);
  }

  void _collectWordRect(
    RenderWord word,
    Offset offset,
    int startId,
    int endId,
    List<Rect> collector,
  ) {
    final id = int.tryParse(word.id);
    if (id != null && id >= startId && id <= endId) {
      // Inflate slightly for better visuals (connects tiny gaps between words)
      collector.add((offset & word.size).inflate(0.5));
    }
  }

  void _collectAtomRects(
    RenderTextAtom atom,
    Offset atomOffset,
    int startId,
    int endId,
    List<Rect> collector,
  ) {
    RenderBox? atomChild = atom.firstChild;
    while (atomChild != null) {
      final atomChildParentData = atomChild.parentData as TextAtomParentData;
      if (atomChild is RenderWord) {
        final wordOffset = atomOffset + atomChildParentData.offset;
        _collectWordRect(atomChild, wordOffset, startId, endId, collector);
      }
      atomChild = atomChildParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class ParagraphParentData extends ContainerBoxParentData<RenderBox> {}
