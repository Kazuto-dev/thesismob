import 'items.dart';

// Concrete, masonry, steel, lumber, ceilings and roofing. Prices are
// Metro Manila retail in pesos; see docs/prices-and-costing.md for sources.

/// Deformed bar sizes sold in the Philippines, in millimetres.
const rebarSizes = [10, 12, 16, 20, 25];

/// Mass of a deformed bar per metre: d² ÷ 162.2 (PNS 49).
double rebarKgPerMetre(int mm) => mm * mm / 162.2;

/// Corrugated GI sheets are sold by the foot of length.
const corrugatedLengthsFt = [5, 6, 7, 8, 9, 10, 12];

/// Price of corrugated GI sheet per foot of length, gauge 26.
const _corrugatedPerFoot = 78.0;

String rebarKey(int mm) => 'rebar_$mm';
String corrugatedKey(int ft) => 'gi_corrugated_${ft}ft';
String plywoodKey(String mm) => 'plywood_$mm';
String marinePlywoodKey(String mm) => 'marine_plywood_$mm';

// 25 mm has no quoted price; it is priced at about ₱40/kg like the rest.
const _rebarPrices = {10: 150.0, 12: 215.0, 16: 390.0, 20: 600.0, 25: 940.0};

final List<Item> structureItems = [
  // Cement and aggregates.
  const Item(
    'cement_40kg',
    'Portland cement, 40 kg',
    'bag',
    ItemGroup.cement,
    plural: 'bags',
    price: 240,
  ),
  const Item(
    'sand',
    'Washed sand',
    'm³',
    ItemGroup.cement,
    step: 0.5,
    price: 1500,
  ),
  const Item(
    'gravel',
    'Gravel, ¾"',
    'm³',
    ItemGroup.cement,
    step: 0.5,
    price: 1800,
  ),
  const Item(
    'gravel_bedding',
    'Gravel bedding',
    'm³',
    ItemGroup.cement,
    step: 0.5,
    price: 1000,
    estimate: true,
  ),

  // Masonry.
  const Item(
    'chb_4',
    'Concrete hollow block 4"',
    'pc',
    ItemGroup.masonry,
    plural: 'pcs',
    price: 24,
  ),
  const Item(
    'chb_6',
    'Concrete hollow block 6"',
    'pc',
    ItemGroup.masonry,
    plural: 'pcs',
    price: 32,
  ),
  const Item(
    'chb_8',
    'Concrete hollow block 8"',
    'pc',
    ItemGroup.masonry,
    plural: 'pcs',
    price: 45,
    estimate: true,
  ),

  // Reinforcing steel.
  for (final mm in rebarSizes)
    Item(
      rebarKey(mm),
      'Deformed bar $mm mm × 6 m',
      'pc',
      ItemGroup.steel,
      plural: 'pcs',
      price: _rebarPrices[mm]!,
      estimate: mm == 25,
    ),
  const Item('tie_wire', 'Tie wire, #16 GI', 'kg', ItemGroup.steel, price: 85),

  // Lumber and boards.
  const Item(
    'plywood_6',
    'Plywood 6 mm (¼") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 400,
  ),
  const Item(
    'plywood_9',
    'Plywood 9 mm (⅜") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 550,
    estimate: true,
  ),
  const Item(
    'plywood_12',
    'Plywood 12 mm (½") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 700,
  ),
  const Item(
    'plywood_18',
    'Plywood 18 mm (¾") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 1150,
  ),
  const Item(
    'marine_plywood_6',
    'Marine plywood 6 mm (¼") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 500,
  ),
  const Item(
    'marine_plywood_9',
    'Marine plywood 9 mm (⅜") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 750,
    estimate: true,
  ),
  const Item(
    'marine_plywood_12',
    'Marine plywood 12 mm (½") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 1000,
  ),
  const Item(
    'marine_plywood_18',
    'Marine plywood 18 mm (¾") 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 1400,
  ),
  const Item(
    'coco_lumber',
    'Coco lumber, rough',
    'bd ft',
    ItemGroup.lumber,
    price: 38,
  ),
  const Item(
    'good_lumber',
    'Good lumber, S4S',
    'bd ft',
    ItemGroup.lumber,
    price: 70,
    estimate: true,
  ),
  const Item('nails', 'Common wire nails', 'kg', ItemGroup.lumber, price: 85),
  const Item(
    'fiber_cement_board',
    'Fiber cement board 4.5 mm 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 560,
  ),
  const Item(
    'gypsum_board',
    'Gypsum board 9 mm 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 500,
  ),

  // Ceiling framing.
  const Item(
    'metal_furring',
    'Metal furring, 5 m',
    'pc',
    ItemGroup.ceiling,
    plural: 'pcs',
    price: 125,
  ),
  const Item(
    'carrying_channel',
    'Carrying channel, 5 m',
    'pc',
    ItemGroup.ceiling,
    plural: 'pcs',
    price: 140,
  ),
  const Item(
    'wall_angle',
    'Wall angle, 3 m',
    'pc',
    ItemGroup.ceiling,
    plural: 'pcs',
    price: 60,
  ),
  const Item(
    'board_screws',
    'Board screws, box of 100',
    'box',
    ItemGroup.ceiling,
    plural: 'boxes',
    price: 120,
    estimate: true,
  ),
  const Item(
    'hanger_wire',
    'Hanger wire, #10 GI',
    'kg',
    ItemGroup.ceiling,
    price: 90,
    estimate: true,
  ),

  // Roofing and insulation.
  for (final ft in corrugatedLengthsFt)
    Item(
      corrugatedKey(ft),
      'Corrugated GI sheet, gauge 26, $ft ft',
      'sheet',
      ItemGroup.roofing,
      plural: 'sheets',
      price: ft * _corrugatedPerFoot,
    ),
  const Item(
    'longspan_m',
    'Long-span rib-type roofing, 0.4 mm',
    'm',
    ItemGroup.roofing,
    step: 0.01,
    price: 380,
  ),
  const Item(
    'tek_screw',
    'Tek screw 2½" with washer',
    'pc',
    ItemGroup.roofing,
    plural: 'pcs',
    price: 1.5,
  ),
  const Item(
    'umbrella_nail',
    'Umbrella nail with washer',
    'kg',
    ItemGroup.roofing,
    price: 120,
    estimate: true,
  ),
  const Item(
    'c_purlin',
    'C-purlin 2"×4" × 1.5 mm, 6 m',
    'pc',
    ItemGroup.roofing,
    plural: 'pcs',
    price: 780,
  ),
  const Item(
    'ridge_roll',
    'Ridge or hip roll, 2.4 m',
    'pc',
    ItemGroup.roofing,
    plural: 'pcs',
    price: 600,
  ),
  const Item(
    'gutter',
    'Gutter, pre-painted',
    'm',
    ItemGroup.roofing,
    price: 300,
  ),
  const Item(
    'downspout',
    'Downspout, PVC 3"',
    'm',
    ItemGroup.roofing,
    price: 120,
    estimate: true,
  ),
  const Item(
    'foam_roll_50',
    'PE foam insulation 1 × 50 m',
    'roll',
    ItemGroup.roofing,
    plural: 'rolls',
    price: 1800,
  ),
  const Item(
    'foam_roll_25',
    'PE foam insulation 1 × 25 m',
    'roll',
    ItemGroup.roofing,
    plural: 'rolls',
    price: 1000,
    estimate: true,
  ),
  const Item(
    'foil_tape',
    'Aluminium foil tape, 50 m',
    'roll',
    ItemGroup.roofing,
    plural: 'rolls',
    price: 250,
    estimate: true,
  ),
];
