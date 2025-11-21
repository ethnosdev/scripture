import 'dart:ui';

class HighlightRange {
  final String startId;
  final String endId;
  final Color color;

  const HighlightRange({
    required this.startId,
    required this.endId,
    required this.color,
  });
}
