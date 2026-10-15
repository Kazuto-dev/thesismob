import 'dart:math' as math;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';

/// Paint "gallon" cans in the Philippines hold 4 litres.
const litresPerGallon = 4.0;

/// Waste allowance on paint for rollers, trays and touch-ups.
const paintWaste = 0.10;

/// Coverage of one coat of primer, m² per 4 L.
const primerCoverage = 25.0;

/// Masonry neutralizer mixed 1:16 with water covers about 20 m² per 4 L of
/// solution, so 1 L of concentrate covers about 85 m² (Boysen B-44).
const neutralizerCoverage = 85.0;

/// Spot putty on new masonry covers about 25 m² per 4 L (Boysen B-7311).
const puttyCoverage = 25.0;

/// A 20 kg bag of skim coat covers about 18 m² at 1 mm (Bostik, Sika).
const skimCoverage = 18.0;

/// One sheet of sandpaper for every 8 m² of each sanding pass.
const sandpaperCoverage = 8.0;

/// Enamel and its primer are thinned about 1 part in 8, and each job uses
/// about half a litre more to clean brushes and rollers.
const thinnerShare = 1 / 8;
const thinnerCleanup = 0.5;

/// Corrugated GI sheets are 0.80 m wide; their end laps are 0.25 m.
const corrugatedEndLap = 0.25;

/// Long-span sheets are cut 5 cm longer than the slope.
const longSpanCutAllowance = 0.05;

/// Extra roofing cut for the diagonal edges along the hips.
const hipWaste = 0.10;

/// A 6 m C-purlin joined over a truss covers about 5.8 m of a purlin line.
const purlinCover = 5.8;

/// Ridge and hip rolls are 2.4 m long and lap 0.15 m.
const ridgeRollCover = 2.4 - 0.15;

/// Tek screws per m² of roof: about 4 per sheet at every purlin, plus the
/// extra screws at the eaves and ridge.
const longSpanScrews = 7.0;
const corrugatedScrews = 8.0;

/// One downspout for every 10 m of gutter.
const gutterPerDownspout = 10.0;

/// Height of a downspout when none is entered, in metres.
const downspoutHeight = 3.0;

/// Extra length cut from a carpet roll for trimming each drop.
const carpetTrim = 0.10;

/// Extra length on each wallpaper strip for trimming top and bottom.
const wallpaperTrim = 0.10;

/// Skirting cut from the floor tiles is 10 cm high.
const skirtingHeight = 0.10;

/// A tile mortar bed is 25 mm of Class B mortar. Neat cement for the
/// slurry and pointing adds 0.025 bags per m²; both get 5% waste.
const tileBedThickness = 0.025;
const tileBedSlurry = 0.025;
const tileBedWaste = 0.05;

/// Cross spacers per tile, edge pieces included.
const spacersPerTile = 1.5;

const _paintNames = {
  'latex': 'latex flat',
  'gloss': 'latex semi-gloss',
  'enamel': 'enamel',
};

const _paintKeys = {
  'latex': 'paint_latex',
  'gloss': 'paint_latex_gloss',
  'enamel': 'paint_enamel',
};

