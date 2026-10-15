import 'package:flutter/foundation.dart';

import 'items_finishes.dart';
import 'items_mep.dart';
import 'items_structure.dart';
import 'interiors.dart';
import 'sitework.dart';
import 'utilities.dart';

export 'items_finishes.dart';
export 'items_mep.dart';
export 'items_structure.dart';

/// Sections of the materials list, in the order a hardware or a quantity
/// surveyor would group them.
enum ItemGroup {
  cement('Cement and aggregates'),
  masonry('Masonry'),
  steel('Reinforcing steel'),
  lumber('Lumber and boards'),
  ceiling('Ceiling framing'),
  roofing('Roofing and insulation'),
  paint('Paint and finishes'),
  tiles('Tiles and floor finishes'),
  electrical('Electrical'),
  plumbing('Plumbing'),
  fixtures('Plumbing fixtures'),
  doors('Doors and windows'),
  other('Other materials');

  const ItemGroup(this.label);

  final String label;
}

/// Something you can buy: a bag of cement, a 6 m bar, a box of wire.
@immutable
class Item {
  const Item(
    this.key,
    this.name,
    this.unit,
    this.group, {
    this.plural,
    this.step = 1,
    this.price = 0,
    this.estimate = false,
  });

  /// Stable id used by calculators, saved estimates and the price book.
  final String key;
  final String name;
  final String unit;
  final String? plural;
  final ItemGroup group;

  /// Smallest amount sold: 1 for pieces and bags, 0.5 for half cubic
  /// metres of sand, 0 for amounts that are not rounded.
  final double step;

  /// Suggested Metro Manila retail price in pesos, or 0 when the user must
  /// enter one. See [priceListLabel] and docs/prices-and-costing.md.
  final double price;

  /// True when [price] is our own estimate rather than a published or
  /// retailer price, so the user should check it first.
  final bool estimate;

  String unitFor(num quantity) => quantity == 1 ? unit : plural ?? unit;

  /// Rounds [quantity] up to an amount that can be bought.
  double purchasable(double quantity) {
    if (step <= 0) return quantity;
    final steps = (quantity / step - 1e-9).ceil();
    return steps * step;
  }
}

/// Where and when the suggested prices were gathered.
const priceListLabel = 'Metro Manila, Aug–Oct 2026';

/// Where the suggested prices come from.
const priceListSources =
    'DTI e-Presyo prevailing prices (Aug 2026) for cement, blocks, steel, '
    'nails, GI sheets and bulbs; Wilcon and other retailer listings for '
    'the rest. Prices marked "estimate" are our own and should be checked '
    'with your supplier.';

/// Every item that calculators can list, in materials-list order.
final List<Item> allItems = [
  ...structureItems,
  ...finishItems,
  ...mepItems,
  ...siteworkItems,
  ...interiorsItems,
  ...utilitiesItems,
];

final Map<String, Item> _byKey = {for (final i in allItems) i.key: i};

Item? itemByKey(String key) => _byKey[key];

/// Regional price levels relative to Metro Manila, from DTI's August 2026
/// prevailing prices: steel and cement cost about 5–20% more outside the
/// Luzon core, and more again on remote islands.
enum PriceRegion {
  metroManila('Metro Manila and nearby', 1.00),
  luzon('Rest of Luzon', 1.08),
  visayas('Visayas', 1.08),
  mindanao('Mindanao', 1.08),
  remote('Island provinces and remote sites', 1.20);

  const PriceRegion(this.label, this.factor);

  final String label;
  final double factor;

  static PriceRegion byName(String? name) =>
      values.firstWhere((r) => r.name == name, orElse: () => metroManila);
}
