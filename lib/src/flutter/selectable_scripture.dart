import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'passage.dart';
import 'selection_controller.dart';

const double kSelectionHandleSize = 22.0;

enum _DragMode { none, start, end }

class SelectableScripture extends StatefulWidget {
  final Widget child;
  final ScriptureSelectionController controller;
  final void Function(int wordId)? onWordTapped;
  final void Function(int wordId)? onSelectionRequested;
  final Color? handleColor;
  final bool showHandles;

  const SelectableScripture({
    super.key,
    required this.child,
    required this.controller,
    this.onWordTapped,
    this.onSelectionRequested,
    this.handleColor,
    this.showHandles = true,
  });

  @override
  State<SelectableScripture> createState() => _SelectableScriptureState();
}

class _SelectableScriptureState extends State<SelectableScripture> {
  final GlobalKey _passageKey = GlobalKey();
  _DragMode _dragMode = _DragMode.none;
  int? _fixedAnchor;
  Offset _dragOffsetDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final effectiveHandleColor = widget.handleColor ??
        TextSelectionTheme.of(context).selectionHandleColor ??
        Theme.of(context).colorScheme.primary;

    Widget passageChild = KeyedSubtree(key: _passageKey, child: widget.child);

    if (widget.showHandles) {
      passageChild = CustomPaint(
        foregroundPainter: _SelectionHandlesPainter(
          controller: widget.controller,
          passageKey: _passageKey,
          handleColor: effectiveHandleColor,
        ),
        child: passageChild,
      );
    }

    return _SelectableScriptureHitTargetWidget(
      isHandleHit: _isHandleHit,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          HandlePanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<HandlePanGestureRecognizer>(
                () => HandlePanGestureRecognizer(isHandleHit: _isHandleHit),
                (HandlePanGestureRecognizer instance) {
                  instance
                    ..onStart = _handlePanStart
                    ..onUpdate = _handlePanUpdate
                    ..onEnd = (_) {
                      _dragMode = _DragMode.none;
                      _fixedAnchor = null;
                      _dragOffsetDelta = Offset.zero;
                    }
                    ..onCancel = () {
                      _dragMode = _DragMode.none;
                      _fixedAnchor = null;
                      _dragOffsetDelta = Offset.zero;
                    };
                },
              ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTap,
          onLongPressStart: _handleLongPress,
          child: passageChild,
        ),
      ),
    );
  }

  /// Returns true if the touch is on or near the start handle/word or end handle/word.
  bool _isHandleHit(Offset globalPosition) {
    if (!widget.controller.hasSelection) return false;

    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage || !renderObject.hasSize) return false;

    final localOffset = renderObject.globalToLocal(globalPosition);

    final startId = widget.controller.startId;
    final endId = widget.controller.endId;
    if (startId == null || endId == null) return false;

    return _isTargetHit(renderObject, startId, localOffset, isStart: true) ||
        _isTargetHit(renderObject, endId, localOffset, isStart: false);
  }

  bool _isTargetHit(
    RenderPassage renderObject,
    int wordId,
    Offset localOffset, {
    required bool isStart,
  }) {
    final geom = renderObject.getWordGeometry(wordId);
    if (geom == null) return false;

    // Word bounds (inflated slightly for easy touch)
    if (geom.rect.inflate(4.0).contains(localOffset)) {
      return true;
    }

    // Handle touch target (at least 44x44 points)
    final anchor = _getHandleAnchor(geom.rect, geom.direction, isStart: isStart);
    final type = _getHandleType(geom.direction, isStart: isStart);
    final bounds = _getHandleBounds(
      anchor: anchor,
      type: type,
      passageWidth: renderObject.size.width,
    );
    final touchTarget = bounds.inflate(11.0);
    return touchTarget.contains(localOffset);
  }

  void _handleTap(TapUpDetails details) {
    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final hitWordId = renderObject.getWordAtOffset(localOffset);

    if (hitWordId == null) {
      // Tapped on whitespace -> Clear selection
      if (widget.controller.hasSelection) {
        widget.controller.clear();
      }
      return;
    }

    // Tapped on a word
    if (widget.controller.hasSelection) {
      // If selection exists, tapping anywhere (even on a word) deselects
      widget.controller.clear();
    } else {
      // If no selection, trigger normal tap (e.g., footnotes)
      widget.onWordTapped?.call(hitWordId);
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final hitWordId = renderObject.getWordAtOffset(localOffset);

    if (hitWordId != null) {
      widget.onSelectionRequested?.call(hitWordId);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.controller.hasSelection) return;

    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage || !renderObject.hasSize) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);

    final startId = widget.controller.startId;
    final endId = widget.controller.endId;
    if (startId == null || endId == null) {
      _dragMode = _DragMode.none;
      return;
    }

    final startGeom = renderObject.getWordGeometry(startId);
    final endGeom = renderObject.getWordGeometry(endId);

    final startAnchor = startGeom != null
        ? _getHandleAnchor(startGeom.rect, startGeom.direction, isStart: true)
        : null;
    final endAnchor = endGeom != null
        ? _getHandleAnchor(endGeom.rect, endGeom.direction, isStart: false)
        : null;

    final distToStart = startAnchor != null
        ? (localOffset - startAnchor).distanceSquared
        : double.infinity;
    final distToEnd = endAnchor != null
        ? (localOffset - endAnchor).distanceSquared
        : double.infinity;

    if (distToStart <= distToEnd) {
      _dragMode = _DragMode.start;
      _fixedAnchor = endId;
      _dragOffsetDelta = startAnchor != null ? localOffset - startAnchor : Offset.zero;
    } else {
      _dragMode = _DragMode.end;
      _fixedAnchor = startId;
      _dragOffsetDelta = endAnchor != null ? localOffset - endAnchor : Offset.zero;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragMode == _DragMode.none || _fixedAnchor == null) return;

    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage || !renderObject.hasSize) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final effectiveOffset = localOffset - _dragOffsetDelta;

    final hitWordId = renderObject.getWordAtOrNearOffset(effectiveOffset);

    if (hitWordId != null) {
      if (_dragMode == _DragMode.start) {
        widget.controller.selectRange(hitWordId, _fixedAnchor!);
      } else {
        widget.controller.selectRange(_fixedAnchor!, hitWordId);
      }
    }
  }
}

