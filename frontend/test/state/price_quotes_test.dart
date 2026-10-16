import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/price_quote.dart';
import 'package:thesismob/state/price_book_controller.dart';

Future<PriceBookController> setup([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PriceBookController(await SharedPreferences.getInstance());
}

void main() {
  test('a price keeps its supplier and quote date', () async {
    final book = await setup();
    book.setPrice(
      'cement_40kg',
      255,
      supplier: ' Wilcon Depot ',
      quotedOn: DateTime(2026, 9, 3, 15, 30),
    );
    expect(
      book.quoteOf('cement_40kg'),
      PriceQuote(supplier: 'Wilcon Depot', date: DateTime(2026, 9, 3)),
    );
    expect(book.suppliers, {'cement_40kg': 'Wilcon Depot'});
    expect(book.datedPrices['cement_40kg'], (
      price: 255.0,
      date: DateTime(2026, 9, 3),
    ));

    // Saved, and read back.
    final again = PriceBookController(await SharedPreferences.getInstance());
    expect(again.quoteOf('cement_40kg')?.supplier, 'Wilcon Depot');
    expect(again.priceOf('cement_40kg'), 255);
  });

  test('a price set elsewhere is dated today and keeps its supplier', () async {
    final book = await setup();
    book.setPrice('sand', 1800, supplier: 'Aggregates Co.');
    book.setPrice('sand', 1900);
    final quote = book.quoteOf('sand')!;
    final today = DateTime.now();
    expect(quote.supplier, 'Aggregates Co.');
    expect(quote.date, DateTime(today.year, today.month, today.day));
    book.reset('sand');
    expect(book.quoteOf('sand'), isNull);
    expect(book.quotes, isEmpty);
  });

  test('prices saved before quotes still load', () async {
    final book = await setup({
      PriceBookController.key: jsonEncode({'gravel': 1900}),
    });
    expect(book.priceOf('gravel'), 1900);
    expect(book.quoteOf('gravel'), isNull);
    expect(book.datedPrices, isEmpty);
  });

  test('clearing can be undone with the quotes', () async {
    final book = await setup();
    book.setPrice('chb_4', 20, supplier: 'Block maker');
    final prices = book.custom;
    final quotes = book.quotes;
    book.resetAll();
    expect(book.quotes, isEmpty);
    book.restore(prices, quotes: quotes);
    expect(book.quoteOf('chb_4')?.supplier, 'Block maker');
  });
}
