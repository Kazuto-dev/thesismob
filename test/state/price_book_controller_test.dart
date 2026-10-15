import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/price_book_controller.dart';

Future<PriceBookController> setup([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PriceBookController(await SharedPreferences.getInstance());
}

void main() {
  test('every item has a unique key and a sensible price', () {
    expect(allItems.map((i) => i.key).toSet(), hasLength(allItems.length));
    for (final i in allItems) {
      expect(i.price, greaterThanOrEqualTo(0), reason: i.key);
      if (i.step > 0) expect(i.price, greaterThan(0), reason: i.key);
    }
  });

  test('suggests the bundled price until the user sets one', () async {
    final book = await setup();
    expect(book.priceOf('cement_40kg'), 240);
    expect(book.isCustom('cement_40kg'), isFalse);
    book.setPrice('cement_40kg', 265);
    expect(book.priceOf('cement_40kg'), 265);
    expect(book.isCustom('cement_40kg'), isTrue);
    book.reset('cement_40kg');
    expect(book.priceOf('cement_40kg'), 240);
    expect(book.priceOf('no_such_item'), 0);
  });

  test('a price reference can scale the price', () async {
    final book = await setup();
    // An 8 ft corrugated sheet at ₱78 per foot.
    expect(book.suggest(const PriceRef('gi_corrugated_8ft')), 624);
    expect(book.suggest(const PriceRef('tile_60x60', 4)), 680);
    expect(book.suggest(const PriceRef('pvc_fittings')), isNull);
    expect(book.suggest(null), isNull);
  });

  test('regions raise suggested prices but not the user\'s own', () async {
    final book = await setup();
    book.setPrice('chb_4', 20);
    book.region = PriceRegion.remote;
    expect(book.priceOf('cement_40kg'), 288);
    expect(book.priceOf('chb_4'), 20);
  });

  test('prices and region are saved', () async {
    final first = await setup();
    first
      ..setPrice('sand', 1800)
      ..region = PriceRegion.visayas;
    final prefs = await SharedPreferences.getInstance();
    final again = PriceBookController(prefs);
    expect(again.priceOf('sand'), 1800);
    expect(again.region, PriceRegion.visayas);
    again.resetAll();
    expect(again.custom, isEmpty);
    again.restore({'sand': 1700});
    expect(again.priceOf('sand'), 1700);
  });
}