Offset _getHandleAnchor(Rect wordRect, TextDirection direction, {required bool isStart}) {
  if (direction == TextDirection.ltr) {
    return isStart
        ? Offset(wordRect.left, wordRect.bottom)
        : Offset(wordRect.right, wordRect.bottom);
  } else {
    // In RTL, the first word's start edge is on the right, end word's end edge is on the left
    return isStart
        ? Offset(wordRect.right, wordRect.bottom)
        : Offset(wordRect.left, wordRect.bottom);
  }
}

TextSelectionHandleType _getHandleType(TextDirection direction, {required bool isStart}) {
  if (direction == TextDirection.ltr) {
    return isStart ? TextSelectionHandleType.left : TextSelectionHandleType.right;
  } else {
    return isStart ? TextSelectionHandleType.right : TextSelectionHandleType.left;
  }
}

Rect _getHandleBounds({
  required Offset anchor,
  required TextSelectionHandleType type,
  required double passageWidth,
}) {
  final bool flipToRight =
      type == TextSelectionHandleType.left && (anchor.dx - kSelectionHandleSize < 0);
  final bool flipToLeft =
      type == TextSelectionHandleType.right && (anchor.dx + kSelectionHandleSize > passageWidth);

  final effectiveType = flipToRight
      ? TextSelectionHandleType.right
      : (flipToLeft ? TextSelectionHandleType.left : type);

  final double left = effectiveType == TextSelectionHandleType.left
      ? anchor.dx - kSelectionHandleSize
      : anchor.dx;

  return Rect.fromLTWH(left, anchor.dy, kSelectionHandleSize, kSelectionHandleSize);
}

class _SelectionHandlesPainter extends CustomPainter {
  final ScriptureSelectionController controller;
  final GlobalKey passageKey;
  final Color handleColor;

  _SelectionHandlesPainter({
    required this.controller,
    required this.passageKey,
    required this.handleColor,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.hasSelection) return;

    final renderObject = passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage || !renderObject.hasSize) return;

    final startId = controller.startId;
    final endId = controller.endId;
    if (startId == null || endId == null) return;

