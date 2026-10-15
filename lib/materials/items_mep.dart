import 'items.dart';

// Electrical, plumbing and plumbing fixtures. Prices are Metro Manila
// retail in pesos; see docs/calculations.md for sources.

/// THHN/THWN building wire sizes in mm².
const wireSizes = ['2.0', '3.5', '5.5', '8.0', '14', '22', '30'];

/// LED bulb wattages.
const bulbWatts = [5, 7, 9, 12, 15, 18];

/// Circuit breaker ratings in amperes.
const breakerRatings = [15, 20, 30, 40, 60, 100];

/// Panel board sizes by number of branch circuits.
const panelBranches = [4, 6, 8, 12, 16, 20, 24, 30];

/// PVC pipe sizes: id and label. ½"–1" are blue pressure pipe for water,
/// 2"–4" orange sanitary pipe for drains (Neltex outside diameters).
const pipeSizes = [
  ('0_5', '½" (20 mm)'),
  ('0_75', '¾" (25 mm)'),
  ('1', '1" (32 mm)'),
  ('2', '2" (57 mm)'),
  ('3', '3" (82 mm)'),
  ('4', '4" (107 mm)'),
];

/// Pipe sizes that carry water under pressure; PPR comes in these too.
const waterPipeSizes = {'0_5', '0_75', '1'};

/// Polyethylene water tank sizes in litres.
const waterTankLitres = [500, 1000, 1500, 2000];

String wireBoxKey(String mm2) => 'thhn_${mm2.replaceAll('.', '_')}_box';
String wireMetreKey(String mm2) => 'thhn_${mm2.replaceAll('.', '_')}_m';
String bulbKey(int watts) => 'led_bulb_${watts}w';
String breakerKey(int amps) => 'breaker_${amps}a';
String panelKey(int branches) => 'panel_$branches';
String pipeKey(String size) => 'pvc_$size';
String pprKey(String size) => 'ppr_$size';
String waterTankKey(int litres) => 'water_tank_$litres';

/// Price of a 150 m box of wire, by size.
const _wireBox = {
  '2.0': 3300.0,
  '3.5': 5200.0,
  '5.5': 8000.0,
  '8.0': 12500.0,
  '14': 21000.0,
  '22': 32000.0,
  '30': 43000.0,
};

const _bulbPrices = {
  5: 80.0,
  7: 95.0,
  9: 115.0,
  12: 150.0,
  15: 190.0,
  18: 230.0,
};
const _breakerPrices = {
  15: 350.0,
  20: 350.0,
  30: 380.0,
  40: 450.0,
  60: 650.0,
  100: 1800.0,
};
const _panelPrices = {
  4: 1500.0,
  6: 2000.0,
  8: 2500.0,
  12: 3500.0,
  16: 4800.0,
  20: 6000.0,
  24: 7500.0,
  30: 9000.0,
};
const _pipePrices = {
  '0_5': 90.0,
  '0_75': 120.0,
  '1': 190.0,
  '2': 220.0,
  '3': 340.0,
  '4': 460.0,
};
const _pprPrices = {'0_5': 250.0, '0_75': 380.0, '1': 600.0};
const _tankPrices = {500: 5000.0, 1000: 8000.0, 1500: 11000.0, 2000: 14000.0};

