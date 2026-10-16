import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/price_quote.dart';
import '../materials/items.dart';
import '../materials/material_spec.dart';

/// The prices used to suggest costs: the bundled list, with the user's own
/// prices on top. Each of the user's prices can carry the supplier and the
/// day of the quote.
class PriceBookController extends ChangeNotifier {
  PriceBookController(this._prefs)
    : _custom = _load(_prefs),
      _quotes = _loadQuotes(_prefs),
      _region = PriceRegion.byName(_prefs.getString(regionKey));

  static const key = 'price_book_v1';
  static const regionKey = 'price_region_v1';

  /// Suppliers and quote dates, kept apart so older versions still read
  /// the prices.
  static const quotesKey = 'price_quotes_v1';

  final SharedPreferences _prefs;
  final Map<String, double> _custom;
  final Map<String, PriceQuote> _quotes;
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

  static Map<String, PriceQuote> _loadQuotes(SharedPreferences prefs) {
    final raw = prefs.getString(quotesKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (PriceQuote.fromJson(e.value) case final q? when e.key is String)
            e.key as String: q,
      };
    } on FormatException {
      return {};
    }
  }

  /// The user's own prices, keyed by item.
  Map<String, double> get custom => Map.unmodifiable(_custom);

  /// The supplier and quote date of the user's price for [itemKey], if any.
  PriceQuote? quoteOf(String itemKey) =>
      _custom.containsKey(itemKey) ? _quotes[itemKey] : null;

  /// Suppliers and quote dates of the user's prices, keyed by item.
  Map<String, PriceQuote> get quotes => {
    for (final MapEntry(:key, :value) in _quotes.entries)
      if (_custom.containsKey(key)) key: value,
  };

  /// The supplier of each of the user's prices that has one.
  Map<String, String> get suppliers => {
    for (final MapEntry(:key, :value) in quotes.entries)
      if (value.supplier.isNotEmpty) key: value.supplier,
  };

  /// The user's prices that have a quote date, for the old-price check.
  Map<String, DatedPrice> get datedPrices => {
    for (final MapEntry(:key, :value) in quotes.entries)
      if (value.date case final date?) key: (price: _custom[key]!, date: date),
  };

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

  /// Sets the user's price for [itemKey]. The quote is dated [quotedOn],
  /// or today, and keeps its supplier unless [supplier] is given.
  void setPrice(
    String itemKey,
    double price, {
    String? supplier,
    DateTime? quotedOn,
  }) {
    final day = quotedOn ?? DateTime.now();
    final quote = PriceQuote(
      supplier: (supplier ?? _quotes[itemKey]?.supplier ?? '').trim(),
      date: DateTime(day.year, day.month, day.day),
    );
    if (_custom[itemKey] == price && _quotes[itemKey] == quote) return;
    _custom[itemKey] = price;
    _quotes[itemKey] = quote;
    _persist();
  }

  void reset(String itemKey) {
    final removed = _custom.remove(itemKey) != null;
    if ((_quotes.remove(itemKey) != null) || removed) _persist();
  }

  void resetAll() {
    if (_custom.isEmpty && _quotes.isEmpty) return;
    _custom.clear();
    _quotes.clear();
    _persist();
  }

  /// Replaces the user's prices, e.g. from a backup file, and their
  /// quotes with [quotes] when given.
  void restore(Map<String, double> prices, {Map<String, PriceQuote>? quotes}) {
    _custom
      ..clear()
      ..addAll(prices);
    if (quotes != null) {
      _quotes
        ..clear()
        ..addAll(quotes);
    }
    _quotes.removeWhere((key, _) => !_custom.containsKey(key));
    _persist();
  }

  void _persist() {
    unawaited(_prefs.setString(key, jsonEncode(_custom)));
    unawaited(
      _prefs.setString(
        quotesKey,
        jsonEncode({
          for (final MapEntry(:key, :value) in _quotes.entries)
            if (!value.isEmpty) key: value.toJson(),
        }),
      ),
    );
    notifyListeners();
  }
}
