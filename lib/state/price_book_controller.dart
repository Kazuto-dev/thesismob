import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../materials/items.dart';
import '../materials/material_spec.dart';

/// The prices used to suggest costs: the bundled list, with the user's own
/// prices on top.
class PriceBookController extends ChangeNotifier {
  PriceBookController(this._prefs)
    : _custom = _load(_prefs),
      _region = PriceRegion.byName(_prefs.getString(regionKey));

  static const key = 'price_book_v1';
  static const regionKey = 'price_region_v1';

  final SharedPreferences _prefs;
  final Map<String, double> _custom;
  PriceRegion _region;

  /// Where the project is, which scales the suggested prices.
  PriceRegion get region => _region;

  set region(PriceRegion value) {
    if (value == _region) return;
    _region = value;
    unawaited(_prefs.setString(regionKey, value.name));
    notifyListeners();
  }

  static Map<String, double> _load(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (e.key is String && e.value is num && (e.value as num) >= 0)
            e.key as String: (e.value as num).toDouble(),
      };
    } on FormatException {
      return {};
    }
  }

  /// The user's own prices, keyed by item.
  Map<String, double> get custom => Map.unmodifiable(_custom);

  bool isCustom(String itemKey) => _custom.containsKey(itemKey);

  /// The suggested price of [itemKey] for the region, before the user's
  /// own price.
  double defaultPriceOf(String itemKey) {
    final price = (itemByKey(itemKey)?.price ?? 0) * _region.factor;
    return (price * 100).roundToDouble() / 100;
  }

  /// The price of one unit of [itemKey], or 0 when there is none.
  double priceOf(String itemKey) => _custom[itemKey] ?? defaultPriceOf(itemKey);

  /// The suggested price for a calculator's price field.
  double? suggest(PriceRef? ref) {
    if (ref == null) return null;
    final price = priceOf(ref.itemKey) * ref.factor;
    return price > 0 ? (price * 100).roundToDouble() / 100 : null;
  }

  void setPrice(String itemKey, double price) {
    if (_custom[itemKey] == price) return;
    _custom[itemKey] = price;
    _persist();
  }

  void reset(String itemKey) {
    if (_custom.remove(itemKey) != null) _persist();
  }

  void resetAll() {
    if (_custom.isEmpty) return;
    _custom.clear();
    _persist();
  }

  /// Replaces the user's prices, e.g. from a backup file.
  void restore(Map<String, double> prices) {
    _custom
      ..clear()
      ..addAll(prices);
    _persist();
  }

  void _persist() {
    unawaited(_prefs.setString(key, jsonEncode(_custom)));
    notifyListeners();
  }
}