final paint = MaterialSpec(
  id: 'paint',
  name: 'Paint',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/paint.png',
  blurb: '4-litre gallons by coats, with primer and surface prep',
  keywords: const [
    'pintura',
    'latex',
    'enamel',
    'primer',
    'wall paint',
    'neutralizer',
    'skim coat',
    'masilya',
    'putty',
  ],
  priceRef: (s) {
    final key = _paintKeys[s['type']];
    return key == null ? null : PriceRef(key);
  },
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Surface length',
      typical: (min: 0.3, max: 300),
      unit: 'm',
      hint: 'Add up the lengths of all walls to paint',
      max: 10000,
    ),
    NumberField(
      id: 'height',
      label: 'Surface height',
      typical: (min: 0.2, max: 12),
      unit: 'm',
      max: 1000,
    ),
    openingsField,
    NumberField(
      id: 'price',
      label: 'Price per gallon (4 L)',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Paint',
      initial: 'latex',
      helper: 'Coverage per coat for a 4 L gallon',
      options: [
        ChoiceOption('latex', 'Latex flat, 30 m²', 30),
        ChoiceOption('gloss', 'Latex semi-gloss, 30 m²', 30),
        ChoiceOption('enamel', 'Enamel, 25 m²', 25),
      ],
    ),
    const ChoiceField(
      id: 'faces',
      label: 'Faces',
      initial: '1',
      helper: 'A partition wall painted on both sides has twice the area',
      options: [
        ChoiceOption('1', 'One face', 1),
        ChoiceOption('2', 'Both faces of the wall', 2),
      ],
    ),
    const ChoiceField(
      id: 'coats',
      label: 'Finish coats',
      initial: '2',
      options: [
        ChoiceOption('1', '1 coat', 1),
        ChoiceOption('2', '2 coats', 2),
        ChoiceOption('3', '3 coats', 3),
      ],
    ),
    const ChoiceField(
      id: 'prep',
      label: 'Surface',
      initial: 'masonry',
      helper: 'Sets the preparation materials',
      options: [
        ChoiceOption('repaint', 'Repaint (no prep)'),
        ChoiceOption('masonry', 'New masonry'),
        ChoiceOption('wood', 'Wood or metal'),
      ],
    ),
    ChoiceField(
      id: 'skim',
      label: 'Skim coat',
      initial: '0',
      helper: 'A 1 mm cement finish over the plaster for a smooth wall',
      options: const [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('1', '1 coat', 1),
        ChoiceOption('2', '2 coats', 2),
      ],
      visibleWhen: (s) => s['prep'] == 'masonry',
    ),
    const ChoiceField(
      id: 'primer',
      label: 'Primer coat',
      initial: 'yes',
      helper: 'New or bare surfaces need one coat of primer first',
      options: [
        ChoiceOption('yes', 'Include primer', 1),
        ChoiceOption('no', 'No primer', 0),
      ],
    ),
  ],
  compute: (input) {
    final gross = input['length'] * input['height'];
    final openings = input.optional('openings');
    final net = gross - openings;
    if (net <= 0) {
      throw ArgumentError('Doors and windows must be smaller than the surface');
    }
    final faces = input.choice('faces').value;
    final area = net * faces;
    final type = input.choice('type');
    final coats = input.choice('coats').value;
    final litres =
        area * coats / (type.value / litresPerGallon) * (1 + paintWaste);
    final gallons = ceilCount(litres / litresPerGallon);
    final primerLitres = input.chose('primer', 'yes')
        ? area / (primerCoverage / litresPerGallon) * (1 + paintWaste)
        : 0.0;
    final prep = input.choice('prep').id;
    final masonry = prep == 'masonry';
    final skimCoats = masonry ? input.choice('skim').value : 0.0;
    // One sanding pass for each putty or skim coat layer on masonry, and
    // one on bare wood or metal before the primer.
    final passes = switch (prep) {
      'masonry' => 1 + skimCoats,
      'wood' => 1.0,
      _ => 0.0,
    };
    final enamel = type.id == 'enamel';
    final thinner = enamel
        ? (litres + primerLitres) * thinnerShare + thinnerCleanup
        : 0.0;
    final coatLabel = coats == 1 ? '1 coat' : '${formatNumber(coats)} coats';
    return CalcResult(
      label: 'Paint, ${_paintNames[type.id]}, $coatLabel',
      area: area,
      quantity: gallons.toDouble(),
      unit: QuantityUnit.gallons,
      unitPrice: input['price'],
      itemKey: _paintKeys[type.id],
      details: [
        if (openings > 0) ...[
          ResultDetail('Surface area', formatArea(gross)),
          ResultDetail('Less doors and windows', '−${formatArea(openings)}'),
        ],
        if (faces > 1) ...[
          ResultDetail('Area of one face', formatArea(net)),
          const ResultDetail('Both faces', '× 2'),
        ],
        ResultDetail('Area to paint', formatArea(area)),
        ResultDetail('Coverage per coat', '${formatArea(type.value)} per 4 L'),
        ResultDetail(
          'Paint for $coatLabel, +10% waste',
          '${formatNumber(roundUp(litres, 1))} L',
        ),
        ResultDetail(
          'Gallons of 4 L',
          formatQuantity(gallons.toDouble(), QuantityUnit.gallons),
        ),
      ],
      companions: [
        if (primerLitres > 0) buy('primer', primerLitres / litresPerGallon),
        if (masonry) ...[
          buy('neutralizer', area / neutralizerCoverage),
          buy('putty', area / puttyCoverage),
        ],
        if (skimCoats > 0) buy('skim_coat', area * skimCoats / skimCoverage),
        if (passes > 0) buy('sandpaper', area * passes / sandpaperCoverage),
        if (thinner > 0) buy('paint_thinner', thinner),
      ],
      note: switch (prep) {
        'masonry' =>
          'New masonry: ${skimCoats > 0 ? 'skim coat and sand, ' : ''}'
              'neutralize and rinse, prime, spot putty and sand, then paint.',
        'wood' => 'Sand bare wood or metal before the primer.',
        _ => null,
      },
    );
  },
  definitions: const [
    InfoSection(
      'Gallon',
      'Paint in the Philippines is sold in 1 L quarts, 4 L gallons and 16 L '
          'pails. A "gallon" here is 4 litres, not the 3.785 L US gallon.',
    ),
    InfoSection(
      'Surface length and height',
      'For walls, add up the lengths of the walls and use the floor-to-'
          'ceiling height. For a ceiling, use the room length and width.',
    ),
    InfoSection(
      'Faces',
      'Choose both faces when a wall is painted on both sides, such as a '
          'partition between two rooms. Doors and windows are left out of '
          'each face.',
    ),
    InfoSection(
      'Coverage',
      'How much surface one coat from a 4 L gallon covers. Boysen gives '
          'about 30–35 m² for both latex and quick-drying enamel; retailers '
          'quote as little as 20–25 m² for enamel on rough surfaces. The app '
          'uses lower figures, since real walls take more paint.',
    ),
    InfoSection(
      'Coats and primer',
      'New concrete and bare wood get one coat of primer, then two finish '
          'coats. Repainting a sound surface in a similar colour may need '
          'only one finish coat and no primer.',
    ),
    InfoSection(
      'Surface preparation',
      'New masonry is washed with neutralizer to stop the lime in fresh '
          'cement from spoiling the paint, then filled with putty and '
          'sanded. A skim coat is a thin cement finish for a smooth wall. '
          'Bare wood and metal are sanded before the primer.',
    ),
    InfoSection(
      'Thinner',
      'Enamel and its primer are thinned with paint thinner, which also '
          'cleans the brushes. Latex is thinned with water.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area to paint',
      'Multiply the length by the height, subtract doors and windows, and '
          'multiply by the number of faces.',
      formula: 'area = (length × height − openings) × faces',
    ),
    InfoSection(
      'Paint',
      'Divide the area by the coverage per litre for each coat, then add 10% '
          'for rollers, trays and touch-ups.',
      formula: 'litres = area × coats ÷ (coverage ÷ 4) × 1.10',
    ),
    InfoSection(
      'Gallons',
      'Divide by 4 litres and round up to whole gallons.',
      formula: 'gallons = round up(litres ÷ 4)',
    ),
    InfoSection(
      'Primer',
      'One coat of primer covers about 25 m² per 4 L, plus the same 10%.',
      formula:
          'primer litres = area ÷ (25 ÷ 4) × 1.10\n'
          'primer gallons = round up(primer litres ÷ 4)',
    ),
    InfoSection(
      'New masonry',
      '1 L of neutralizer covers about 85 m². Spot putty covers about 25 m² '
          'per 4 L gallon. A 20 kg bag of skim coat covers about 18 m² for '
          'each 1 mm coat.',
      formula:
          'neutralizer = round up(area ÷ 85) litres\n'
          'putty = round up(area ÷ 25) gallons\n'
          'skim coat = round up(area × coats ÷ 18) bags',
    ),
    InfoSection(
      'Sandpaper',
      'One sheet for every 8 m² of each sanding pass: one pass for the '
          'putty and one for each skim coat on masonry, or one pass on bare '
          'wood or metal.',
      formula: 'sheets = round up(area × passes ÷ 8)',
    ),
    InfoSection(
      'Thinner',
      'For enamel, one eighth of the enamel and primer, plus 0.5 L for '
          'cleaning, rounded up to whole litres.',
      formula: 'thinner = round up((enamel + primer litres) ÷ 8 + 0.5)',
    ),
    InfoSection(
      'Cost',
      'Multiply the gallons of finish paint by the price per gallon. Primer '
          'and preparation materials are priced from your price list and '
          'added to the total.',
      formula: 'cost = gallons × price per gallon + other materials',
    ),
  ],
  references: const [
    'https://www.boysen.com.ph/products/boysen-permacoat-latex',
    'https://www.boysen.com.ph/products/boysen-quick-drying-enamel',
    'https://www.boysen.com.ph/products/boysen-masonry-neutralizer-b-44',
    'https://www.boysen.com.ph/products/boysen-masonry-putty-b-7311/',
    'https://phl.sika.com/dms/getdocument.get/ba888e31-3994-4be5-a054-99e013c85dff_ph01/pds-sikawall-110superfineskimcoat.pdf',
  ],
);

