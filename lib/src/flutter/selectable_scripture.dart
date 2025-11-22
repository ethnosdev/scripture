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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTap,
      onLongPressStart: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: (_) => _dragMode = _DragMode.none,
      child: KeyedSubtree(key: _passageKey, child: widget.child),
    );
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

    // 1. Strict Boundary Check (Preferred)
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

    // 2. Proximity Check (Solves the "Invisible Header" issue)
    // If the user drags from *inside* the selection, move the closest boundary.
    if (hitId > startId && hitId < endId) {
      final distToStart = hitId - startId;
      final distToEnd = endId - hitId;

      if (distToStart <= distToEnd) {
        // Closer to start
        _dragMode = _DragMode.start;
        _fixedAnchor = widget.controller.endId;
      } else {
        // Closer to end
        _dragMode = _DragMode.end;
        _fixedAnchor = widget.controller.startId;
      }
      return;
    }

    // 3. Outside Check
    // If user drags a word strictly OUTSIDE the current selection,
    // we do nothing (scrolling handles this).
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
