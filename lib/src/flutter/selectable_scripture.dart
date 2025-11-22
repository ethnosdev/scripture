import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'passage.dart';
import 'selection_controller.dart'; // Import to access RenderPassage

enum _DragMode { none, start, end }

class SelectableScripture extends StatefulWidget {
  final Widget child;
  final ScriptureSelectionController controller;
  final void Function(int wordId)? onWordTapped;
  final void Function(int wordId)? onSelectionRequested;

  const SelectableScripture({
    super.key,
    required this.child,
    required this.controller,
    this.onWordTapped,
    this.onSelectionRequested,
  });

  @override
  State<SelectableScripture> createState() => _SelectableScriptureState();
}

class _SelectableScriptureState extends State<SelectableScripture> {
  final GlobalKey _passageKey = GlobalKey();
  _DragMode _dragMode = _DragMode.none;
  int? _fixedAnchor;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        HandlePanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<HandlePanGestureRecognizer>(
              () => HandlePanGestureRecognizer(isHandleHit: _isHandleHit),
              (HandlePanGestureRecognizer instance) {
                instance
                  ..onStart = _handlePanStart
                  ..onUpdate = _handlePanUpdate
                  ..onEnd = (_) => _dragMode = _DragMode.none;
              },
            ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTap,
        onLongPressStart: _handleLongPress,
        child: KeyedSubtree(key: _passageKey, child: widget.child),
      ),
    );
  }

  /// Returns true if the touch is strictly on the Start or End word of the current selection.
  bool _isHandleHit(Offset globalPosition) {
    if (!widget.controller.hasSelection) return false;

    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage) return false;

    final localOffset = renderObject.globalToLocal(globalPosition);
    final hitId = renderObject.getWordAtOffset(localOffset);

    if (hitId == null) return false;

    // Only claim the gesture if we hit the exact Start or End word
    return hitId == widget.controller.startId ||
        hitId == widget.controller.endId;
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
    if (renderObject is! RenderPassage) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final hitId = renderObject.getWordAtOffset(localOffset);

    if (hitId == null) {
      _dragMode = _DragMode.none;
      return;
    }

    final startId = widget.controller.startId;
    final endId = widget.controller.endId;

    if (startId == null || endId == null) {
      _dragMode = _DragMode.none;
      return;
    }

    if (hitId == startId) {
      _dragMode = _DragMode.start;
      _fixedAnchor = widget.controller.endId;
      return;
    }

    if (hitId == endId) {
      _dragMode = _DragMode.end;
      _fixedAnchor = widget.controller.startId;
      return;
    }

    // Logic to determine drag mode based on proximity if not exact hit
    if (hitId > startId && hitId < endId) {
      final distToStart = hitId - startId;
      final distToEnd = endId - hitId;
      if (distToStart <= distToEnd) {
        _dragMode = _DragMode.start;
        _fixedAnchor = widget.controller.endId;
      } else {
        _dragMode = _DragMode.end;
        _fixedAnchor = widget.controller.startId;
      }
      return;
    }

    _dragMode = _DragMode.none;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragMode == _DragMode.none) return;

    final renderObject = _passageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderPassage) return;

    // 1. Find word under finger
    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final hitWordId = renderObject.getWordAtOffset(localOffset);

    if (hitWordId != null && _fixedAnchor != null) {
      // 2. Update Selection
      if (_dragMode == _DragMode.start) {
        widget.controller.selectRange(hitWordId, _fixedAnchor!);
      } else {
        widget.controller.selectRange(_fixedAnchor!, hitWordId);
      }
    }
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
