import 'package:flutter/foundation.dart';

/// Manages the state of word selection within a scripture passage.
///
/// Keeps track of the [startId] and [endId] of the selected range.
/// IDs are expected to be packed integers representing
/// specific words (e.g. BBCCCVVVWWW).
class ScriptureSelectionController extends ChangeNotifier {
  int? _startId;
  int? _endId;

  /// The ID of the first word in the selection.
  int? get startId => _startId;

  /// The ID of the last word in the selection.
  int? get endId => _endId;

  /// Whether a valid selection currently exists.
  bool get hasSelection => _startId != null && _endId != null;

  /// Selects a range of words defined by [start] and [end] IDs.
  ///
  /// This method automatically orders [start] and [end] so that
  /// [startId] is always numerically less than or equal to [endId].
  void selectRange(int start, int end) {
    int newStart;
    int newEnd;

    if (start > end) {
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
  void selectWord(int id) {
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
  bool isSelected(int id) {
    if (!hasSelection) return false;

    if (_startId == null || _endId == null) return false;

    return id >= _startId! && id <= _endId!;
  }
}
