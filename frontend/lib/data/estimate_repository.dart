import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'estimate.dart';
import 'legacy_migration.dart';

/// Persists history and summary estimates in SharedPreferences (browser
/// localStorage on the web).
///
/// On first run it imports the lists saved by the original app. The original
/// keys are left untouched so nothing is lost if the old version is reopened.
class EstimateRepository {
  EstimateRepository(this._prefs);

  static const historyKey = 'estimates_history_v2';
  static const summaryKey = 'estimates_summary_v2';
  static const legacyHistoryKey = 'calculation_history';
  static const legacySummaryKey = 'calculation_summary';

  final SharedPreferences _prefs;

  List<Estimate> loadHistory() =>
      _load(historyKey, legacyHistoryKey, estimateFromLegacyHistory);

  List<Estimate> loadSummary() =>
      _load(summaryKey, legacySummaryKey, estimateFromLegacySummary);

  Future<void> saveHistory(List<Estimate> history) =>
      _save(historyKey, history);

  Future<void> saveSummary(List<Estimate> summary) =>
      _save(summaryKey, summary);

  Future<void> _save(String key, List<Estimate> estimates) => _prefs.setString(
    key,
    jsonEncode([for (final e in estimates) e.toJson()]),
  );

  List<Estimate> _load(
    String key,
    String legacyKey,
    Estimate? Function(Map<String, dynamic>, int) fromLegacy,
  ) {
    final saved = _prefs.getString(key);
    if (saved != null) {
      return _decode(saved, (json, _) => Estimate.fromJson(json));
    }
    final legacy = _prefs.getString(legacyKey);
    if (legacy == null) return [];
    final migrated = _decode(legacy, fromLegacy);
    _save(key, migrated);
    return migrated;
  }

  /// Decodes a JSON list, skipping entries that cannot be read rather than
  /// losing the whole list.
  List<Estimate> _decode(
    String raw,
    Estimate? Function(Map<String, dynamic>, int) parse,
  ) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      debugPrint('Ignoring unreadable saved estimates: $e');
      return [];
    }
    if (decoded is! List) return [];
    final result = <Estimate>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map<String, dynamic>) continue;
      try {
        final estimate = parse(item, i);
        if (estimate != null) result.add(estimate);
      } on FormatException catch (e) {
        debugPrint('Skipping saved estimate $i: $e');
      }
    }
    return result;
  }
}
