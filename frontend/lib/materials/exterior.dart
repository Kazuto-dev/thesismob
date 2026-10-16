// Perimeter fence, gates and roof edges: fascia, eaves soffit and
// flashing. Sources are listed in docs/calculations.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'architectural.dart'
    show
        litresPerGallon,
        neutralizerCoverage,
        paintWaste,
        primerCoverage,
        ridgeRollCover,
        thinnerCleanup,
        thinnerShare;
import 'calc_helpers.dart';
import 'concrete.dart'
    show
        columnFrameLumber,
        coverEarth,
        coverFormed,
        formNails,
        hookLength,
        stockBars;
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';
import 'sitework.dart' show enamelCoverage, steelStockLength, steelWaste;
import 'structural.dart' show chbHorizontalBars, chbVerticalBars, screwsPerM2;
import 'work_items.dart';

/// Keys of the work items these calculators add to the bill of
/// quantities. The fence uses the masonry, concrete, rebar, formwork,
/// plaster and painting work items that already exist.
abstract final class ExteriorWork {
  static const steelGate = 'steel_gate';
  static const fasciaBoard = 'fascia_board';
  static const eavesSoffit = 'eaves_soffit';
  static const roofFlashing = 'roof_flashing';
}

// ---------------------------------------------------------------------------
// Price book
// ---------------------------------------------------------------------------

/// Fascia widths offered, with the 1" × 12 ft board of good lumber each
/// one is cut from: 6, 8 or 10 board feet at about ₱70 a board foot.
typedef FasciaWidth = ({String id, String label, double width, double price});

const fasciaWidths = <FasciaWidth>[
  (id: '6', label: '6" (150 mm)', width: 0.15, price: 420),
  (id: '8', label: '8" (200 mm)', width: 0.20, price: 560),
  (id: '10', label: '10" (250 mm)', width: 0.25, price: 700),
];

/// A 1" × [inches]" × 12 ft board of good lumber.
String woodFasciaKey(String inches) => 'lumber_1x${inches}_12ft';

FasciaWidth _fasciaWidth(String? id) =>
    fasciaWidths.firstWhere((w) => w.id == id, orElse: () => fasciaWidths[1]);

/// A kind of roof flashing: its price book item, girth (the width of flat
/// sheet it is bent from) and the rows of screws that fix it.
typedef Flashing = ({
  String id,
  String label,
  String key,
  String name,
  double girth,
  int rows,
  double price,
});

const flashings = <Flashing>[
  (
    id: 'wall',
    label: 'Wall or apron flashing',
    key: 'flashing_wall',
    name: 'Wall or apron flashing, pre-painted GI, 300 mm girth, 2.4 m',
    girth: 0.30,
    rows: 1,
    price: 350,
  ),
  (
    id: 'valley',
    label: 'Valley flashing',
    key: 'flashing_valley',
    name: 'Valley flashing, pre-painted GI, 600 mm girth, 2.4 m',
    girth: 0.60,
    rows: 2,
    price: 650,
  ),
  (
    id: 'gable',
    label: 'Gable or barge flashing',
    key: 'flashing_gable',
    name: 'Gable (barge) flashing, pre-painted GI, 400 mm girth, 2.4 m',
    girth: 0.40,
    rows: 2,
    price: 450,
  ),
  // Already in the price book; the roofing calculator buys it too.
  (
    id: 'ridge',
    label: 'Ridge or hip roll',
    key: 'ridge_roll',
    name: 'Ridge or hip roll, 2.4 m',
    girth: 0.45,
    rows: 2,
    price: 600,
  ),
];

Flashing _flashing(String? id) =>
    flashings.firstWhere((f) => f.id == id, orElse: () => flashings.first);

Item _pc(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'pc', group, plural: 'pcs', price: price, estimate: true);

Item _set(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'set', group, plural: 'sets', price: price, estimate: true);

/// Price book items these calculators buy. Every price is our estimate of
/// Metro Manila retail for late 2026; see docs/calculations.md for what
/// each rests on.
final List<Item> exteriorItems = [
  // Gates.
  const Item(
    'steel_gate_m2',
    'Steel gate leaf, tubular frame with infill, fabricated and primed',
    'm²',
    ItemGroup.doors,
    step: 0.01,
    price: 4500,
    estimate: true,
  ),
  _set(
    'steel_gate_set',
    'Steel gate, fabricated and primed, about 3.0 × 1.8 m',
    ItemGroup.doors,
    24000,
  ),
  _pc('gate_hinge', 'Gate hinge, heavy duty, weld-on', ItemGroup.doors, 250),
  _pc('drop_bolt', 'Drop bolt for gates, 12"', ItemGroup.doors, 300),
  _set('gate_latch', 'Gate latch with padlock hasp', ItemGroup.doors, 450),
  _pc(
    'gate_wheel',
    'Sliding gate wheel, V-groove 4", with bracket',
    ItemGroup.doors,
    650,
  ),
  _set(
    'gate_guide',
    'Sliding gate top guide rollers with bracket',
    ItemGroup.doors,
    550,
  ),
  _pc('gate_stopper', 'Sliding gate end stopper', ItemGroup.doors, 150),
  const Item(
    'square_tube_4',
    'Square steel tube 4" × 4" × 3 mm, 6 m',
    'length',
    ItemGroup.steel,
    plural: 'lengths',
    price: 3600,
    estimate: true,
  ),

  // Fascia and soffit.
  const Item(
    'fiber_cement_board_9',
    'Fiber cement board 9 mm 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 950,
    estimate: true,
  ),
  for (final w in fasciaWidths)
    _pc(
      woodFasciaKey(w.id),
      'Good lumber 1" × ${w.id}" × 12 ft, S4S',
      ItemGroup.lumber,
      w.price,
    ),
  const Item(
    'fascia_metal_m',
    'Fascia cover, pre-painted GI, roll-formed',
    'm',
    ItemGroup.roofing,
    step: 0.01,
    price: 280,
    estimate: true,
  ),
  _pc(
    'pvc_soffit_panel',
    'PVC soffit panel 200 mm × 3.0 m',
    ItemGroup.ceiling,
    180,
  ),
  _pc(
    'pvc_soffit_trim',
    'PVC soffit trim (J-channel), 3.0 m',
    ItemGroup.ceiling,
    120,
  ),

  // Flashing.
  for (final f in flashings)
    if (f.key != 'ridge_roll') _pc(f.key, f.name, ItemGroup.roofing, f.price),
  _pc('wall_plug', 'Plastic wall plug with screw, 6 mm', ItemGroup.other, 5),
];

/// Work items these calculators measure. No DPWH item number was
/// confirmed for them; outputs are for small jobs.
const exteriorWorkItems = <WorkItem>[
  WorkItem(
    ExteriorWork.steelGate,
    'Steel gate, set on its posts with hinges or track',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.welding: 1}),
    output: 4,
  ),
  WorkItem(
    ExteriorWork.fasciaBoard,
    'Fascia board, installed',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.scaffold: 0.5}),
    output: 15,
  ),
  WorkItem(
    ExteriorWork.eavesSoffit,
    'Eaves soffit, boards or panels on metal furring',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.scaffold: 1}),
    output: 8,
  ),
  WorkItem(
    ExteriorWork.roofFlashing,
    'Roof flashing, lapped and sealed',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 20,
  ),
];

/// The calculators.
final List<MaterialSpec> exteriorMaterials = [
  fence,
  gate,
  fascia,
  soffit,
  flashing,
];

/// A measured work quantity, to the nearest hundredth of its unit.
double _hundredths(double value) => (value * 100).roundToDouble() / 100;

/// A measured volume, to the nearest thousandth of a m³.
double _thousandths(double value) => (value * 1000).roundToDouble() / 1000;

/// Metres of bar placed in [pieces] bars each [length] metres long, with
/// the laps [stockBars] adds where a bar longer than 6 m is spliced.
double _barMetres(int pieces, double length, double lap) {
  if (pieces <= 0 || length <= 0) return 0;
  if (length <= rebarStockLength) return pieces * length;
  final splices = ceilCount(length / rebarStockLength) - 1;
  return pieces * (length + splices * lap);
}