/// Metres of 10 cm skirting cut from one tile, strips taken along
/// whichever side gives more.
double skirtingPerTile(double a, double b) {
  int strips(double side) => (side / skirtingHeight + 1e-9).floor();
  return math.max(a * strips(b), b * strips(a));
}

final tiles = MaterialSpec(
  id: 'tiles',
  name: 'Tiles',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/tiles.png',
  blurb: 'Floor or wall tiles with skirting, adhesive or mortar, and grout',
  keywords: const [
    'tile',
    'baldosa',
    'floor',
    'sahig',
    'wall tile',
    'ceramic',
    'skirting',
    'grout',
  ],
  priceRef: (s) {
    final size = s['size'];
    if (!tileSizes.any((t) => t.id == size)) return null;
    return PriceRef(s['buy'] == 'box' ? tileBoxKey(size!) : tileKey(size!));
  },
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Surface length',
      typical: (min: 0.3, max: 300),
      unit: 'm',
      max: 10000,
    ),
    const NumberField(
      id: 'width',
      label: 'Surface width',
      typical: (min: 0.2, max: 60),
      unit: 'm',
      max: 10000,
    ),
    const NumberField(
      id: 'skirting',
      label: 'Skirting length',
      typical: (min: 0.3, max: 300),
      unit: 'm',
      hint: 'Optional. Room perimeter less doors, for 10 cm skirting',
      optional: true,
      max: 10000,
    ),
    const NumberField(
      id: 'perBox',
      label: 'Tiles per box',
      unit: 'pcs',
      hint: 'Optional. Printed on the box',
      integer: true,
      optional: true,
      max: 1000,
    ),
    priceField('Price per tile', visibleWhen: (s) => s['buy'] != 'box'),
    priceField(
      'Price per box',
      id: 'boxPrice',
      visibleWhen: (s) => s['buy'] == 'box',
    ),
  ],
  choices: [
    ChoiceField(
      id: 'size',
      label: 'Tile size',
      options: [
        for (final s in tileSizes) ChoiceOption(s.id, s.label, s.a * s.b),
      ],
    ),
    const ChoiceField(
      id: 'buy',
      label: 'Buy',
      initial: 'piece',
      helper: 'Home centres sell most floor tiles by the box',
      options: [
        ChoiceOption('piece', 'By the piece'),
        ChoiceOption('box', 'By the box'),
      ],
    ),
    const ChoiceField(
      id: 'layout',
      label: 'Layout',
      initial: 'straight',
      helper: 'Diagonal layouts cut more tiles at the edges',
      options: [
        ChoiceOption('straight', 'Straight, +10%', 0.10),
        ChoiceOption('diagonal', 'Diagonal, +15%', 0.15),
      ],
    ),
    const ChoiceField(
      id: 'bed',
      label: 'Setting bed',
      initial: 'adhesive',
      helper: 'Thin-set adhesive, or a 25 mm bed of cement and sand',
      options: [
        ChoiceOption('adhesive', 'Tile adhesive'),
        ChoiceOption('mortar', 'Cement mortar bed'),
      ],
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    final size = tileSizes.firstWhere((s) => s.id == input.choice('size').id);
    // Edge tiles count as whole tiles; lay them the way that needs fewer.
    final across = ceilCount(length / size.a) * ceilCount(width / size.b);
    final turned = ceilCount(length / size.b) * ceilCount(width / size.a);
    final floor = math.min(across, turned);
    final rows = across <= turned
        ? (ceilCount(length / size.a), ceilCount(width / size.b))
        : (ceilCount(length / size.b), ceilCount(width / size.a));
    final skirting = input.optional('skirting');
    final skirtingTiles = skirting > 0
        ? ceilCount(skirting / skirtingPerTile(size.a, size.b))
        : 0;
    final layout = input.choice('layout');
    final count = withWaste(floor + skirtingTiles, layout.value);
    final perBox = input.optional('perBox') > 0
        ? input.optional('perBox').round()
        : size.box;
    final boxes = ceilCount(count.total / perBox);
    final byBox = input.chose('buy', 'box');
    // Bed and grout cover the floor and the face of the skirting.
    final bedArea = area + skirting * skirtingHeight;
    final mortar = input.chose('bed', 'mortar');
    // Adhesive: about 3 kg/m² for small tiles, 5 kg/m² from 40 × 40 cm.
    final adhesiveRate = math.max(size.a, size.b) <= 0.30 ? 3.0 : 5.0;
    // Grout for 3 mm joints, as deep as the tile (8–10 mm).
    final depth = math.max(size.a, size.b) <= 0.30 ? 8.0 : 10.0;
    final aMm = size.a * 1000;
    final bMm = size.b * 1000;
    final groutKg = bedArea * (aMm + bMm) / (aMm * bMm) * 3 * depth * 1.6;
    return CalcResult(
      label: byBox
          ? 'Tiles ${size.label}, box of $perBox'
          : 'Tiles ${size.label}',
      area: area,
      quantity: byBox ? boxes.toDouble() : count.total.toDouble(),
      unit: byBox ? QuantityUnit.boxes : QuantityUnit.pieces,
      unitPrice: byBox ? input['boxPrice'] : input['price'],
      itemKey: byBox ? tileBoxKey(size.id) : tileKey(size.id),
      details: [
        ResultDetail('Area to tile', formatArea(area)),
        ResultDetail('Tiles in rows', '${rows.$1} × ${rows.$2} = $floor'),
        if (skirtingTiles > 0)
          ResultDetail(
            'Skirting ${formatLength(skirting)}, 10 cm high',
            '+${formatQuantity(skirtingTiles.toDouble(), QuantityUnit.pieces)}',
          ),
        ...wasteDetail(count, layout.value, QuantityUnit.pieces),
        if (byBox)
          ResultDetail(
            'Tiles to buy',
            formatQuantity(count.total.toDouble(), QuantityUnit.pieces),
          ),
        ResultDetail('Boxes of $perBox', formatCount(boxes, 'box', 'boxes')),
      ],
      companions: [
        if (mortar) ...[
          buy(
            'cement_40kg',
            bedArea *
                (tileBedThickness * mortarClassB.cement + tileBedSlurry) *
                (1 + tileBedWaste),
          ),
          buy(
            'sand',
            bedArea * tileBedThickness * mortarClassB.sand * (1 + tileBedWaste),
          ),
        ] else
          buy('tile_adhesive', bedArea * adhesiveRate / 25),
        buy('tile_grout', groutKg / 2),
        buy('tile_spacers', count.total * spacersPerTile / 100),
      ],
      note: mortar
          ? 'Cement and sand are for a 25 mm bed of Class B (1:3) mortar.'
          : null,
    );
  },
  definitions: const [
    InfoSection(
      'Tile size',
      'Common sizes in the Philippines are 20 × 20, 20 × 30 and 30 × 30 cm '
          'for walls and small rooms, and 30 × 60, 40 × 40 and 60 × 60 cm '
          'for floors.',
    ),
    InfoSection(
      'Surface length and width',
      'The floor or wall to tile, in metres.',
    ),
    InfoSection(
      'Skirting',
      'A 10 cm strip of tile along the foot of the walls, cut from the floor '
          'tiles. Enter the room perimeter less the door openings.',
    ),
    InfoSection(
      'By the piece or by the box',
      'Home centres price floor tiles per box; small hardware stores often '
          'sell them per piece. Usually 4 tiles to a box for 60 × 60, 6 for '
          '40 × 40, 8 for 30 × 60, 16 for 30 × 30 and 25 for 20 × 20 cm. '
          'Enter the number printed on your box if it differs.',
    ),
    InfoSection(
      'Layout',
      'Tiles laid straight, parallel to the walls, waste about 10% in cuts. '
          'Diagonal layouts cut every edge tile and waste about 15%.',
    ),
    InfoSection(
      'Setting bed',
      'Tile adhesive (thin-set) is spread with a notched trowel. A mortar '
          'bed is 25 mm of Class B mortar (1 part cement to 3 parts sand) '
          'with a cement slurry on top.',
    ),
    InfoSection(
      'Grout and spacers',
      'Grout fills the 3 mm joints and comes in 2 kg packs. Plastic spacers '
          'keep the joints even, about 1.5 per tile, in packs of 100.',
    ),
  ],
  solution: const [
    InfoSection(
      'Tiles in rows',
      'Count the tiles along each side, rounding up because cut edge tiles '
          'are whole tiles bought. Try the tile both ways round and keep the '
          'smaller count.',
      formula: 'tiles = round up(length ÷ tile) × round up(width ÷ tile)',
    ),
    InfoSection(
      'Skirting',
      'Each tile is cut into 10 cm strips. A 60 × 60 cm tile gives 6 strips '
          'of 0.60 m, or 3.6 m of skirting.',
      formula:
          'metres per tile = tile length × round down(tile width ÷ 0.10)\n'
          'skirting tiles = round up(skirting ÷ metres per tile)',
    ),
    InfoSection(
      'Waste and boxes',
      'Add 10% (straight) or 15% (diagonal), rounded up, then divide by the '
          'tiles per box.',
      formula:
          'total = tiles + round up(tiles × waste)\n'
          'boxes = round up(total ÷ tiles per box)',
    ),
    InfoSection(
      'Adhesive',
      'About 3 kg/m² with a 6 mm notched trowel for tiles up to 30 × 30 cm, '
          'about 5 kg/m² for larger tiles. Bags hold 25 kg. The skirting '
          'adds its face, length × 0.10 m.',
      formula: 'bags = round up(area × kg per m² ÷ 25)',
    ),
    InfoSection(
      'Mortar bed',
      'Class B mortar takes 12 bags of cement and 1 m³ of sand per m³. A '
          '25 mm bed is 0.025 m³ per m², plus 0.025 bags of cement for the '
          'slurry, and 5% waste.',
      formula:
          'cement = area × (0.025 × 12 + 0.025) × 1.05 bags\n'
          'sand = area × 0.025 × 1.05 m³',
    ),
    InfoSection(
      'Grout',
      'Joint volume per m² times the density of grout (1.6 kg/L), with tile '
          'sides, joint width (3 mm) and depth in millimetres, in 2 kg packs.',
      formula:
          'kg = area × (a + b) ÷ (a × b) × joint × depth × 1.6\n'
          'packs = round up(kg ÷ 2)',
    ),
    InfoSection(
      'Spacers',
      'About 1.5 spacers per tile, in packs of 100.',
      formula: 'packs = round up(total tiles × 1.5 ÷ 100)',
    ),
    InfoSection(
      'Cost',
      'Multiply the tiles by the price per tile, or the boxes by the price '
          'per box. Adhesive or mortar, grout and spacers are priced from '
          'your price list and added to the total.',
      formula: 'cost = tiles × price per tile, or boxes × price per box',
    ),
  ],
  references: const [
    'https://shop.wilcon.com.ph/tiles',
    'https://www.bostik.com/files/live/sites/shared_bostik/files/import-philippines/bostik-fixall-excel-tds-fa-rev1.pdf',
    'https://philconprices.com/tag/tiling-work-per-square-meter/',
    'https://wallsandfloors.co.uk/blog/how-to-use-tile-spacers',
  ],
);

