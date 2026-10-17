import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/estimate.dart';
import '../data/estimate_repository.dart';

/// The log of recent calculations. Bills of materials live in projects;
/// see ProjectsController.
class EstimatesController extends ChangeNotifier {
  EstimatesController(this._repository)
    : _history = _repository.loadHistory()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Oldest history entries beyond this are dropped.
  static const historyLimit = 100;

  final EstimateRepository _repository;
  final List<Estimate> _history;

  /// Newest first.
  List<Estimate> get history => List.unmodifiable(_history);

  bool _disposed = false;

  /// False once the app has shut down and this controller was disposed.
  bool get isActive => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Logs a calculation. Recalculating with identical inputs reuses the
  /// newest entry instead of adding a duplicate. Returns the stored entry.
  Estimate record(Estimate estimate) {
    if (_history.isNotEmpty && _history.first.sameCalculationAs(estimate)) {
      return _history.first;
    }
    _history.insert(0, estimate);
    if (_history.length > historyLimit) {
      _history.removeRange(historyLimit, _history.length);
    }
    _persistHistory();
    notifyListeners();
    return estimate;
  }

  /// Replaces the history entry [id] with [updated], keeping the id, and
  /// moves it to the top. Used while the user keeps editing one
  /// calculation, so history holds its latest state rather than every
  /// keystroke. Returns the stored entry, or null when [id] is not in the
  /// history.
  Estimate? replaceInHistory(String id, Estimate updated) {
    final index = _history.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final stored = updated.withId(id);
    _history
      ..removeAt(index)
      ..insert(0, stored);
    _persistHistory();
    notifyListeners();
    return stored;
  }

  /// Removes an entry and returns where it was so it can be restored.
  ({int index, Estimate estimate})? removeFromHistory(String id) =>
      _remove(_history, id, _persistHistory);

  void restoreToHistory(int index, Estimate estimate) =>
      _restore(_history, index, estimate, _persistHistory);

  /// Empties the history and returns what was removed, for undo.
  List<Estimate> clearHistory() => _clear(_history, _persistHistory);

  void restoreHistory(List<Estimate> items) {
    _history
      ..clear()
      ..addAll(items);
    _persistHistory();
    notifyListeners();
  }

  ({int index, Estimate estimate})? _remove(
    List<Estimate> list,
    String id,
    void Function() persist,
  ) {
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final removed = list.removeAt(index);
    persist();
    notifyListeners();
    return (index: index, estimate: removed);
  }

  void _restore(
    List<Estimate> list,
    int index,
    Estimate estimate,
    void Function() persist,
  ) {
    if (list.any((e) => e.id == estimate.id)) return;
    list.insert(index.clamp(0, list.length), estimate);
    persist();
    notifyListeners();
  }

  List<Estimate> _clear(List<Estimate> list, void Function() persist) {
    final removed = List<Estimate>.of(list);
    list.clear();
    persist();
    notifyListeners();
    return removed;
  }

  /// Adds entries from a backup that are not already here, keeping the
  /// newest [historyLimit]. Returns how many were added.
  int importHistory(List<Estimate> items) {
    final known = {for (final e in _history) e.id};
    final added = [
      for (final e in items)
        if (!known.contains(e.id)) e,
    ];
    if (added.isEmpty) return 0;
    _history
      ..addAll(added)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_history.length > historyLimit) {
      _history.removeRange(historyLimit, _history.length);
    }
    _persistHistory();
    notifyListeners();
    return added.length;
  }

  void _persistHistory() => unawaited(_repository.saveHistory(_history));
}
