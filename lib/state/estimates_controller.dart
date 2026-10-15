import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/estimate.dart';
import '../data/estimate_repository.dart';

/// App-wide state for calculation history and the project summary.
///
/// History is a log of recent calculations. The summary is the bill of
/// materials the user builds on purpose with "Add to summary".
class EstimatesController extends ChangeNotifier {
  EstimatesController(this._repository)
    : _history = _repository.loadHistory()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      _summary = _repository.loadSummary();

  /// Oldest history entries beyond this are dropped.
  static const historyLimit = 100;

  final EstimateRepository _repository;
  final List<Estimate> _history;
  final List<Estimate> _summary;

  /// Newest first.
  List<Estimate> get history => List.unmodifiable(_history);

  /// In the order items were added.
  List<Estimate> get summary => List.unmodifiable(_summary);

  /// Sum of the summary totals, rounded to the centavo.
  double get summaryTotal =>
      (_summary.fold<double>(0, (sum, e) => sum + e.total) * 100)
          .roundToDouble() /
      100;

  bool _disposed = false;

  /// False once the app has shut down and this controller was disposed.
  bool get isActive => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool isInSummary(String estimateId) =>
      _summary.any((e) => e.id == estimateId);

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

  /// Adds [estimate] to the summary unless it is already there. Returns
  /// whether it was added.
  bool addToSummary(Estimate estimate) {
    if (isInSummary(estimate.id)) return false;
    _summary.add(estimate);
    _persistSummary();
    notifyListeners();
    return true;
  }

  /// Removes an entry and returns where it was so it can be restored.
  ({int index, Estimate estimate})? removeFromSummary(String id) =>
      _remove(_summary, id, _persistSummary);

  ({int index, Estimate estimate})? removeFromHistory(String id) =>
      _remove(_history, id, _persistHistory);

  void restoreToSummary(int index, Estimate estimate) =>
      _restore(_summary, index, estimate, _persistSummary);

  void restoreToHistory(int index, Estimate estimate) =>
      _restore(_history, index, estimate, _persistHistory);

  /// Empties the summary and returns what was removed, for undo.
  List<Estimate> clearSummary() => _clear(_summary, _persistSummary);

  List<Estimate> clearHistory() => _clear(_history, _persistHistory);

  void restoreSummary(List<Estimate> items) {
    _summary
      ..clear()
      ..addAll(items);
    _persistSummary();
    notifyListeners();
  }

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

  void _persistHistory() => unawaited(_repository.saveHistory(_history));

  void _persistSummary() => unawaited(_repository.saveSummary(_summary));
}