/// Flat latex covers about 30 m² per 4 L coat, as in the Paint calculator.
const latexCoverage = 30.0;

/// One coat of primer and [coats] of latex for [area] m², with masonry
/// neutralizer on new plaster, all going to the painting work.
List<Companion> _latexPaint(
  double area, {
  int coats = 2,
  bool masonry = false,
}) {
  final primer = area / (primerCoverage / litresPerGallon) * (1 + paintWaste);
  final latex =
      area * coats / (latexCoverage / litresPerGallon) * (1 + paintWaste);
  return [
    if (masonry)
      buy('neutralizer', area / neutralizerCoverage, work: Work.painting),
    buy('primer', primer / litresPerGallon, work: Work.painting),
    buy('paint_latex', latex / litresPerGallon, work: Work.painting),
  ];
}

/// [coats] of enamel for [area] m², over one coat of primer when [primer]
/// is true, thinned, all going to the painting work.
List<Companion> _enamelPaint(double area, {int coats = 2, bool primer = true}) {
  final primerLitres = primer
      ? area / (primerCoverage / litresPerGallon) * (1 + paintWaste)
      : 0.0;
  final enamel =
      area * coats / (enamelCoverage / litresPerGallon) * (1 + paintWaste);
  return [
    if (primer)
      buy('primer', primerLitres / litresPerGallon, work: Work.painting),
    buy('paint_enamel', enamel / litresPerGallon, work: Work.painting),
    buy(
      'paint_thinner',
      (primerLitres + enamel) * thinnerShare + thinnerCleanup,
      work: Work.painting,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Perimeter fence
// ---------------------------------------------------------------------------

/// Each post stands on a square footing 0.60 m wide and 0.25 m thick; the
/// blocks between posts stand on a continuous wall footing 0.20 m thick.
const fencePostFooting = 0.60;
const fencePostFootingThickness = 0.25;
const fenceWallFootingThickness = 0.20;

/// 10 mm bars in the footings: post footings each way at 0.15 m, three
/// bars along the wall footing and cross bars every 0.40 m.
const fencePostFootingBarSpacing = 0.15;
const fenceWallFootingBars = 3;
const fenceCrossBarSpacing = 0.40;

/// Posts have 4 main bars, bent 0.30 m into the footing, and 10 mm ties
/// every 0.20 m.
const fencePostBars = 4;
const fencePostDowel = 0.30;
const fenceTieSpacing = 0.20;

/// Every bar but the post main bars is 10 mm, the wall's own bars
/// included: vertical every 0.60 m and horizontal every 3rd course, the
/// usual spacing in the Concrete Hollow Blocks calculator.
const fenceBarMm = 10;
const fenceWallVertical = '0.6';
const fenceWallHorizontal = '3';

/// Concrete waste on footings and posts, and the times the post forms are
/// used along the fence.
const fenceConcreteWaste = 0.05;
const fenceFormUses = 3;

/// Lap of the continuous footing bars where they are spliced: 40 bar
/// diameters.
const fenceLapBars = 40;

bool _plastered(Map<String, String> s) => s['plaster'] != '0';

final fence = MaterialSpec(
  id: 'fence',
  name: 'Perimeter Fence',
  category: MaterialCategory.structural,
  icon: Icons.fence,
  blurb: 'A block fence with concrete posts, footings, plaster and paint',
  keywords: const [
    'fence',
    'bakod',
    'pader',
    'perimeter wall',
    'boundary wall',
    'CHB fence',
    'hollow blocks',
    'poste',
    'haligi',
    'footing',
  ],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Fence length',
      unit: 'm',
      hint: 'Along the property line, less the gate openings',
      typical: (min: 1, max: 300),
      max: 10000,
    ),
    NumberField(
      id: 'height',
      label: 'Fence height',
      unit: 'm',
      hint: 'Above the ground, usually 1.8–2.4 m',
      typical: (min: 0.5, max: 4),
      max: 20,
    ),
    NumberField(
      id: 'price',
      label: 'Price per block',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'size',
      label: 'Block size',
      initial: '6',
      helper: '6" is usual for perimeter fences',
      options: [
        ChoiceOption('4', '4"'),
        ChoiceOption('6', '6"'),
        ChoiceOption('8', '8"'),
      ],
    ),
    wasteField(initial: '5', helper: 'About 5% of blocks break or are cut'),
    const ChoiceField(
      id: 'spacing',
      label: 'Post spacing',
      initial: '3',
      helper: 'Concrete posts, centre to centre; follow the plans',
      options: [
        ChoiceOption('2.5', '2.5 m', 2.5),
        ChoiceOption('3', '3.0 m', 3.0),
        ChoiceOption('3.5', '3.5 m', 3.5),
      ],
    ),
    const ChoiceField(
      id: 'post',
      label: 'Post size',
      initial: '0.2',
      options: [
        ChoiceOption('0.2', '0.20 × 0.20 m', 0.20),
        ChoiceOption('0.25', '0.25 × 0.25 m', 0.25),
      ],
    ),
    const ChoiceField(
      id: 'postBar',
      label: 'Post bars',
      initial: '12',
      helper: 'Four main bars, with 10 mm ties every 20 cm',
      options: [
        ChoiceOption('10', '4 × 10 mm', 10),
        ChoiceOption('12', '4 × 12 mm', 12),
      ],
    ),
    const ChoiceField(
      id: 'depth',
      label: 'Footing depth',
      initial: '0.8',
      helper: 'From the ground to the bottom of the footings',
      options: [
        ChoiceOption('0.6', '0.60 m', 0.60),
        ChoiceOption('0.8', '0.80 m', 0.80),
        ChoiceOption('1', '1.00 m', 1.00),
      ],
    ),
    const ChoiceField(
      id: 'footing',
      label: 'Wall footing',
      initial: '0.6',
      helper: 'Continuous footing 0.20 m thick under the blocks',
      options: [
        ChoiceOption('0.4', '0.40 m wide', 0.40),
        ChoiceOption('0.6', '0.60 m wide', 0.60),
      ],
    ),
    ChoiceField(
      id: 'class',
      label: 'Concrete mix',
      initial: 'A',
      helper: 'Fajardo site-mix classes: cement : sand : gravel',
      options: [
        for (final m in concreteMixes)
          ChoiceOption(m.id, '${m.label}, ${m.ratio}', m.cement),
      ],
    ),
    const ChoiceField(
      id: 'plaster',
      label: 'Plaster',
      initial: '2',
      helper: 'Above the ground, posts included',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('1', 'One face', 1),
        ChoiceOption('2', 'Both faces', 2),
      ],
    ),
    const ChoiceField(
      id: 'paint',
      label: 'Paint',
      initial: 'none',
      helper: 'On the plastered faces',
      visibleWhen: _plastered,
      options: [
        ChoiceOption('none', 'None'),
        ChoiceOption('latex', 'Latex, primer and 2 coats'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef('chb_${s['size'] ?? '6'}'),
  compute: (input) {
    final length = input['length'];
    final height = input['height'];
    final size = input.choice('size');
    final waste = input.choice('waste').value;
    final spacing = input.choice('spacing').value;
    final post = input.choice('post').value;
    final postBarMm = int.parse(input.choice('postBar').id);
    final depth = input.choice('depth').value;
    final footingWidth = input.choice('footing').value;
    final mix = concreteMix(input.choice('class').id);
    final faces = input.choice('plaster').value;
    final painted = faces > 0 && input.chose('paint', 'latex');

    final bays = ceilCount(length / spacing);
    final posts = bays + 1;
    final wallLength = length - posts * post;
    if (wallLength <= 0) {
      throw ArgumentError('The fence must be longer than its posts');
    }
    // The blocks start on the wall footing, below the ground.
    final below = depth - fenceWallFootingThickness;
    final wallHeight = height + below;
    final area = wallLength * wallHeight;
    final blocks = withWaste(ceilCount(area * chbPerSquareMetre), waste);
    final mortar = chbMortar[size.id]!;
    final plaster = length * height * faces;

    // Footings: one under each post, a wall footing between them.
    final footingRun = math.max(0.0, length - posts * fencePostFooting);
    final wallFooting = footingRun * footingWidth * fenceWallFootingThickness;
    final postFootings =
        posts * fencePostFooting * fencePostFooting * fencePostFootingThickness;
    final footings = wallFooting + postFootings;
    final postHeight = height + depth - fencePostFootingThickness;
    final postConcrete = posts * post * post * postHeight;

    // 10 mm bars: in the wall, along and across the wall footing, both
    // ways in each post footing, and the post ties.
    final wallBarsPerM2 =
        chbVerticalBars[fenceWallVertical]! +
        chbHorizontalBars[fenceWallHorizontal]!;
    final wallBarMetres = area * wallBarsPerM2;
    final wallBars = ceilCount(wallBarMetres / rebarStockLength);
    const lap = fenceLapBars * fenceBarMm / 1000;
    final longBars = stockBars(fenceWallFootingBars, length, lap);
    final longMetres = _barMetres(fenceWallFootingBars, length, lap);
    final crossCount = footingRun > 0
        ? (footingRun / fenceCrossBarSpacing + 1e-9).floor() + 1
        : 0;
    final crossLength = footingWidth - 2 * coverEarth;
    final crossBars = stockBars(crossCount, crossLength, 0);
    final padLength = fencePostFooting - 2 * coverEarth;
    final padEachWay =
        (padLength / fencePostFootingBarSpacing + 1e-9).floor() + 1;
    final padCount = posts * 2 * padEachWay;
    final padBars = stockBars(padCount, padLength, 0);
    final tiesPerPost = (postHeight / fenceTieSpacing + 1e-9).floor() + 1;
    final tieCount = posts * tiesPerPost;
    final tieLength = 4 * (post - 2 * coverFormed) + 2 * hookLength(fenceBarMm);
    final tieBars = stockBars(tieCount, tieLength, 0);
    // Post bars, bent into the footing.
    final mainCount = posts * fencePostBars;
    final mainLength = postHeight + fencePostDowel;
    final postLap = fenceLapBars * postBarMm / 1000;
    final mainBars = stockBars(mainCount, mainLength, postLap);
    final mainMetres = _barMetres(mainCount, mainLength, postLap);

    final tenBars = wallBars + longBars + crossBars + padBars + tieBars;
    final tenMetres =
        wallBarMetres +
        longMetres +
        crossCount * crossLength +
        padCount * padLength +
        tieCount * tieLength;
    final rebarKg =
        tenMetres * rebarKgPerMetre(fenceBarMm) +
        mainMetres * rebarKgPerMetre(postBarMm);
    // Ties wherever bars cross: the wall's bars, the wall footing's cross
    // bars over its three long bars, each post footing's mat and each post
    // tie round its four bars.
    final crossings =
        area /
            double.parse(fenceWallVertical) /
            (double.parse(fenceWallHorizontal) * 0.20) +
        crossCount * fenceWallFootingBars +
        posts * padEachWay * padEachWay +
        tieCount * fencePostBars;

    // Plywood on the two exposed faces of each post; the blocks on either
    // side close the other two.
    final formArea = posts * 2 * post * postHeight;
    final sheets = math.max(
      1,
      ceilCount(formArea / sheetFormArea / fenceFormUses),
    );

    final concreteFactor = 1 + fenceConcreteWaste;
    const footingWork = Work.concreteFooting;
    const postWork = Work.concreteColumn;
    final wallWork = switch (size.id) {
      '4' => Work.chb4,
      '8' => Work.chb8,
      _ => Work.chb6,
    };

    return CalcResult(
      label:
          'CHB fence ${size.label}, ${formatLength(length)} long, '
          '${formatLength(height)} high',
      area: area,
      quantity: blocks.total.toDouble(),
      unit: QuantityUnit.blocks,
      unitPrice: input['price'],
      itemKey: 'chb_${size.id}',
      details: [
        ResultDetail(
          'Posts at most ${formatLength(spacing)} apart',
          formatCount(posts, 'post'),
        ),
        ResultDetail(
          'Blocks between posts, ${formatLength(_hundredths(wallLength))} '
          '× ${formatLength(_hundredths(wallHeight))}',
          formatArea(roundUp(area)),
        ),
        ResultDetail(
          'Of it below the ground, down to the footing',
          formatLength(_hundredths(below)),
        ),
        ResultDetail(
          'Blocks at 12.5 per m²',
          formatQuantity(blocks.base.toDouble(), QuantityUnit.blocks),
        ),
        ...wasteDetail(blocks, waste, QuantityUnit.blocks),
        ResultDetail(
          'Wall footing ${formatNumber(footingWidth)} × 0.20 m',
          formatLength(_hundredths(footingRun)),
        ),
        ResultDetail(
          'Post footings 0.60 × 0.60 × 0.25 m',
          formatCount(posts, 'footing'),
        ),
        ResultDetail('Footing concrete', formatVolume(roundUp(footings, 3))),
        ResultDetail(
          'Posts ${formatNumber(post)} × ${formatNumber(post)} × '
          '${formatLength(_hundredths(postHeight))}',
          formatVolume(roundUp(postConcrete, 3)),
        ),
        ResultDetail(
          '$fenceBarMm mm bars: wall, footings and ties',
          formatCount(tenBars, 'bar'),
        ),
        ResultDetail(
          'Post bars, $mainCount × $postBarMm mm',
          formatCount(mainBars, 'bar'),
        ),
        ResultDetail('Post form area', formatArea(roundUp(formArea))),
        if (plaster > 0) ResultDetail('Plaster', formatArea(roundUp(plaster))),
      ],
      companions: [
        // Laying stays with the wall; plaster is its own work item.
        buy('cement_40kg', area * mortar.cement, label: 'Cement for laying'),
        buy('sand', area * mortar.sand, label: 'Sand for laying'),
        if (plaster > 0) ...[
          buy(
            'cement_40kg',
            plaster * plasterCement,
            label: 'Cement for plaster',
            work: Work.plaster,
          ),
          buy(
            'sand',
            plaster * plasterSand,
            label: 'Sand for plaster',
            work: Work.plaster,
          ),
        ],
        buy(
          'cement_40kg',
          footings * concreteFactor * mix.cement,
          label: 'Cement for footings',
          work: footingWork,
        ),
        buy(
          'sand',
          footings * concreteFactor * mix.sand,
          label: 'Sand for footings',
          work: footingWork,
        ),
        buy(
          'gravel',
          footings * concreteFactor * mix.gravel,
          label: 'Gravel for footings',
          work: footingWork,
        ),
        buy(
          'cement_40kg',
          postConcrete * concreteFactor * mix.cement,
          label: 'Cement for posts',
          work: postWork,
        ),
        buy(
          'sand',
          postConcrete * concreteFactor * mix.sand,
          label: 'Sand for posts',
          work: postWork,
        ),
        buy(
          'gravel',
          postConcrete * concreteFactor * mix.gravel,
          label: 'Gravel for posts',
          work: postWork,
        ),
        if (postBarMm == fenceBarMm)
          buy(rebarKey(fenceBarMm), (tenBars + mainBars).toDouble())
        else ...[
          buy(rebarKey(fenceBarMm), tenBars.toDouble()),
          buy(rebarKey(postBarMm), mainBars.toDouble()),
        ],
        buy(
          'tie_wire',
          crossings * tieWirePerTie(postBarMm) / tieWireMetresPerKg,
        ),
        buy(marinePlywoodKey('12'), sheets.toDouble()),
        buy('coco_lumber', sheets * columnFrameLumber['12']!),
        buy('nails', formArea * formNails),
        if (painted) ..._latexPaint(plaster, masonry: true),
      ],
      note:
          'Digging and backfill are not counted: use the Earthworks '
          'calculator with the footing sizes above. Bars, posts and '
          'footings must follow the structural plans.',
      works: [
        WorkQuantity(wallWork, _hundredths(area)),
        if (plaster > 0) WorkQuantity(Work.plaster, _hundredths(plaster)),
        WorkQuantity(footingWork, _thousandths(footings)),
        WorkQuantity(postWork, _thousandths(postConcrete)),
        WorkQuantity(Work.rebar, _hundredths(rebarKg)),
        WorkQuantity(Work.formwork, _hundredths(formArea)),
        if (painted)
          WorkQuantity(Work.painting, _hundredths(plaster), effort: 3),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Perimeter fence',
      'A wall of concrete hollow blocks along the property line, held by '
          'reinforced concrete posts and standing on concrete footings. '
          'Enter the length of the block fence without the gate openings, '
          'and its height above the ground. Gates are counted in the Steel '
          'Gate calculator.',
    ),
    InfoSection(
      'Posts',
      'Reinforced concrete columns at most the chosen spacing apart, one '
          'at each end: about every 3 m is usual. Each post has four main '
          'bars bent into its footing and 10 mm ties every 20 cm, and stands '
          'on a 0.60 × 0.60 × 0.25 m footing with 10 mm bars every 15 cm '
          'both ways.',
    ),
    InfoSection(
      'Wall footing',
      'A continuous concrete footing 0.20 m thick under the blocks between '
          'the post footings, with three 10 mm bars along it and 10 mm cross '
          'bars every 40 cm. The blocks start on it, below the ground, so '
          'the wall is taller than the fence by the footing depth less the '
          'footing.',
    ),
    InfoSection(
      'Blocks, mortar and bars',
      'Blocks are laid in Class B mortar like any CHB wall, with 10 mm '
          'vertical bars every 60 cm and horizontal bars every third course. '
          '6" blocks are usual for perimeter fences; 4" suits low fences '
          'inside a lot.',
    ),
    InfoSection(
      'Plaster and paint',
      'Plaster, 16 mm thick, covers the fence above the ground, posts '
          'included, on one or both faces. Paint is a wash of masonry '
          'neutralizer, one coat of primer and two of latex on the plastered '
          'faces.',
    ),
    InfoSection(
      'Height and local rules',
      'Fence heights and solid or see-through parts are often limited by '
          'the local government or the subdivision. Check them before '
          'designing, and follow the structural plans for bars and footings.',
    ),
  ],
  solution: const [
    InfoSection(
      'Posts and blocks',
      'One more post than bays. The blocks fill the fence between the posts, '
          'from the wall footing to the top, at 12.5 per m², plus waste.',
      formula:
          'posts = round up(length ÷ spacing) + 1\n'
          'wall = (length − posts × post) × (height + depth − 0.20)\n'
          'blocks = round up(wall × 12.5) + round up(5%)',
    ),
    InfoSection(
      'Mortar and plaster',
      'Class B mortar per m² of wall as in the Concrete Hollow Blocks '
          'calculator, and 0.192 bags of cement and 0.016 m³ of sand per m² '
          'of each plastered face above the ground.',
      formula:
          'plaster = length × height × faces\n'
          'cement = wall × mortar + plaster × 0.192\n'
          'sand = wall × mortar sand + plaster × 0.016',
    ),
    InfoSection(
      'Footings and posts',
      'Concrete with 5% waste, at the chosen mix. The wall footing runs '
          'between the post footings.',
      formula:
          'wall footing = (length − posts × 0.60) × width × 0.20\n'
          'post footings = posts × 0.60 × 0.60 × 0.25\n'
          'posts = posts × post² × (height + depth − 0.25)\n'
          'cement = round up(volume × 1.05 × bags per m³)',
    ),
    InfoSection(
      'Bars and tie wire',
      'Wall bars at 4.28 m per m², three footing bars along the whole fence '
          '(lapped 40 bar sizes past 6 m), cross bars every 0.40 m, 4 bars '
          'each way in each post footing, four main bars per post 0.30 m '
          'longer than the post, and ties every 0.20 m. Bars are cut from '
          '6 m stock; each crossing takes 0.30 m of tie wire.',
      formula:
          'ties per post = round down(post height ÷ 0.20) + 1\n'
          'tie = 4 × (post − 0.08) + 2 × 0.105 m\n'
          'tie wire = crossings × 0.30 ÷ 53 kg',
    ),
    InfoSection(
      'Forms',
      'Plywood on the two exposed faces of each post, used three times '
          'along the fence, with 20.33 bd ft of coco lumber per sheet and '
          '0.20 kg of nails per m².',
      formula:
          'form area = posts × 2 × post × post height\n'
          'plywood = max(1, round up(form area ÷ 2.88 ÷ 3))',
    ),
    InfoSection(
      'Paint',
      'When chosen, the plastered area gets masonry neutralizer (1 L per '
          '85 m²), one coat of primer (25 m² per 4 L) and two coats of latex '
          '(30 m² per 4 L), each with 10% waste.',
      formula:
          'primer = plaster ÷ 6.25 × 1.10 L\n'
          'latex = plaster × 2 ÷ 7.5 × 1.10 L',
    ),
    InfoSection(
      'Cost',
      'Multiply the blocks by the price per block. Cement, sand, gravel, '
          'bars, tie wire, forms and paint are priced from your price book '
          'and added to the total.',
      formula: 'cost = blocks × price per block + other materials',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Tables 1-2 and '
        '2-2 and the forms tables',
    'NSCP 2015, Table 420.6.1.3.1 (concrete cover) and Sec. 425.3 (hooks)',
    'https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/',
    'https://www.boysen.com.ph/products/boysen-permacoat-latex',
  ],
);

// ---------------------------------------------------------------------------
// Steel gate
// ---------------------------------------------------------------------------

/// A sliding leaf overlaps the posts by 0.10 m at each end.
const gateSlidingOverlap = 0.10;

/// Swing leaves taller than 1.5 m hang on 3 hinges, lower ones on 2.
const gateTallLeaf = 1.5;

/// A sliding leaf longer than 4 m runs on 3 wheels, a shorter one on 2.
const gateLongLeaf = 4.0;

/// The track is anchored every 0.60 m.
const gateAnchorSpacing = 0.60;

/// Steel posts go 0.60 m into a 0.40 × 0.40 × 0.80 m concrete footing.
const gatePostEmbed = 0.60;
const gatePostFooting = 0.40 * 0.40 * 0.80;

bool _bySet(Map<String, String> s) => s['buy'] == 'set';

final gate = MaterialSpec(
  id: 'gate',
  name: 'Steel Gate',
  category: MaterialCategory.architectural,
  icon: Icons.door_sliding_outlined,
  blurb: 'Swing or sliding gates with hinges or wheels and track',
  keywords: const [
    'gate',
    'gate ng bakod',
    'tarangkahan',
    'geyt',
    'swing gate',
    'sliding gate',
    'rolling gate',
    'bisagra',
    'steel',
    'welding',
  ],
  numbers: [
    const NumberField(
      id: 'width',
      label: 'Gate opening width',
      unit: 'm',
      hint: 'Between the posts; about 3 m for a car',
      typical: (min: 0.8, max: 8),
      max: 30,
    ),
    const NumberField(
      id: 'height',
      label: 'Gate height',
      unit: 'm',
      typical: (min: 0.8, max: 3.5),
      max: 10,
    ),
    const NumberField(
      id: 'count',
      label: 'Number of gates',
      unit: 'pcs',
      hint: 'Of this size and type',
      initial: '1',
      integer: true,
      max: 100,
    ),
    priceField('Price per m²', visibleWhen: (s) => !_bySet(s)),
    priceField('Price per set', id: 'priceSet', visibleWhen: _bySet),
  ],
  choices: const [
    ChoiceField(
      id: 'type',
      label: 'Gate',
      initial: 'swing2',
      leading: true,
      options: [
        ChoiceOption('swing1', 'Swing, one leaf', 1),
        ChoiceOption('swing2', 'Swing, two leaves', 2),
        ChoiceOption('sliding', 'Sliding on a track', 1),
      ],
    ),
    ChoiceField(
      id: 'buy',
      label: 'Priced',
      initial: 'area',
      helper: 'Fabricators quote by the m² or for the whole gate',
      options: [
        ChoiceOption('area', 'By the m²'),
        ChoiceOption('set', 'By the set'),
      ],
    ),
    ChoiceField(
      id: 'posts',
      label: 'Gate posts',
      initial: 'concrete',
      options: [
        ChoiceOption('concrete', 'Concrete fence posts, counted in the fence'),
        ChoiceOption('steel', 'Steel tube posts 4" × 4"'),
      ],
    ),
    ChoiceField(
      id: 'paint',
      label: 'Finish paint',
      initial: 'enamel',
      helper: 'Over the fabricator\'s primer',
      options: [
        ChoiceOption('enamel', 'Enamel, 2 coats on site'),
        ChoiceOption('none', 'Painted by the fabricator'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_bySet(s) ? 'steel_gate_set' : 'steel_gate_m2'),
  compute: (input) {
    final width = input['width'];
    final height = input['height'];
    final count = input['count'].round();
    if (count < 1) throw ArgumentError('Enter at least one gate');
    final type = input.choice('type');
    final sliding = type.id == 'sliding';
    final leaves = type.value.round();
    final leafRun = sliding ? width + 2 * gateSlidingOverlap : width;
    final area = count * leafRun * height;
    final bySet = input.chose('buy', 'set');
    final painted = input.chose('paint', 'enamel');
    final paintArea = 2 * area;

    final companions = <Companion>[];
    final details = <ResultDetail>[
      ResultDetail(
        sliding
            ? 'Leaf, opening + 2 × 0.10 m overlap'
            : leaves == 2
            ? 'Two leaves of ${formatLength(_hundredths(width / 2))}'
            : 'One leaf',
        '${formatLength(_hundredths(leafRun))} × ${formatLength(height)}',
      ),
      ResultDetail('Gate area', formatArea(_hundredths(area))),
    ];
    if (sliding) {
      final wheels = leafRun > gateLongLeaf + 1e-9 ? 3 : 2;
      // The leaf rolls clear of the opening, so the track is twice as long.
      final track = 2 * leafRun;
      final angles = ceilCount(
        count * track * (1 + steelWaste) / steelStockLength,
      );
      final anchors = ceilCount(track / gateAnchorSpacing) + 1;
      details.addAll([
        ResultDetail('Wheels per gate', '$wheels'),
        ResultDetail(
          'Track, 1½" angle bar, twice the leaf',
          formatLength(_hundredths(count * track)),
        ),
      ]);
      companions.addAll([
        buy('gate_wheel', (count * wheels).toDouble()),
        buy(
          'angle_bar_1_5',
          angles.toDouble(),
          label: 'Angle bar 1½" × 1½" × 3/16", 6 m, for the track',
        ),
        buy('anchor_bolt_10', (count * anchors).toDouble()),
        buy('gate_guide', count.toDouble()),
        buy('gate_stopper', 2.0 * count),
        buy('gate_latch', count.toDouble()),
      ]);
    } else {
      final hinges = height > gateTallLeaf + 1e-9 ? 3 : 2;
      details.add(ResultDetail('Hinges per leaf', '$hinges'));
      companions.addAll([
        buy('gate_hinge', (count * leaves * hinges).toDouble()),
        buy('drop_bolt', (count * leaves).toDouble()),
        buy('gate_latch', count.toDouble()),
      ]);
    }
    if (input.chose('posts', 'steel')) {
      final posts = 2 * count;
      final metres = posts * (height + gatePostEmbed);
      final concrete = posts * gatePostFooting * (1 + 0.05);
      final mix = concreteMix('A');
      details.add(
        ResultDetail(
          'Steel posts, ${formatLength(_hundredths(height + gatePostEmbed))} '
          'each',
          formatCount(posts, 'post'),
        ),
      );
      companions.addAll([
        buy(
          'square_tube_4',
          ceilCount(metres * (1 + steelWaste) / steelStockLength).toDouble(),
        ),
        buy(
          'cement_40kg',
          concrete * mix.cement,
          label: 'Cement for the post footings',
        ),
        buy('sand', concrete * mix.sand),
        buy('gravel', concrete * mix.gravel),
      ]);
    }
    if (painted) {
      details.add(
        ResultDetail('Enamel, both faces', formatArea(_hundredths(paintArea))),
      );
      companions.addAll(_enamelPaint(paintArea, primer: false));
    }

    final name = sliding
        ? 'Steel sliding gate'
        : 'Steel swing gate, ${leaves == 2 ? 'two leaves' : 'one leaf'}';
    final label =
        '${count > 1 ? '$count × ' : ''}$name, '
        '${formatNumber(width)} × ${formatNumber(height)} m';
    final works = [
      WorkQuantity(ExteriorWork.steelGate, _hundredths(area)),
      if (painted)
        WorkQuantity(Work.painting, _hundredths(paintArea), effort: 2),
    ];
    const note =
        'Fabricated gates come primed; the price should include the frame, '
        'the infill and its welding. Locks beyond a latch, and gate motors, '
        'are not counted.';
    if (bySet) {
      return CalcResult(
        label: label,
        area: area,
        quantity: count.toDouble(),
        unit: QuantityUnit.sets,
        unitPrice: input['priceSet'],
        itemKey: 'steel_gate_set',
        details: details,
        companions: companions,
        note: note,
        works: works,
      );
    }
    return CalcResult(
      label: label,
      area: area,
      quantity: roundUp(area),
      unit: QuantityUnit.squareMetres,
      unitPrice: input['price'],
      itemKey: 'steel_gate_m2',
      details: details,
      companions: companions,
      note: note,
      works: works,
    );
  },
  definitions: const [
    InfoSection(
      'Steel gate',
      'A gate of welded steel tube with sheet, bar or grille infill, made by '
          'a fabricator and set on site. Enter the clear opening between the '
          'posts and the gate height.',
    ),
    InfoSection(
      'Swing or sliding',
      'A swing gate hangs on heavy weld-on hinges, two per leaf or three on '
          'leaves taller than 1.5 m, with a drop bolt per leaf and a latch. '
          'A sliding gate is one leaf 0.10 m longer than the opening at each '
          'end, rolling on V-groove wheels along an angle-bar track twice '
          'its length, with top guide rollers and two end stoppers.',
    ),
    InfoSection(
      'Priced by the m² or by the set',
      'Fabricators quote either a price per m² of gate or a price for the '
          'whole gate. Choose the one your quote uses; the hardware, track '
          'and posts are added either way.',
    ),
    InfoSection(
      'Posts',
      'Most gates hang on the concrete posts of the fence, which the '
          'Perimeter Fence calculator counts. Steel posts of 4" × 4" tube '
          'go 0.60 m into a 0.40 × 0.40 × 0.80 m concrete footing.',
    ),
    InfoSection(
      'Paint',
      'Gates arrive primed. Two coats of enamel on both faces are added on '
          'site unless the fabricator paints them.',
    ),
  ],
  solution: const [
    InfoSection(
      'Gate area',
      'The opening width (plus the 0.20 m overlap of a sliding leaf) times '
          'the height, for each gate.',
      formula:
          'swing area = gates × width × height\n'
          'sliding area = gates × (width + 0.20) × height',
    ),
    InfoSection(
      'Cost',
      'The area times the price per m², or the number of gates times the '
          'price per set.',
      formula: 'cost = area × price per m²  or  gates × price per set',
    ),
    InfoSection(
      'Swing hardware',
      'Two hinges per leaf, three when the gate is taller than 1.5 m; a drop '
          'bolt per leaf and a latch per gate.',
      formula: 'hinges = gates × leaves × (2 or 3)',
    ),
    InfoSection(
      'Sliding hardware',
      'Two wheels, three for a leaf longer than 4 m. The track is twice the '
          'leaf, in 1½" angle bar bought in 6 m lengths with 5% waste, fixed '
          'with ⅜" expansion anchors every 0.60 m. One set of top guide '
          'rollers, two stoppers and a latch per gate.',
      formula:
          'track = 2 × leaf\n'
          'angle bars = round up(gates × track × 1.05 ÷ 6)\n'
          'anchors = gates × (round up(track ÷ 0.60) + 1)',
    ),
    InfoSection(
      'Steel posts',
      'Two per gate, each the gate height plus 0.60 m, in 6 m lengths with '
          '5% waste, set in Class A concrete with 5% waste.',
      formula:
          'tube = round up(posts × (height + 0.60) × 1.05 ÷ 6)\n'
          'concrete = posts × 0.128 m³ × 1.05',
    ),
    InfoSection(
      'Paint',
      'Both faces of each leaf, two coats of enamel at 25 m² per 4 L with '
          '10% waste, thinned 1 part in 8 plus 0.5 L for cleaning.',
      formula: 'enamel = 2 × area × 2 coats ÷ 6.25 × 1.10 L',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/structural-steel-fabrication-erection-cost-per-kg-philippines/',
    'https://www.boysen.com.ph/products/boysen-quick-drying-enamel',
  ],
);

// ---------------------------------------------------------------------------
// Fascia board
// ---------------------------------------------------------------------------

/// Extra fascia for cuts, mitred corners and joints.
const fasciaAllowance = 0.05;

/// A 4' × 8' sheet is ripped into strips 2.44 m long.
const fasciaStripLength = 2.44;

/// A 12 ft board is 3.66 m long.
const boardLength12ft = 12 * 0.3048;

/// Fiber cement and metal fascia are fixed to two rows of 5 m metal
/// furring along the rafter ends.
const fasciaBackerRows = 2;
const furringLength = 5.0;

/// Board screws every 0.30 m and tek screws every 0.40 m, in two rows.
const fasciaScrewSpacing = 0.30;
const fasciaTekSpacing = 0.40;

/// Common nails for wood fascia: about 0.05 kg a metre.
const fasciaNails = 0.05;

String _fasciaMaterial(Map<String, String> s) => switch (s['material']) {
  'wood' => 'wood',
  'metal' => 'metal',
  _ => 'fiber_cement',
};

String _fasciaKey(Map<String, String> s) => switch (_fasciaMaterial(s)) {
  'wood' => woodFasciaKey(_fasciaWidth(s['width']).id),
  'metal' => 'fascia_metal_m',
  _ => 'fiber_cement_board_9',
};

final fascia = MaterialSpec(
  id: 'fascia',
  name: 'Fascia Board',
  category: MaterialCategory.architectural,
  icon: Icons.house_siding_outlined,
  blurb: 'Fiber cement, wood or metal fascia along the eaves',
  keywords: const [
    'fascia',
    'fascia board',
    'sinepa',
    'senepa',
    'eaves',
    'roof edge',
    'gilid ng bubong',
    'hardiflex',
    'fiber cement',
  ],
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Fascia length',
      unit: 'm',
      hint: 'All eaves and gable ends that get a fascia',
      typical: (min: 1, max: 300),
      max: 10000,
    ),
    priceField(
      'Price per sheet',
      visibleWhen: (s) => _fasciaMaterial(s) == 'fiber_cement',
    ),
    priceField(
      'Price per board',
      id: 'priceBoard',
      visibleWhen: (s) => _fasciaMaterial(s) == 'wood',
    ),
    priceField(
      'Price per metre',
      id: 'priceMetre',
      visibleWhen: (s) => _fasciaMaterial(s) == 'metal',
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'material',
      label: 'Fascia',
      initial: 'fiber_cement',
      leading: true,
      options: [
        ChoiceOption('fiber_cement', 'Fiber cement board 9 mm'),
        ChoiceOption('wood', 'Wood, 1" good lumber'),
        ChoiceOption('metal', 'Pre-painted metal'),
      ],
    ),
    ChoiceField(
      id: 'width',
      label: 'Fascia width',
      initial: '8',
      helper: 'The face of the fascia, from the plans',
      visibleWhen: (s) => _fasciaMaterial(s) != 'metal',
      options: [
        for (final w in fasciaWidths) ChoiceOption(w.id, w.label, w.width),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_fasciaKey(s)),
  compute: (input) {
    final length = input['length'];
    final selected = {for (final e in input.choices.entries) e.key: e.value.id};
    final material = _fasciaMaterial(selected);
    final needed = length * (1 + fasciaAllowance);
    final furring = ceilCount(fasciaBackerRows * needed / furringLength);
    final works = [WorkQuantity(ExteriorWork.fasciaBoard, _hundredths(length))];
    final details = [
      ResultDetail('Fascia length', formatLength(length)),
      ResultDetail(
        'With 5% for cuts and corners',
        formatLength(roundUp(needed)),
      ),
    ];
    const note =
        'The Roofing Sheets calculator does not count fascia. Paint the '
        'back and the cut edges of wood and fiber cement before fixing.';

    if (material == 'metal') {
      return CalcResult(
        label: 'Fascia cover, pre-painted metal',
        quantity: roundUp(needed),
        unit: QuantityUnit.metres,
        unitPrice: input['priceMetre'],
        itemKey: 'fascia_metal_m',
        details: details,
        companions: [
          buy('metal_furring', furring.toDouble()),
          buy('tek_screw', fasciaBackerRows * length / fasciaTekSpacing),
        ],
        note: note,
        works: works,
      );
    }
    final width = _fasciaWidth(input.choice('width').id);
    final paintArea = length * width.width;
    final paintDetail = ResultDetail(
      'Face to paint, ${formatNumber(width.width)} m wide',
      formatArea(roundUp(paintArea)),
    );
    final paintWorks = [
      ...works,
      WorkQuantity(Work.painting, _hundredths(paintArea), effort: 3),
    ];
    if (material == 'wood') {
      final boards = ceilCount(needed / boardLength12ft);
      return CalcResult(
        label: 'Fascia, wood 1" × ${width.label}',
        quantity: boards.toDouble(),
        unit: QuantityUnit.pieces,
        unitPrice: input['priceBoard'],
        itemKey: woodFasciaKey(width.id),
        details: [
          ...details,
          ResultDetail(
            'Boards of 12 ft (3.66 m)',
            formatCount(boards, 'board'),
          ),
          paintDetail,
        ],
        companions: [
          buy('nails', length * fasciaNails),
          ..._enamelPaint(paintArea),
        ],
        note: note,
        works: paintWorks,
      );
    }
    final perSheet = (1.22 / width.width + 1e-9).floor();
    final strips = ceilCount(needed / fasciaStripLength);
    final sheets = ceilCount(strips / perSheet);
    return CalcResult(
      label: 'Fascia, fiber cement 9 mm × ${width.label}',
      quantity: sheets.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      itemKey: 'fiber_cement_board_9',
      details: [
        ...details,
        ResultDetail('Strips of 2.44 m', formatCount(strips, 'strip')),
        ResultDetail('Strips cut from a 4 × 8 sheet', '$perSheet'),
        paintDetail,
      ],
      companions: [
        buy('metal_furring', furring.toDouble()),
        buy(
          'board_screws',
          fasciaBackerRows * length / fasciaScrewSpacing / 100,
        ),
        ..._latexPaint(paintArea),
      ],
      note: note,
      works: paintWorks,
    );
  },
  definitions: const [
    InfoSection(
      'Fascia',
      'The board along the ends of the rafters or trusses at the eaves, '
          'which closes the roof edge and often carries the gutter. Enter '
          'the length of every eave and gable end that gets one.',
    ),
    InfoSection(
      'Fiber cement',
      'Strips ripped from 9 mm fiber cement boards, screwed to two rows of '
          'metal furring along the rafter ends, then primed and painted with '
          'two coats of latex.',
    ),
    InfoSection(
      'Wood',
      'Good lumber 1" thick, S4S, in 12 ft boards nailed to the rafter '
          'ends, then primed and painted with two coats of enamel.',
    ),
    InfoSection(
      'Pre-painted metal',
      'A fascia cover roll-formed from pre-painted steel, sold by the metre '
          'and screwed to metal furring. It needs no paint.',
    ),
    InfoSection(
      'What the roofing calculator counts',
      'The Roofing Sheets calculator counts the sheets, purlins, screws, '
          'ridge and hip rolls, gutters and downspouts, but no fascia, '
          'soffit or wall flashing.',
    ),
  ],
  solution: const [
    InfoSection(
      'Fascia needed',
      'Add 5% to the length for cuts, mitred corners and joints.',
      formula: 'fascia = length × 1.05',
    ),
    InfoSection(
      'Fiber cement',
      'Strips 2.44 m long, as many to a 1.22 m wide sheet as the width '
          'allows: 8 at 6", 6 at 8", 4 at 10". Board screws every 0.30 m in '
          'two rows.',
      formula:
          'strips = round up(fascia ÷ 2.44)\n'
          'sheets = round up(strips ÷ strips per sheet)\n'
          'screws = length × 2 ÷ 0.30, in boxes of 100',
    ),
    InfoSection(
      'Wood',
      '12 ft boards (3.66 m) and about 0.05 kg of nails per metre.',
      formula: 'boards = round up(fascia ÷ 3.66)',
    ),
    InfoSection(
      'Metal',
      'Bought by the metre with the 5%, and fixed with tek screws every '
          '0.40 m in two rows.',
      formula: 'tek screws = length × 2 ÷ 0.40',
    ),
    InfoSection(
      'Furring and paint',
      'Fiber cement and metal fascia take two rows of 5 m metal furring. '
          'Painted fascia gets one coat of primer and two of latex (fiber '
          'cement) or enamel (wood) on its face, with 10% waste.',
      formula:
          'furring = round up(2 × fascia ÷ 5)\n'
          'face = length × width',
    ),
    InfoSection(
      'Cost',
      'Sheets, boards or metres times their price; furring, screws, nails '
          'and paint are priced from your price book and added to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'https://www.jameshardie.com.ph/',
    'https://aedoconstruction.com/blog/roof-gutter-downspout-cost-philippines/',
    'https://www.boysen.com.ph/products/boysen-permacoat-latex',
  ],
);

// ---------------------------------------------------------------------------
// Eaves soffit
// ---------------------------------------------------------------------------

/// Fiber cement soffit boards are bought with 10% for ripping into
/// strips.
const soffitBoardWaste = 0.10;

/// Furring runs along the eaves at most 0.40 m apart under fiber cement
/// and 0.60 m under PVC panels, with cross pieces every 1.2 m.
const soffitFurringSpacingBoard = 0.40;
const soffitFurringSpacingPanel = 0.60;
const soffitCrossSpacing = 1.2;

/// PVC panels are 0.20 m wide and 3.0 m long, bought with 5% waste.
const pvcPanelWidth = 0.20;
const pvcPanelLength = 3.0;
const pvcPanelWaste = 0.05;

/// Wall angle and PVC trim come in 3 m lengths.
const trimLength = 3.0;

bool _pvcSoffit(Map<String, String> s) => s['material'] == 'pvc';

final soffit = MaterialSpec(
  id: 'soffit',
  name: 'Eaves Soffit',
  category: MaterialCategory.architectural,
  icon: Icons.wb_shade_outlined,
  blurb: 'Fiber cement or PVC under the roof overhang, with framing',
  keywords: const [
    'soffit',
    'eaves',
    'kisame sa labas',
    'ambi',
    'overhang',
    'PVC panel',
    'fiber cement',
    'hardiflex',
    'spandrel',
  ],
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Eaves length',
      unit: 'm',
      hint: 'All eaves with a soffit, measured along the fascia',
      typical: (min: 1, max: 300),
      max: 10000,
    ),
    const NumberField(
      id: 'overhang',
      label: 'Overhang',
      unit: 'm',
      hint: 'Level width from the wall to the fascia, usually 0.60–1.00 m',
      typical: (min: 0.2, max: 2),
      max: 10,
    ),
    priceField('Price per sheet', visibleWhen: (s) => !_pvcSoffit(s)),
    priceField('Price per panel', id: 'pricePanel', visibleWhen: _pvcSoffit),
  ],
  choices: const [
    ChoiceField(
      id: 'material',
      label: 'Soffit',
      initial: 'fiber_cement',
      leading: true,
      options: [
        ChoiceOption('fiber_cement', 'Fiber cement board 4.5 mm, painted'),
        ChoiceOption('pvc', 'PVC soffit panels'),
      ],
    ),
  ],
  priceRef: (s) =>
      PriceRef(_pvcSoffit(s) ? 'pvc_soffit_panel' : 'fiber_cement_board'),
  compute: (input) {
    final length = input['length'];
    final overhang = input['overhang'];
    final pvc = input.chose('material', 'pvc');
    final area = length * overhang;
    final spacing = pvc ? soffitFurringSpacingPanel : soffitFurringSpacingBoard;
    final lines = ceilCount(overhang / spacing) + 1;
    final cross = ceilCount(length / soffitCrossSpacing) + 1;
    final furringRun = lines * length + cross * overhang;
    final furring = ceilCount(furringRun * 1.05 / furringLength);
    final details = [
      ResultDetail(
        'Soffit, ${formatLength(length)} × ${formatLength(overhang)}',
        formatArea(roundUp(area)),
      ),
      ResultDetail(
        'Furring lines along the eaves, ${formatNumber(spacing)} m apart',
        '$lines',
      ),
      ResultDetail('Cross pieces every 1.2 m', '$cross'),
      ResultDetail(
        'Metal furring, + 5%, in 5 m pieces',
        formatCount(furring, 'piece'),
      ),
    ];
    const note =
        'Leave vents or a gap at the wall where the roof space needs air. '
        'The Roofing Sheets calculator does not count the soffit.';
    final works = [WorkQuantity(ExteriorWork.eavesSoffit, _hundredths(area))];

    if (pvc) {
      final strips = ceilCount(length / pvcPanelWidth);
      final int base;
      if (overhang <= pvcPanelLength + 1e-9) {
        final perPanel = (pvcPanelLength / overhang + 1e-9).floor();
        base = ceilCount(strips / perPanel);
      } else {
        base = strips * ceilCount(overhang / pvcPanelLength);
      }
      final panels = withWaste(base, pvcPanelWaste);
      return CalcResult(
        label: 'Eaves soffit, PVC panels',
        area: area,
        quantity: panels.total.toDouble(),
        unit: QuantityUnit.pieces,
        unitPrice: input['pricePanel'],
        itemKey: 'pvc_soffit_panel',
        details: [
          ...details,
          ResultDetail('Strips 0.20 m wide across the overhang', '$strips'),
          ResultDetail('Panels of 3.0 m', formatCount(panels.base, 'panel')),
          ...wasteDetail(panels, pvcPanelWaste, QuantityUnit.pieces),
        ],
        companions: [
          buy('metal_furring', furring.toDouble()),
          buy('pvc_soffit_trim', 2 * length * 1.05 / trimLength),
          buy('board_screws', strips * lines / 100),
        ],
        note: note,
        works: works,
      );
    }
    final sheets = ceilCount(area * (1 + soffitBoardWaste) / sheetArea);
    return CalcResult(
      label: 'Eaves soffit, fiber cement 4.5 mm',
      area: area,
      quantity: sheets.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      itemKey: 'fiber_cement_board',
      details: [
        ...details,
        ResultDetail(
          'Boards of 2.98 m², + 10% for ripping',
          formatCount(sheets, 'sheet'),
        ),
      ],
      companions: [
        buy('metal_furring', furring.toDouble()),
        buy('wall_angle', length * 1.05 / trimLength),
        buy('board_screws', area * screwsPerM2 / 100),
        ..._latexPaint(area),
      ],
      note: note,
      works: [
        ...works,
        WorkQuantity(Work.painting, _hundredths(area), effort: 3),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Eaves soffit',
      'The ceiling under the roof overhang, from the wall to the fascia. '
          'Measure the eaves along the fascia; the corners are then counted '
          'a little generously.',
    ),
    InfoSection(
      'Fiber cement',
      '4.5 mm fiber cement boards ripped to the overhang, screwed to metal '
          'furring every 0.40 m, then primed and painted with two coats of '
          'latex. A wall angle finishes the edge at the wall.',
    ),
    InfoSection(
      'PVC panels',
      'Interlocking PVC panels 0.20 m wide and 3.0 m long, cut to run from '
          'the wall to the fascia, screwed to furring every 0.60 m and '
          'finished with J-channel trim at the wall and the fascia. They '
          'need no paint.',
    ),
    InfoSection(
      'Framing',
      'Metal furring along the eaves, one line at the wall, one at the '
          'fascia and more between them, with cross pieces every 1.2 m '
          'fixed to the rafters or truss tails.',
    ),
    InfoSection(
      'What the roofing calculator counts',
      'The Roofing Sheets calculator counts the sheets, purlins, screws, '
          'ridge and hip rolls, gutters and downspouts, but no soffit or '
          'fascia.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area',
      'The eaves length times the overhang.',
      formula: 'area = eaves length × overhang',
    ),
    InfoSection(
      'Fiber cement',
      'The area plus 10% for ripping, in 1.22 × 2.44 m boards, with 14 board '
          'screws per m².',
      formula:
          'sheets = round up(area × 1.10 ÷ 2.977)\n'
          'screws = area × 14, in boxes of 100',
    ),
    InfoSection(
      'PVC panels',
      'One 0.20 m strip across the overhang for every 0.20 m of eaves, as '
          'many strips to a 3.0 m panel as fit, plus 5%. A screw where each '
          'strip crosses a furring line, and J-channel trim along both edges.',
      formula:
          'strips = round up(eaves ÷ 0.20)\n'
          'panels = round up(strips ÷ round down(3.0 ÷ overhang)) + 5%\n'
          'trim = round up(2 × eaves × 1.05 ÷ 3)',
    ),
    InfoSection(
      'Furring',
      'Lines along the eaves at most 0.40 m apart (0.60 m under PVC), and '
          'cross pieces every 1.2 m, plus 5%, in 5 m pieces.',
      formula:
          'lines = round up(overhang ÷ spacing) + 1\n'
          'cross = round up(eaves ÷ 1.2) + 1\n'
          'furring = round up((lines × eaves + cross × overhang) × 1.05 ÷ 5)',
    ),
    InfoSection(
      'Paint',
      'Fiber cement gets one coat of primer (25 m² per 4 L) and two of latex '
          '(30 m² per 4 L), with 10% waste.',
      formula:
          'primer = area ÷ 6.25 × 1.10 L\n'
          'latex = area × 2 ÷ 7.5 × 1.10 L',
    ),
    InfoSection(
      'Cost',
      'Sheets or panels times their price; furring, trim, screws and paint '
          'are priced from your price book and added to the total.',
      formula: 'cost = sheets or panels × price + other materials',
    ),
  ],
  references: const [
    'https://www.jameshardie.com.ph/',
    'https://aedoconstruction.com/blog/ceiling-installation-repair-cost-philippines/',
  ],
);

// ---------------------------------------------------------------------------
// Roof flashing
// ---------------------------------------------------------------------------

/// Tek screws and wall plugs every 0.40 m along each row.
const flashingFixingSpacing = 0.40;

/// A 300 ml tube of sealant runs a bead about 6 m long.
const sealantBeadPerTube = 6.0;

final flashing = MaterialSpec(
  id: 'flashing',
  name: 'Roof Flashing',
  category: MaterialCategory.architectural,
  icon: Icons.water_drop_outlined,
  blurb: 'Wall, valley, gable or ridge flashing, with sealant and screws',
  keywords: const [
    'flashing',
    'roof flashing',
    'valley',
    'lambak',
    'wall flashing',
    'apron',
    'barge',
    'gable',
    'ridge roll',
    'hip roll',
    'sealant',
    'tulo',
    'bubong',
  ],
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Flashing length',
      unit: 'm',
      hint: 'Along the wall, valley, gable or ridge',
      typical: (min: 0.5, max: 200),
      max: 10000,
    ),
    priceField('Price per piece'),
  ],
  choices: [
    ChoiceField(
      id: 'type',
      label: 'Flashing',
      initial: 'wall',
      leading: true,
      helper:
          'Ridge and hip rolls are already in the Roofing Sheets calculator',
      options: [for (final f in flashings) ChoiceOption(f.id, f.label)],
    ),
  ],
  priceRef: (s) => PriceRef(_flashing(s['type']).key),
  compute: (input) {
    final length = input['length'];
    final f = _flashing(input.choice('type').id);
    final wall = f.id == 'wall';
    final pieces = ceilCount(length / ridgeRollCover);
    final laps = pieces - 1;
    final sealant = laps * f.girth + (wall ? length : 0);
    final fixings = ceilCount(length / flashingFixingSpacing) + 1;
    return CalcResult(
      label: f.label,
      quantity: pieces.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      itemKey: f.key,
      details: [
        ResultDetail('Flashing length', formatLength(length)),
        ResultDetail(
          'Pieces of 2.4 m lapped 0.15 m',
          formatCount(pieces, 'piece'),
        ),
        ResultDetail(
          wall
              ? 'Sealant along the wall and at ${formatCount(laps, 'lap')}'
              : 'Sealant at ${formatCount(laps, 'lap')}',
          formatLength(roundUp(sealant)),
        ),
        ResultDetail(
          'Tek screws, ${f.rows == 1 ? '1 row' : '${f.rows} rows'} '
          'every 0.40 m',
          formatNumber((f.rows * fixings).toDouble()),
        ),
      ],
      companions: [
        if (sealant > 0) buy('sealant', sealant / sealantBeadPerTube),
        buy('tek_screw', (f.rows * fixings).toDouble()),
        if (wall) buy('wall_plug', fixings.toDouble()),
      ],
      note:
          'The Roofing Sheets calculator already counts ridge and hip rolls '
          'and gutters; do not enter them again here for the same roof.',
      works: [WorkQuantity(ExteriorWork.roofFlashing, _hundredths(length))],
    );
  },
  definitions: const [
    InfoSection(
      'Flashing',
      'Bent strips of pre-painted steel that keep water out where the roof '
          'meets a wall, where two roof slopes meet, and along the edges. '
          'Each piece is 2.4 m long and laps the next by 0.15 m.',
    ),
    InfoSection(
      'Kinds',
      'Wall or apron flashing runs where a roof meets a wall, tucked into '
          'the wall and sealed. Valley flashing lines the trough where two '
          'slopes meet. Gable or barge flashing caps the sloping edge of a '
          'gable. Ridge and hip rolls cap the top of the roof and the hips.',
    ),
    InfoSection(
      'Already in the roofing calculator',
      'The Roofing Sheets calculator counts ridge and hip rolls for the '
          'ridge and hips it measures, and gutters and downspouts. Use the '
          'ridge option here only for a roof that was not estimated there. '
          'Valley, wall and gable flashing are not counted there.',
    ),
    InfoSection(
      'Sealant and screws',
      'Polyurethane or silicone sealant closes each lap and, on wall '
          'flashing, the top edge against the wall. Tek screws with washers '
          'fix the flashing to the roof every 0.40 m; wall flashing is also '
          'plugged and screwed to the wall.',
    ),
  ],
  solution: const [
    InfoSection(
      'Pieces',
      'Each 2.4 m piece covers 2.25 m once lapped.',
      formula: 'pieces = round up(length ÷ 2.25)',
    ),
    InfoSection(
      'Cost',
      'Multiply the pieces by the price per piece.',
      formula: 'cost = pieces × price per piece',
    ),
    InfoSection(
      'Sealant',
      'A bead across every lap, as long as the girth (0.30 m wall, 0.60 m '
          'valley, 0.40 m gable, 0.45 m ridge), plus the full length of wall '
          'flashing. A 300 ml tube runs about 6 m.',
      formula:
          'sealant = (pieces − 1) × girth (+ length for wall flashing)\n'
          'tubes = round up(sealant ÷ 6)',
    ),
    InfoSection(
      'Screws and plugs',
      'A row of tek screws every 0.40 m: one row on wall flashing, two on '
          'the others. Wall flashing also takes a wall plug with screw every '
          '0.40 m. Sealant, screws and plugs are priced from your price book '
          'and added to the total.',
      formula:
          'per row = round up(length ÷ 0.40) + 1\n'
          'tek screws = rows × per row',
    ),
  ],
  references: const [
    'https://www.ugc.ph/product/durarib/',
    'https://roofonline.com/roof-pitch-factor/',
  ],
);