/// The roof slope measured on a plan: rise per 12 of run. The value is the
/// rise ÷ run.
const _pitchOptions = [
  ChoiceOption('3', '3:12', 3 / 12),
  ChoiceOption('4', '4:12', 4 / 12),
  ChoiceOption('5', '5:12', 5 / 12),
  ChoiceOption('6', '6:12', 6 / 12),
  ChoiceOption('8', '8:12', 8 / 12),
  ChoiceOption('12', '12:12', 12 / 12),
];

final roof = MaterialSpec(
  id: 'roof',
  name: 'Roofing Sheets',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/roof.png',
  blurb: 'Corrugated or long-span sheets, with purlins, screws and gutters',
  keywords: const [
    'yero',
    'GI sheet',
    'long span',
    'bubong',
    'corrugated',
    'rib type',
    'hip roof',
    'purlin',
    'alulod',
    'gutter',
  ],
  priceRef: (s) {
    if (s['type'] == 'longspan') return const PriceRef('longspan_m');
    final ft = int.tryParse(s['sheetLength'] ?? '');
    return ft == null ? null : PriceRef(corrugatedKey(ft));
  },
  numbers: [
    const NumberField(
      id: 'eave',
      label: 'Roof length',
      typical: (min: 1, max: 100),
      unit: 'm',
      hint: 'Along the eaves, overhangs included',
      max: 10000,
    ),
    NumberField(
      id: 'width',
      label: 'Roof width',
      typical: (min: 1, max: 100),
      unit: 'm',
      hint: 'Across the plan, overhangs included',
      max: 10000,
      visibleWhen: (s) => s['shape'] == 'hip',
    ),
    NumberField(
      id: 'rafter',
      label: 'Rafter length',
      typical: (min: 0.5, max: 20),
      unit: 'm',
      hint: 'From the eaves to the ridge, overhang included',
      max: 1000,
      visibleWhen: (s) => s['shape'] != 'hip',
    ),
    NumberField(
      id: 'downspout',
      label: 'Downspout height',
      typical: (min: 1, max: 15),
      unit: 'm',
      hint: 'Optional. From the gutter to the ground, 3 m if empty',
      initial: '3',
      optional: true,
      max: 100,
      visibleWhen: (s) => s['gutter'] == 'eaves',
    ),
    priceField('Price per sheet', visibleWhen: (s) => s['type'] != 'longspan'),
    priceField(
      'Price per metre',
      id: 'priceMetre',
      visibleWhen: (s) => s['type'] == 'longspan',
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Roofing',
      initial: 'corrugated',
      leading: true,
      options: [
        ChoiceOption('corrugated', 'Corrugated GI'),
        ChoiceOption('longspan', 'Long-span rib type'),
      ],
    ),
    const ChoiceField(
      id: 'shape',
      label: 'Roof shape',
      initial: 'gable',
      leading: true,
      helper: 'A shed roof has one side, a gable two, a hip roof four',
      options: [
        ChoiceOption('gable', 'Gable'),
        ChoiceOption('shed', 'Shed'),
        ChoiceOption('hip', 'Hip'),
      ],
    ),
    ChoiceField(
      id: slopeField.id,
      label: slopeField.label,
      initial: slopeField.initial,
      helper: slopeField.helper,
      options: slopeField.options,
      visibleWhen: (s) => s['shape'] != 'hip',
    ),
    ChoiceField(
      id: 'pitch',
      label: 'Roof pitch',
      initial: '4',
      helper: 'Rise per 12 of run; 4:12 is about 18°',
      options: _pitchOptions,
      visibleWhen: (s) => s['shape'] == 'hip',
    ),
    ChoiceField(
      id: 'sheetLength',
      label: 'Sheet length',
      initial: '8',
      options: [
        for (final ft in corrugatedLengthsFt)
          ChoiceOption('$ft', '$ft ft', ft * 0.3048),
      ],
      visibleWhen: (s) => s['type'] != 'longspan',
    ),
    ChoiceField(
      id: 'sideLap',
      label: 'Side lap',
      initial: '1.5',
      helper: 'Corrugations neighbouring 0.80 m sheets overlap',
      options: const [
        ChoiceOption('1.5', '1½ (0.70 m cover)', 0.70),
        ChoiceOption('2.5', '2½ (0.60 m cover)', 0.60),
      ],
      visibleWhen: (s) => s['type'] != 'longspan',
    ),
    ChoiceField(
      id: 'cover',
      label: 'Effective width',
      initial: '1.00',
      helper: 'Printed in the product sheet; most profiles cover about 1 m',
      options: const [
        ChoiceOption('1.00', '1.00 m', 1.00),
        ChoiceOption('1.07', '1.07 m', 1.07),
        ChoiceOption('0.98', '0.98 m', 0.98),
      ],
      visibleWhen: (s) => s['type'] == 'longspan',
    ),
    const ChoiceField(
      id: 'purlins',
      label: 'Purlins',
      initial: 'no',
      helper: 'Adds 2" × 4" C-purlins, 6 m long',
      options: [
        ChoiceOption('no', 'Not included'),
        ChoiceOption('yes', 'Steel C-purlins'),
      ],
    ),
    ChoiceField(
      id: 'spacing',
      label: 'Purlin spacing',
      initial: '0.60',
      helper: '0.60 m is usual, and safer in typhoon areas',
      options: const [
        ChoiceOption('0.45', '0.45 m', 0.45),
        ChoiceOption('0.60', '0.60 m', 0.60),
        ChoiceOption('0.80', '0.80 m', 0.80),
        ChoiceOption('1.00', '1.00 m', 1.00),
      ],
      visibleWhen: (s) => s['purlins'] == 'yes',
    ),
    const ChoiceField(
      id: 'gutter',
      label: 'Gutters',
      initial: 'none',
      options: [
        ChoiceOption('none', 'None'),
        ChoiceOption('eaves', 'Along the eaves'),
      ],
    ),
  ],
  compute: (input) {
    final shape = input.choice('shape').id;
    final hip = shape == 'hip';
    final longSpan = input.chose('type', 'longspan');
    final double length;
    final double slope;
    final double area;
    final double ridge;
    final double hips;
    final double eaves;
    final int sides;
    final shapeDetail = <ResultDetail>[];
    if (hip) {
      length = math.max(input['eave'], input['width']);
      final width = math.min(input['eave'], input['width']);
      final pitch = input.choice('pitch');
      final p = pitch.value;
      final slopeFactor = math.sqrt(1 + p * p);
      final hipFactor = math.sqrt(2 + p * p);
      final run = width / 2;
      slope = run * slopeFactor;
      area = length * width * slopeFactor;
      ridge = length - width;
      hips = 4 * run * hipFactor;
      eaves = 2 * (length + width);
      // All four faces add up to a gable on the same plan and pitch.
      sides = 2;
      shapeDetail.addAll([
        ResultDetail('Plan area', formatArea(roundUp(length * width))),
        ResultDetail(
          'Slope factor (${pitch.label})',
          '\u00D7\u00A0${formatNumber(roundUp(slopeFactor, 3))}',
        ),
        ResultDetail('Roof area', formatArea(roundUp(area))),
        ResultDetail('Rafter along the slope', formatLength(roundUp(slope))),
        ResultDetail('Ridge', formatLength(roundUp(ridge))),
        ResultDetail(
          '4 hips of ${formatLength(roundUp(run * hipFactor))}',
          formatLength(roundUp(hips)),
        ),
      ]);
    } else {
      length = input['eave'];
      final factor = input.choice('measured').value;
      slope = input['rafter'] * factor;
      sides = shape == 'shed' ? 1 : 2;
      area = length * slope * sides;
      ridge = sides == 2 ? length : 0;
      hips = 0;
      eaves = length * sides;
      if (factor != 1) {
        shapeDetail.add(
          ResultDetail(
            'Slope length (\u00D7\u00A0${formatNumber(factor)})',
            formatLength(roundUp(slope)),
          ),
        );
      }
    }
    final sidesDetail = [
      if (hip)
        const ResultDetail('Four hip faces, counted as two sides', '× 2')
      else if (sides == 2)
        const ResultDetail('Roof sides', '× 2'),
    ];
    final purlinSpacing = input.chose('purlins', 'yes')
        ? input.choice('spacing').value
        : 0.0;
    final purlinLines = purlinSpacing > 0
        ? ceilCount(slope / purlinSpacing) + 1
        : 0;
    final purlins = purlinLines * ceilCount(length / purlinCover) * sides;
    final gutter = input.chose('gutter', 'eaves');
    final downspouts = gutter ? ceilCount(eaves / gutterPerDownspout) : 0;
    final entered = input.optional('downspout');
    final drop = entered > 0 ? entered : downspoutHeight;
    final companions = [
      if (purlins > 0)
        buy(
          'c_purlin',
          purlins.toDouble(),
          label: _named('c_purlin', '$purlinLines lines per side'),
        ),
      buy('tek_screw', area * (longSpan ? longSpanScrews : corrugatedScrews)),
      if (ridge + hips > 0) buy('ridge_roll', (ridge + hips) / ridgeRollCover),
      if (gutter) ...[
        buy('gutter', eaves),
        buy(
          'downspout',
          downspouts * drop,
          label: _named('downspout', '$downspouts × ${formatLength(drop)}'),
        ),
      ],
    ];
    final hipNote = hip
        ? ' Hip faces are cut from full sheets, so 10% is added.'
        : '';
    if (longSpan) {
      final cover = input.choice('cover').value;
      final columns = ceilCount(length / cover);
      final pieces = columns * sides;
      final cut = slope + longSpanCutAllowance;
      final straight = pieces * cut;
      final metres = roundUp(hip ? straight * (1 + hipWaste) : straight);
      return CalcResult(
        label: 'Long-span roofing, ${formatLength(cover)} cover',
        area: area,
        quantity: metres,
        unit: QuantityUnit.metres,
        unitPrice: input['priceMetre'],
        itemKey: 'longspan_m',
        details: [
          ...shapeDetail,
          ResultDetail(
            'Sheets per side (${formatLength(cover)} cover)',
            formatCount(columns, 'sheet'),
          ),
          ...sidesDetail,
          ResultDetail('Cut length (+5 cm)', formatLength(roundUp(cut))),
          ResultDetail(
            '${formatCount(pieces, 'sheet')} × ${formatLength(roundUp(cut))}',
            formatLength(roundUp(straight)),
          ),
          if (hip) const ResultDetail('Hip cutting waste (10%)', '× 1.10'),
        ],
        companions: companions,
        note:
            'Long-span sheets are cut to length and sold by the metre.'
            '$hipNote',
      );
    }
    final cover = input.choice('sideLap').value;
    final sheetLength = input.choice('sheetLength');
    final columns = ceilCount(length / cover);
    final rows = slope <= sheetLength.value + 1e-9
        ? 1
        : ceilCount(
            (slope - corrugatedEndLap) / (sheetLength.value - corrugatedEndLap),
          );
    final count = withWaste(columns * rows * sides, hip ? hipWaste : 0);
    return CalcResult(
      label:
          'Corrugated GI, ${sheetLength.label} '
          '(${formatLength(roundUp(sheetLength.value))})',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      itemKey: corrugatedKey(int.parse(sheetLength.id)),
      details: [
        ...shapeDetail,
        ResultDetail(
          'Sheets along the eaves (${formatLength(cover)} cover)',
          formatCount(columns, 'sheet'),
        ),
        ResultDetail(
          'Sheets up the slope (0.25 m end lap)',
          formatCount(rows, 'sheet'),
        ),
        ...sidesDetail,
        if (count.extra > 0)
          ResultDetail(
            'Hip cutting waste (10%)',
            '+${formatCount(count.extra, 'sheet')}',
          ),
      ],
      companions: companions,
      note: hip ? hipNote.trim() : null,
    );
  },
  definitions: const [
    InfoSection(
      'Corrugated GI',
      'Galvanised iron sheets with rounded waves, 0.80 m wide and 5 to 12 ft '
          'long. Neighbouring sheets overlap by 1½ or 2½ corrugations, '
          'leaving 0.70 or 0.60 m of cover.',
    ),
    InfoSection(
      'Long-span rib type',
      'Pre-painted sheets roll-formed to any length on order, so one sheet '
          'runs from eaves to ridge. They cover about 1 m each and are priced '
          'per linear metre.',
    ),
    InfoSection(
      'Roof shape',
      'A shed roof slopes one way. A gable roof has two sides meeting at a '
          'ridge. A hip roof slopes on all four sides, with hips running '
          'from the corners up to the ridge.',
    ),
    InfoSection(
      'Roof length and rafter length',
      'Roof length runs along the eaves. Rafter length runs from the eaves '
          'up to the ridge, overhang included. Measured from a plan, the '
          'rafter length is horizontal, so choose the pitch to convert it. '
          'For a hip roof, enter the length and width of the plan with the '
          'overhangs, and the pitch.',
    ),
    InfoSection(
      'End lap',
      'Where two corrugated sheets meet up the slope, the upper one overlaps '
          'the lower by 0.25 m so water cannot get in.',
    ),
    InfoSection(
      'Purlins',
      'Steel C-purlins run along the roof across the rafters or trusses and '
          'carry the sheets. They are usually 0.60 m apart and sold 6 m '
          'long.',
    ),
    InfoSection(
      'Ridge roll, screws and gutters',
      'Ridge and hip rolls are bent caps over the ridge and hips, 2.4 m '
          'long. Tek screws with rubber washers fix the sheets to the '
          'purlins. Gutters run along the eaves and drain into downspouts.',
    ),
  ],
  solution: const [
    InfoSection(
      'Length along the slope',
      'A plan measurement times the pitch factor √(1 + (rise ÷ run)²): 1.054 '
          'for 4:12, 1.118 for 6:12, 1.414 for 12:12.',
      formula: 'slope = rafter × pitch factor',
    ),
    InfoSection(
      'Hip roof',
      'The roof area is the plan area times the pitch factor. The rafter '
          'runs half the width. Each of the 4 hips is the run times '
          '√(2 + (rise ÷ run)²). The four faces add up to a gable on the same '
          'plan, so the sheets are counted that way, plus 10% for the '
          'diagonal cuts.',
      formula:
          'area = length × width × √(1 + p²)\n'
          'slope = width ÷ 2 × √(1 + p²)\n'
          'ridge = length − width\n'
          'hips = 4 × width ÷ 2 × √(2 + p²)',
    ),
    InfoSection(
      'Corrugated sheets',
      'Count the sheets along the eaves from their cover width, and the '
          'sheets up the slope from their length less the 0.25 m end lap.',
      formula:
          'across = round up(roof length ÷ cover)\n'
          'up = round up((slope − 0.25) ÷ (sheet length − 0.25))\n'
          'sheets = across × up × sides',
    ),
    InfoSection(
      'Long-span sheets',
      'One sheet per cover width along the eaves, each cut 5 cm longer than '
          'the slope.',
      formula:
          'sheets = round up(roof length ÷ cover) × sides\n'
          'metres = sheets × (slope + 0.05)',
    ),
    InfoSection(
      'Purlins',
      'Purlin lines up each side, one at the eaves and one at the ridge. '
          'Each line takes 6 m purlins that cover 5.8 m once joined.',
      formula:
          'lines = round up(slope ÷ spacing) + 1\n'
          'purlins = lines × round up(roof length ÷ 5.8) × sides',
    ),
    InfoSection(
      'Screws and ridge roll',
      'About 8 tek screws per m² for corrugated sheets and 7 per m² for '
          'long-span, which is 4 per sheet at every purlin plus the extra '
          'screws at the eaves and ridge. Ridge rolls are 2.4 m long and lap '
          '0.15 m.',
      formula:
          'screws = roof area × 8 (or 7)\n'
          'ridge rolls = round up((ridge + hips) ÷ 2.25)',
    ),
    InfoSection(
      'Gutters',
      'Gutters run along every eave. One downspout serves about 10 m of '
          'gutter.',
      formula:
          'gutter = eave lengths\n'
          'downspout = round up(gutter ÷ 10) × height',
    ),
    InfoSection(
      'Cost',
      'Sheets × price per sheet, or metres × price per metre for long-span. '
          'Purlins, screws, ridge rolls and gutters are priced from your '
          'price list and added to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'https://www.ugc.ph/product/durarib/',
    'https://www.ugc.ph/product/multi-rib8/',
    'https://roofonline.com/roof-pitch-factor/',
    'https://aedoconstruction.com/blog/roof-gutter-downspout-cost-philippines/',
  ],
);

/// A price list item's name followed by [extra], e.g. "Downspout, PVC 3",
/// 2 × 3 m".
String _named(String itemKey, String extra) =>
    '${itemByKey(itemKey)!.name}, $extra';

/// Broadloom carpet comes off rolls 4 m or 3.66 m wide.
({int drops, double cut, double bought}) carpetDrops(
  double length,
  double width,
  double roll,
) {
  ({int drops, double cut, double bought}) lay(double along, double across) {
    final drops = ceilCount(across / roll);
    final cut = along + carpetTrim;
    return (drops: drops, cut: cut, bought: drops * cut * roll);
  }

  final a = lay(length, width);
  final b = lay(width, length);
  return a.bought <= b.bought ? a : b;
}

final carpet = MaterialSpec(
  id: 'carpet',
  name: 'Carpet',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/carpet.png',
  blurb: 'Wall-to-wall carpet from a roll, or carpet tiles',
  keywords: const ['alpombra', 'karpet', 'rug', 'broadloom', 'carpet tile'],
  priceRef: (s) =>
      PriceRef(s['type'] == 'tiles' ? 'carpet_tile_box' : 'carpet_m2'),
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Room length',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
    ),
    const NumberField(
      id: 'width',
      label: 'Room width',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
    ),
    priceField('Price per m²', visibleWhen: (s) => s['type'] != 'tiles'),
    priceField(
      'Price per box',
      id: 'boxPrice',
      visibleWhen: (s) => s['type'] == 'tiles',
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Carpet',
      initial: 'roll',
      leading: true,
      options: [
        ChoiceOption('roll', 'Roll (broadloom)'),
        ChoiceOption('tiles', 'Carpet tiles'),
      ],
    ),
    ChoiceField(
      id: 'rollWidth',
      label: 'Roll width',
      initial: '4',
      options: const [
        ChoiceOption('4', '4.00 m', 4),
        ChoiceOption('3.66', '3.66 m (12 ft)', 3.66),
      ],
      visibleWhen: (s) => s['type'] != 'tiles',
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    if (input.chose('type', 'tiles')) {
      final tiles = ceilCount(area * 1.05 / 0.25);
      final boxes = ceilCount(tiles / 20);
      return CalcResult(
        label: 'Carpet tiles 50 × 50 cm',
        area: area,
        quantity: boxes.toDouble(),
        unit: QuantityUnit.boxes,
        unitPrice: input['boxPrice'],
        itemKey: 'carpet_tile_box',
        details: [
          ResultDetail('Room area', formatArea(area)),
          ResultDetail('Tiles with 5% waste', formatCount(tiles, 'tile')),
          const ResultDetail('Tiles per box (5 m²)', '20'),
        ],
      );
    }
    final roll = input.choice('rollWidth').value;
    final lay = carpetDrops(length, width, roll);
    final bought = roundUp(lay.bought, 1);
    final perimeter = 2 * (length + width);
    return CalcResult(
      label: 'Carpet, ${formatLength(roll)} roll',
      area: area,
      quantity: bought,
      unit: QuantityUnit.squareMetres,
      unitPrice: input['price'],
      itemKey: 'carpet_m2',
      details: [
        ResultDetail('Room area', formatArea(area)),
        ResultDetail(
          'Drops from a ${formatLength(roll)} roll',
          '${lay.drops} × ${formatLength(roundUp(lay.cut))}',
        ),
        ResultDetail('Carpet to buy', formatArea(bought)),
      ],
      companions: [
        buy('underlay_m2', area * 1.05),
        buy('gripper_m', perimeter),
        if (lay.drops > 1) buy('seam_tape_m', (lay.drops - 1) * lay.cut),
      ],
      note: 'Drops run the way that needs less carpet.',
    );
  },
  definitions: const [
    InfoSection(
      'Broadloom carpet',
      'Wall-to-wall carpet cut from rolls 4 m or 3.66 m (12 ft) wide and '
          'priced per square metre. Each length cut from the roll is a drop.',
    ),
    InfoSection(
      'Carpet tiles',
      '50 × 50 cm squares, usually 20 to a box (5 m²). Easy to replace one '
          'at a time.',
    ),
    InfoSection(
      'Underlay, gripper and seam tape',
      'Underlay is the cushion under broadloom carpet. Gripper strips are '
          'nailed around the walls to hold the carpet edges. Seam tape joins '
          'two drops side by side.',
    ),
  ],
  solution: const [
    InfoSection(
      'Drops',
      'Enough roll widths to span the room, each cut 10 cm longer than the '
          'room for trimming. Both directions are tried and the one that '
          'needs less carpet is used.',
      formula:
          'drops = round up(room width ÷ roll width)\n'
          'carpet = drops × (room length + 0.10) × roll width',
    ),
    InfoSection(
      'Underlay, gripper and seam tape',
      'Underlay covers the floor plus 5%. Gripper runs around the room. '
          'Each joint between drops takes one drop length of seam tape.',
      formula:
          'underlay = area × 1.05\n'
          'gripper = 2 × (length + width)\n'
          'seam tape = (drops − 1) × drop length',
    ),
    InfoSection(
      'Carpet tiles',
      'Each tile covers 0.25 m². Add 5% for cuts and divide into boxes of '
          '20.',
      formula:
          'tiles = round up(area × 1.05 ÷ 0.25)\n'
          'boxes = round up(tiles ÷ 20)',
    ),
    InfoSection(
      'Cost',
      'Square metres × price per m², or boxes × price per box. Underlay, '
          'gripper and seam tape are priced from your price list and added '
          'to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'https://jswallmatrix.com/products/carpets/carpet-roll/price-list-philippines',
  ],
);

/// Wallpaper rolls by option id: width and length in metres, and the
/// price list entry.
const _wallpaperRolls = {
  'std': (width: 0.53, length: 10.05, key: 'wallpaper_std'),
  'jumbo': (width: 1.06, length: 15.6, key: 'wallpaper_jumbo'),
  'narrow': (width: 0.45, length: 10.0, key: 'wallpaper_narrow'),
};

/// A 200 g pack of paste hangs about 5 standard rolls (26.6 m²).
const rollsPerPastePack = 5;

final wallpaper = MaterialSpec(
  id: 'wallpaper',
  name: 'Wallpaper',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/wallpaper.png',
  blurb: 'Rolls counted strip by strip, with pattern repeat and paste',
  keywords: const ['wall paper', 'wallcovering', 'wall sticker'],
  priceRef: (s) {
    final roll = _wallpaperRolls[s['roll']];
    return roll == null ? null : PriceRef(roll.key);
  },
  numbers: const [
    NumberField(
      id: 'width',
      label: 'Wall width',
      typical: (min: 0.3, max: 100),
      unit: 'm',
      hint: 'Add up the widths of all walls to cover',
      max: 10000,
    ),
    NumberField(
      id: 'height',
      label: 'Wall height',
      typical: (min: 0.5, max: 8),
      unit: 'm',
      max: 100,
    ),
    NumberField(
      id: 'openings',
      label: 'Doors to skip',
      unit: 'm',
      hint: 'Optional. Total width of full-height openings',
      optional: true,
      max: 10000,
    ),
    NumberField(
      id: 'price',
      label: 'Price per roll',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'roll',
      label: 'Roll size',
      initial: 'std',
      options: [
        ChoiceOption('std', '0.53 × 10.05 m', 0.53),
        ChoiceOption('jumbo', '1.06 × 15.6 m', 1.06),
        ChoiceOption('narrow', '0.45 × 10 m', 0.45),
      ],
    ),
    const ChoiceField(
      id: 'repeat',
      label: 'Pattern repeat',
      initial: '0',
      helper: 'Printed on the label; matching patterns wastes paper',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('32', '32 cm', 0.32),
        ChoiceOption('53', '53 cm', 0.53),
        ChoiceOption('64', '64 cm', 0.64),
      ],
    ),
    wasteField(initial: 'none', percents: const [0, 10, 15]),
    const ChoiceField(
      id: 'backing',
      label: 'Backing',
      initial: 'paste',
      helper: 'Self-adhesive rolls need no paste',
      options: [
        ChoiceOption('paste', 'Hung with paste'),
        ChoiceOption('self', 'Self-adhesive'),
      ],
    ),
  ],
  compute: (input) {
    final height = input['height'];
    final width = input['width'] - input.optional('openings');
    if (width <= 0) {
      throw ArgumentError('Doors to skip must be narrower than the walls');
    }
    final choice = input.choice('roll');
    final roll = _wallpaperRolls[choice.id]!;
    final standard = _wallpaperRolls['std']!;
    final repeat = input.choice('repeat').value;
    var drop = height + wallpaperTrim;
    if (repeat > 0) drop = ceilCount(drop / repeat) * repeat;
    final perRoll = (roll.length / drop + 1e-9).floor();
    if (perRoll == 0) {
      throw ArgumentError('The wall is taller than one roll');
    }
    final strips = ceilCount(width / roll.width);
    final waste = input.choice('waste').value;
    final count = withWaste(ceilCount(strips / perRoll), waste);
    // Paste is counted in standard rolls: a jumbo roll is about 3 of them.
    final standardRolls =
        count.total *
        (roll.width * roll.length) /
        (standard.width * standard.length);
    return CalcResult(
      label: 'Wallpaper ${choice.label}',
      area: width * height,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.rolls,
      unitPrice: input['price'],
      itemKey: roll.key,
      details: [
        ResultDetail(
          repeat > 0 ? 'Strip length (with repeat)' : 'Strip length (+10 cm)',
          formatLength(roundUp(drop)),
        ),
        ResultDetail('Strips per roll', '$perRoll'),
        ResultDetail('Strips to cover ${formatLength(width)}', '$strips'),
        ResultDetail(
          'Rolls',
          formatQuantity(count.base.toDouble(), QuantityUnit.rolls),
        ),
        ...wasteDetail(count, waste, QuantityUnit.rolls),
      ],
      companions: [
        if (input.chose('backing', 'paste'))
          buy('wallpaper_paste', standardRolls / rollsPerPastePack),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Roll sizes',
      'The standard roll is 0.53 m wide and 10.05 m long (about 5.3 m²). '
          'Jumbo rolls are 1.06 × 15.6 m; some self-adhesive rolls are '
          '0.45 × 10 m.',
    ),
    InfoSection(
      'Strip',
      'One floor-to-ceiling length cut from the roll. Leftovers shorter than '
          'the wall cannot be used for another full strip.',
    ),
    InfoSection(
      'Pattern repeat',
      'The distance before a pattern repeats. Each strip must start at the '
          'same point of the pattern, so strips are cut in whole repeats.',
    ),
    InfoSection(
      'Paste',
      'Wallpaper paste comes as a 200 g pack of powder mixed with water. '
          'One pack hangs about 5 standard rolls. Self-adhesive rolls need '
          'none.',
    ),
  ],
  solution: const [
    InfoSection(
      'Strip length',
      'Wall height plus 10 cm for trimming, rounded up to whole pattern '
          'repeats if there is one.',
      formula: 'strip = height + 0.10',
    ),
    InfoSection(
      'Strips per roll',
      'Only whole strips count.',
      formula: 'per roll = round down(roll length ÷ strip)',
    ),
    InfoSection(
      'Rolls',
      'Strips across the walls, divided among the rolls, plus the waste '
          'allowance rounded up separately.',
      formula:
          'strips = round up(wall width ÷ roll width)\n'
          'rolls = round up(strips ÷ per roll) + round up(rolls × waste)',
    ),
    InfoSection(
      'Paste',
      'One pack for every 5 standard rolls of 5.3 m². A jumbo roll counts as '
          'about 3 standard rolls.',
      formula: 'packs = round up(rolls × roll area ÷ 5.3 ÷ 5)',
    ),
    InfoSection(
      'Cost',
      'Multiply the rolls by the price per roll. Paste is priced from your '
          'price list and added to the total.',
      formula: 'cost = rolls × price per roll + paste',
    ),
  ],
  references: const [
    'https://www.screwfix.com/guides/painting-decorating/wallpaper/how-much-wallpaper-do-i-need',
  ],
);
