import 'package:flutter/foundation.dart';

/// Where and when the user got one of their own prices: the supplier and
/// the day of the quote. Both are optional.
@immutable
class PriceQuote {
  const PriceQuote({this.supplier = '', this.date});

  /// Reads a saved quote, or returns null when there is nothing usable.
  static PriceQuote? fromJson(Object? json) {
    if (json is! Map) return null;
    final supplier = json['supplier'];
    final date = json['date'];
    final quote = PriceQuote(
      supplier: supplier is String ? supplier.trim() : '',
      date: date is String ? DateTime.tryParse(date) : null,
    );
    return quote.isEmpty ? null : quote;
  }

  final String supplier;

  /// The day of the quote, without a time.
  final DateTime? date;

  bool get isEmpty => supplier.isEmpty && date == null;

  Map<String, String> toJson() => {
    if (supplier.isNotEmpty) 'supplier': supplier,
    if (date case final d?) 'date': d.toIso8601String().substring(0, 10),
  };

  @override
  bool operator ==(Object other) =>
      other is PriceQuote && other.supplier == supplier && other.date == date;

  @override
  int get hashCode => Object.hash(supplier, date);
}

/// One of the user's prices and the day it was quoted, by item key, for
/// telling how old a project's prices are.
typedef DatedPrice = ({double price, DateTime date});