    final startGeom = renderObject.getWordGeometry(startId);
    final endGeom = renderObject.getWordGeometry(endId);

    if (startGeom != null) {
      _paintHandle(
        canvas: canvas,
        wordRect: startGeom.rect,
        direction: startGeom.direction,
        isStart: true,
        passageWidth: size.width,
        color: handleColor,
      );
    }

    if (endGeom != null) {
      _paintHandle(
        canvas: canvas,
        wordRect: endGeom.rect,
        direction: endGeom.direction,
        isStart: false,
        passageWidth: size.width,
        color: handleColor,
      );
    }
  }

  void _paintHandle({
    required Canvas canvas,
    required Rect wordRect,
    required TextDirection direction,
    required bool isStart,
    required double passageWidth,
    required Color color,
  }) {
    final anchor = _getHandleAnchor(wordRect, direction, isStart: isStart);
    final type = _getHandleType(direction, isStart: isStart);

    final bool flipToRight =
        type == TextSelectionHandleType.left && (anchor.dx - kSelectionHandleSize < 0);
    final bool flipToLeft =
        type == TextSelectionHandleType.right && (anchor.dx + kSelectionHandleSize > passageWidth);

    final effectiveType = flipToRight
        ? TextSelectionHandleType.right
        : (flipToLeft ? TextSelectionHandleType.left : type);

    final double left = effectiveType == TextSelectionHandleType.left
        ? anchor.dx - kSelectionHandleSize
        : anchor.dx;
    final double top = anchor.dy;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = kSelectionHandleSize / 2.0;
    final circle = Rect.fromCircle(
      center: Offset(left + radius, top + radius),
      radius: radius,
    );

    final point = effectiveType == TextSelectionHandleType.left
        ? Rect.fromLTWH(left + radius, top, radius, radius)
        : Rect.fromLTWH(left, top, radius, radius);

    final path = Path()
      ..addOval(circle)
      ..addRect(point);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SelectionHandlesPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.handleColor != handleColor;
  }
}

class HandlePanGestureRecognizer extends PanGestureRecognizer {
  final bool Function(Offset globalPosition) isHandleHit;

  HandlePanGestureRecognizer({required this.isHandleHit});

  @override
  void addPointer(PointerDownEvent event) {
    // 1. Check if the touch hits a selection handle BEFORE adding the pointer
    if (isHandleHit(event.position)) {
      super.addPointer(event);
      // 2. AGGRESSIVE WIN: Immediately declare victory in the gesture arena.
      // This prevents a PageView from stealing the gesture after a few pixels of movement.
      resolve(GestureDisposition.accepted);
    } else {
      // 3. Ignore the touch. This lets a PageView/ScrollView handle it.
      // We don't call super.addPointer(event).
    }
  }
}

class _SelectableScriptureHitTargetWidget
    extends SingleChildRenderObjectWidget {
  final bool Function(Offset globalPosition) isHandleHit;

  const _SelectableScriptureHitTargetWidget({
    required this.isHandleHit,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSelectableScriptureHitTarget(isHandleHit: isHandleHit);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSelectableScriptureHitTarget renderObject,
  ) {
    renderObject.isHandleHit = isHandleHit;
  }
}

class _RenderSelectableScriptureHitTarget extends RenderProxyBox {
  _RenderSelectableScriptureHitTarget({
    required bool Function(Offset globalPosition) isHandleHit,
  }) : _isHandleHit = isHandleHit;

  bool Function(Offset globalPosition) _isHandleHit;
  set isHandleHit(bool Function(Offset globalPosition) value) {
    _isHandleHit = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      if (hitTestChildren(result, position: position) ||
          hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }

    if (child != null && !size.isEmpty) {
      final globalPos = localToGlobal(position);
      if (_isHandleHit(globalPos)) {
        final clamped = Offset(
          position.dx.clamp(0.0, size.width - 1.0),
          position.dy.clamp(0.0, size.height - 1.0),
        );
        if (hitTestChildren(result, position: clamped) ||
            hitTestSelf(clamped)) {
          result.add(BoxHitTestEntry(this, position));
          return true;
        }
      }
    }

    return false;
  }
}

