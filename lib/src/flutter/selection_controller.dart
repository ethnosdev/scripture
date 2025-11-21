import 'package:flutter/foundation.dart';

/// Manages the state of word selection within a scripture passage.
///
/// Keeps track of the [startId] and [endId] of the selected range.
/// IDs are expected to be numeric strings (packed integers) representing
/// specific words (e.g. BBCCCVVVWWW).
class ScriptureSelectionController extends ChangeNotifier {
  String? _startId;
  String? _endId;

  /// The ID of the first word in the selection.
  String? get startId => _startId;

  /// The ID of the last word in the selection.
  String? get endId => _endId;

  /// Whether a valid selection currently exists.
  bool get hasSelection => _startId != null && _endId != null;

  /// Selects a range of words defined by [start] and [end] IDs.
  ///
  /// This method automatically orders [start] and [end] so that
  /// [startId] is always numerically less than or equal to [endId].
  void selectRange(String start, String end) {
    // Parse to integers to compare magnitude correctly
    final s = int.tryParse(start) ?? -1;
    final e = int.tryParse(end) ?? -1;

    // If parsing failed, we can't safely select
    if (s == -1 || e == -1) return;

    String newStart;
    String newEnd;

    if (s > e) {
      newStart = end;
      newEnd = start;
    } else {
      newStart = start;
      newEnd = end;
    }

    if (_startId != newStart || _endId != newEnd) {
      _startId = newStart;
      _endId = newEnd;
      notifyListeners();
    }
  }

  /// Selects a single word.
  void selectWord(String id) {
    selectRange(id, id);
  }

  /// Clears the current selection.
  void clear() {
    if (_startId != null || _endId != null) {
      _startId = null;
      _endId = null;
      notifyListeners();
    }
  }

  /// Helper to check if a specific word ID falls within the current selection.
  bool isSelected(String id) {
    if (!hasSelection) return false;

    final target = int.tryParse(id);
    final start = int.tryParse(_startId!);
    final end = int.tryParse(_endId!);

    if (target == null || start == null || end == null) return false;

    return target >= start && target <= end;
  }
}