final List<Item> mepItems = [
  // Electrical.
  for (final size in wireSizes) ...[
    Item(
      wireBoxKey(size),
      'THHN wire $size mm², box of 150 m',
      'box',
      ItemGroup.electrical,
      plural: 'boxes',
      price: _wireBox[size]!,
      estimate: true,
    ),
    // Cut from the reel costs about 15% more per metre.
    Item(
      wireMetreKey(size),
      'THHN wire $size mm², cut',
      'm',
      ItemGroup.electrical,
      price: (_wireBox[size]! / 150 * 1.15).roundToDouble(),
      estimate: true,
    ),
  ],
  const Item(
    'conduit_half',
    'PVC conduit ½" (20 mm), 3 m',
    'length',
    ItemGroup.electrical,
    plural: 'lengths',
    price: 65,
    estimate: true,
  ),
  const Item(
    'conduit_three_quarter',
    'PVC conduit ¾" (25 mm), 3 m',
    'length',
    ItemGroup.electrical,
    plural: 'lengths',
    price: 90,
    estimate: true,
  ),
  const Item(
    'conduit_fittings',
    'Conduit couplings and connectors',
    'lot',
    ItemGroup.electrical,
    step: 0,
  ),
  const Item(
    'utility_box',
    'Utility box 2"×4"',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 25,
    estimate: true,
  ),
  const Item(
    'junction_box',
    'Junction box 4"×4"',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 30,
    estimate: true,
  ),
  const Item(
    'switch',
    'Wall switch, 1-gang',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 60,
  ),
  const Item(
    'switch_plate',
    'Switch plate',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 30,
    estimate: true,
  ),
  const Item(
    'outlet',
    'Convenience outlet, duplex, with plate',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 150,
    estimate: true,
  ),
  const Item(
    'aircon_outlet',
    'Aircon outlet, 250 V, with plate',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 220,
    estimate: true,
  ),
  for (final w in bulbWatts)
    Item(
      bulbKey(w),
      'LED bulb $w W',
      'pc',
      ItemGroup.electrical,
      plural: 'pcs',
      price: _bulbPrices[w]!,
    ),
  const Item(
    'lamp_holder',
    'Lamp holder, E27',
    'pc',
    ItemGroup.electrical,
    plural: 'pcs',
    price: 40,
    estimate: true,
  ),
  for (final a in breakerRatings)
    Item(
      breakerKey(a),
      'Circuit breaker $a A, plug-in',
      'pc',
      ItemGroup.electrical,
      plural: 'pcs',
      price: _breakerPrices[a]!,
      estimate: true,
    ),
  for (final b in panelBranches)
    Item(
      panelKey(b),
      'Panel board, $b branches, with main',
      'pc',
      ItemGroup.electrical,
      plural: 'pcs',
      price: _panelPrices[b]!,
      estimate: true,
    ),
  const Item(
    'ground_rod',
    'Ground rod 16 mm × 2.4 m with clamp',
    'set',
    ItemGroup.electrical,
    plural: 'sets',
    price: 650,
    estimate: true,
  ),
  const Item(
    'electrical_tape',
    'Electrical tape',
    'roll',
    ItemGroup.electrical,
    plural: 'rolls',
    price: 35,
    estimate: true,
  ),

  // Plumbing.
  for (final (id, label) in pipeSizes)
    Item(
      pipeKey(id),
      waterPipeSizes.contains(id)
          ? 'PVC pressure pipe (blue) $label, 3 m'
          : 'PVC sanitary pipe (orange) $label, 3 m',
      'pc',
      ItemGroup.plumbing,
      plural: 'pcs',
      price: _pipePrices[id]!,
      estimate: true,
    ),
  for (final (id, label) in pipeSizes)
    if (waterPipeSizes.contains(id))
      Item(
        pprKey(id),
        'PPR pipe PN20 $label, 4 m',
        'pc',
        ItemGroup.plumbing,
        plural: 'pcs',
        price: _pprPrices[id]!,
        estimate: true,
      ),
  const Item(
    'pvc_fittings',
    'PVC fittings allowance',
    'lot',
    ItemGroup.plumbing,
    step: 0,
  ),
  const Item(
    'solvent_cement',
    'Solvent cement, 100 cc',
    'can',
    ItemGroup.plumbing,
    plural: 'cans',
    price: 75,
    estimate: true,
  ),
  const Item(
    'teflon_tape',
    'Teflon tape',
    'roll',
    ItemGroup.plumbing,
    plural: 'rolls',
    price: 20,
    estimate: true,
  ),
  const Item(
    'cleanout',
    'Cleanout plug, 4"',
    'pc',
    ItemGroup.plumbing,
    plural: 'pcs',
    price: 150,
    estimate: true,
  ),

  // Plumbing fixtures.
  const Item(
    'toilet',
    'Water closet with tank',
    'set',
    ItemGroup.fixtures,
    plural: 'sets',
    price: 5500,
    estimate: true,
  ),
  const Item(
    'squat_toilet',
    'Squat toilet bowl',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 1200,
    estimate: true,
  ),
  const Item(
    'lavatory',
    'Lavatory (bathroom basin)',
    'set',
    ItemGroup.fixtures,
    plural: 'sets',
    price: 2500,
    estimate: true,
  ),
  const Item(
    'kitchen_sink',
    'Kitchen sink, stainless',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 2500,
    estimate: true,
  ),
  const Item(
    'faucet',
    'Faucet, chrome',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 700,
    estimate: true,
  ),
  const Item(
    'shower_set',
    'Shower set (head with arm or hose)',
    'set',
    ItemGroup.fixtures,
    plural: 'sets',
    price: 1500,
    estimate: true,
  ),
  const Item(
    'angle_valve',
    'Angle valve ½"',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 250,
    estimate: true,
  ),
  const Item(
    'flexible_hose',
    'Flexible hose ½"',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 150,
    estimate: true,
  ),
  const Item(
    'p_trap',
    'P-trap',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 250,
    estimate: true,
  ),
  const Item(
    'wax_ring',
    'Wax ring',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 120,
    estimate: true,
  ),
  const Item(
    'closet_bolts',
    'Closet bolt set',
    'set',
    ItemGroup.fixtures,
    plural: 'sets',
    price: 80,
    estimate: true,
  ),
  const Item(
    'floor_drain',
    'Floor drain 4" × 4", stainless',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 250,
    estimate: true,
  ),
  const Item(
    'shower_valve',
    'Shower valve',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 600,
    estimate: true,
  ),
  for (final l in waterTankLitres)
    Item(
      waterTankKey(l),
      'Water tank, polyethylene, ${_litres(l)} L',
      'pc',
      ItemGroup.fixtures,
      plural: 'pcs',
      price: _tankPrices[l]!,
      estimate: true,
    ),
  const Item(
    'float_valve',
    'Float valve, ¾"',
    'pc',
    ItemGroup.plumbing,
    plural: 'pcs',
    price: 450,
    estimate: true,
  ),
  const Item(
    'septic_tank',
    'Septic tank, polyethylene, 2,000 L, 2-chamber',
    'pc',
    ItemGroup.fixtures,
    plural: 'pcs',
    price: 25000,
    estimate: true,
  ),
];

String _litres(int l) =>
    l >= 1000 ? '${l ~/ 1000},${(l % 1000).toString().padLeft(3, '0')}' : '$l';
