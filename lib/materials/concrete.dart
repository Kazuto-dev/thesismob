import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';

// Reinforced concrete: slabs, footings, columns and beams. Each works out
// the cement, sand and gravel for its volume, the reinforcing bars cut from
// 6 m stock, tie wire and, where needed, plywood forms with their lumber
// frames and nails.

/// Concrete cover to the bars: against earth, formed members, slabs.
const coverEarth = 0.075;
const coverFormed = 0.040;
const coverSlab = 0.020;

/// Fajardo's board feet of 2"×2" frame lumber per plywood sheet of forms.
const columnFrameLumber = {'6': 29.67, '12': 20.33};
const beamFrameLumber = {'6': 25.06, '12': 18.66};

/// Joists, stringers, shores and bracing under a suspended slab, per sheet
/// of plywood: about 10 board feet per m² of soffit.
const slabFrameLumber = 28.8;

/// Common nails per m² of form contact area.
const formNails = 0.20;

/// Each 135° tie or stirrup hook takes max(6d, 75 mm) plus about 3d for
/// the bend.
double hookLength(int barMm) =>
    math.max(6 * barMm / 1000, 0.075) + 3 * barMm / 1000;

/// Stock bars needed for [pieces] bars each [length] metres long. Shorter
/// bars are cut several from one 6 m bar; longer ones are spliced with
/// [lap] metres of overlap.
int stockBars(int pieces, double length, double lap) {
  if (pieces <= 0 || length <= 0) return 0;
  if (length <= rebarStockLength) {
    final perStock = (rebarStockLength / length + 1e-9).floor();
    return ceilCount(pieces / perStock);
  }
  final splices = ceilCount(length / rebarStockLength) - 1;
  return ceilCount(pieces * (length + splices * lap) / rebarStockLength);
}

final _classChoice = ChoiceField(
  id: 'class',
  label: 'Concrete mix',
  initial: 'A',
  helper: 'Fajardo site-mix classes: cement : sand : gravel',
  options: [
    for (final m in concreteMixes)
      ChoiceOption(m.id, '${m.label}, ${m.ratio}', m.cement),
  ],
);

final _concreteWaste = wasteField(
  initial: '5',
  helper: 'Spillage and uneven ground',
  percents: const [0, 5, 10],
);

const _lapChoice = ChoiceField(
  id: 'lap',
  label: 'Lap splice',
  initial: '40',
  helper: '40 bar diameters for Grade 33–40 bars; 60 for Grade 60',
  options: [
    ChoiceOption('40', '40 d', 40),
    ChoiceOption('50', '50 d', 50),
    ChoiceOption('60', '60 d', 60),
  ],
);

const _formPlywood = ChoiceField(
  id: 'plywood',
  label: 'Form plywood',
  initial: '12',
  options: [
    ChoiceOption('6', '6 mm (¼") marine'),
    ChoiceOption('12', '12 mm (½") marine'),
  ],
);

ChoiceField _reuse(String initial) => ChoiceField(
  id: 'reuse',
  label: 'Forms used',
  initial: initial,
  helper: 'Plywood forms are stripped and reused for the next pour',
  options: const [
    ChoiceOption('1', 'Once', 1),
    ChoiceOption('2', '2 times', 2),
    ChoiceOption('3', '3 times', 3),
  ],
);

ChoiceField _barSize(
  String id,
  String label,
  List<int> sizes,
  String initial,
) => ChoiceField(
  id: id,
  label: label,
  initial: initial,
  options: [for (final mm in sizes) ChoiceOption('$mm', '$mm mm', mm * 1.0)],
);

ChoiceField _spacing(
  String id,
  String label,
  List<double> spacings,
  String initial, {
  String? helper,
}) => ChoiceField(
  id: id,
  label: label,
  initial: initial,
  helper: helper,
  options: [
    for (final s in spacings)
      ChoiceOption(formatNumber(s), '${formatNumber(s * 100)} cm', s),
  ],
);

const _cementPrice = NumberField(
  id: 'price',
  label: 'Price per bag of cement',
  unit: '₱',
  hint: '40 kg bag',
  isPrice: true,
  max: 100000,
);

PriceRef? _cementRef(Map<String, String> _) => const PriceRef('cement_40kg');

/// Cement, sand and gravel for [volume] m³ of [mix] with [waste].
({int cement, double sand, double gravel, double volume}) _mix(
  double volume,
  ConcreteMix mix,
  double waste,
) {
  final v = volume * (1 + waste);
  return (
    cement: ceilCount(v * mix.cement),
    sand: v * mix.sand,
    gravel: v * mix.gravel,
    volume: v,
  );
}

List<ResultDetail> _mixDetails(
  double volume,
  ConcreteMix mix,
  double waste,
  int cement,
) => [
  ResultDetail('Concrete volume', formatVolume(roundUp(volume, 3))),
  if (waste > 0)
    ResultDetail(
      'With ${formatPercent(waste)} waste',
      formatVolume(roundUp(volume * (1 + waste), 3)),
    ),
  ResultDetail(
    '${mix.label} cement, ${formatNumber(mix.cement)} bags per m³',
    formatCount(cement, 'bag'),
  ),
];

/// Plywood, frame lumber and nails for [area] m² of form contact area.
List<Companion> _forms(
  double area, {
  required String plywood,
  required double uses,
  required double lumberPerSheet,
}) {
  if (area <= 0) return const [];
  final sheets = math.max(1, ceilCount(area / sheetFormArea / uses));
  return [
    buy(marinePlywoodKey(plywood), sheets.toDouble()),
    buy('coco_lumber', sheets * lumberPerSheet),
    buy('nails', area * formNails),
  ];
}

List<ResultDetail> _formDetails(double area, double uses) => [
  ResultDetail('Form contact area', formatArea(roundUp(area))),
  if (uses > 1) ResultDetail('Forms reused', '× ${formatNumber(uses)}'),
];

Companion _tieWire(int ties, int barMm) =>
    buy('tie_wire', ties * tieWirePerTie(barMm) / tieWireMetresPerKg);

final slab = MaterialSpec(
  id: 'slab',
  name: 'Concrete Slab',
  category: MaterialCategory.structural,
  icon: Icons.layers_outlined,
  blurb: 'Floor slab on fill or suspended, with bars and forms',
  keywords: const [
    'slab',
    'floor',
    'sahig',
    'buhos',
    'concrete',
    'semento',
    'flooring',
    'rebar',
  ],
  numbers: const [
    NumberField(id: 'length', label: 'Slab length', unit: 'm', max: 1000),
    NumberField(id: 'width', label: 'Slab width', unit: 'm', max: 1000),
    NumberField(
      id: 'thickness',
      label: 'Thickness',
      unit: 'm',
      hint: '0.10 m for a house floor',
      initial: '0.10',
      max: 2,
    ),
    _cementPrice,
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Slab',
      initial: 'ground',
      leading: true,
      options: [
        ChoiceOption('ground', 'On fill (ground floor)'),
        ChoiceOption('suspended', 'Suspended (upper floor)'),
      ],
    ),
    ChoiceField(
      id: 'class',
      label: 'Concrete mix',
      initial: 'auto',
      helper: 'Class B on fill and Class A suspended is usual',
      options: [
        const ChoiceOption('auto', 'Usual for the slab'),
        for (final m in concreteMixes)
          ChoiceOption(m.id, '${m.label}, ${m.ratio}', m.cement),
      ],
    ),
    _barSize('bar', 'Bar size', const [10, 12], '10'),
    ChoiceField(
      id: 'spacing',
      label: 'Bar spacing, both ways',
      initial: 'auto',
      helper: 'Follow the plans. Usual: 40 cm on fill, 20 cm suspended',
      options: [
        const ChoiceOption('auto', 'Usual for the slab'),
        for (final s in const [0.15, 0.20, 0.25, 0.30, 0.40])
          ChoiceOption(formatNumber(s), '${formatNumber(s * 100)} cm', s),
        const ChoiceOption('none', 'No bars'),
      ],
    ),
    ChoiceField(
      id: 'bedding',
      label: 'Gravel bed',
      initial: '0.1',
      visibleWhen: (s) => s['type'] != 'suspended',
      options: const [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.05', '5 cm', 0.05),
        ChoiceOption('0.1', '10 cm', 0.10),
        ChoiceOption('0.15', '15 cm', 0.15),
      ],
    ),
    _formPlywood.copyWithVisibility((s) => s['type'] == 'suspended'),
    _reuse('1').copyWithVisibility((s) => s['type'] == 'suspended'),
    _lapChoice,
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final thickness = input['thickness'];
    final suspended = input.chose('type', 'suspended');
    final classId = input.choice('class').id == 'auto'
        ? (suspended ? 'A' : 'B')
        : input.choice('class').id;
    final mix = concreteMix(classId);
    final waste = input.choice('waste').value;
    final area = length * width;
    final volume = area * thickness;
    final concrete = _mix(volume, mix, waste);

    final barMm = int.parse(input.choice('bar').id);
    final spacingOption = input.choice('spacing');
    final spacing = spacingOption.id == 'auto'
        ? (suspended ? 0.20 : 0.40)
        : spacingOption.value;
    final lap = input.choice('lap').value * barMm / 1000;
    final cover = suspended ? coverSlab : coverFormed;
    var bars = 0;
    var ties = 0;
    var alongLength = 0;
    var alongWidth = 0;
    if (spacingOption.id != 'none') {
      alongLength = ((width - 2 * cover) / spacing + 1e-9).floor() + 1;
      alongWidth = ((length - 2 * cover) / spacing + 1e-9).floor() + 1;
      bars =
          stockBars(alongLength, length - 2 * cover, lap) +
          stockBars(alongWidth, width - 2 * cover, lap);
      ties = alongLength * alongWidth;
    }
    final bedding = suspended ? 0.0 : input.choice('bedding').value;
    final uses = suspended ? input.choice('reuse').value : 1.0;
    final forms = suspended
        ? _forms(
            area,
            plywood: input.choice('plywood').id,
            uses: uses,
            lumberPerSheet: slabFrameLumber,
          )
        : const <Companion>[];

    return CalcResult(
      label:
          '${suspended ? 'Suspended slab' : 'Slab on fill'} '
          '${formatNumber(length)} × ${formatNumber(width)} m, '
          '${formatNumber(thickness * 1000)} mm, ${mix.label}',
      area: area,
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ResultDetail('Slab area', formatArea(area)),
        ..._mixDetails(volume, mix, waste, concrete.cement),
        if (bars > 0) ...[
          ResultDetail(
            '$barMm mm bars @ ${formatNumber(spacing * 100)} cm',
            '$alongLength + $alongWidth runs',
          ),
          ResultDetail('6 m bars to buy', formatCount(bars, 'bar')),
        ],
        if (suspended) ..._formDetails(area, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        if (bedding > 0) buy('gravel_bedding', area * bedding),
        if (bars > 0) buy(rebarKey(barMm), bars.toDouble()),
        if (ties > 0) _tieWire(ties, barMm),
        ...forms,
      ],
      note:
          'Quantities follow the dimensions entered. Bar sizes and spacing '
          'must follow the structural plans.',
    );
  },
  definitions: const [
    InfoSection(
      'Slab on fill or suspended',
      'A slab on fill rests on compacted soil and a gravel bed. A suspended '
          'slab spans between beams on an upper floor and needs plywood '
          'forms and shoring underneath until it cures.',
    ),
    InfoSection(
      'Concrete mix',
      'Site-mixed classes from Fajardo\'s tables, by volume of cement, sand '
          'and gravel. Class A (1:2:4) is used for suspended slabs, beams, '
          'columns and footings; Class B (1:2.5:5) or C (1:3:6) for slabs on '
          'fill. These are not the DPWH classes, which are set by strength.',
    ),
    InfoSection(
      'Bars and spacing',
      'Slabs are reinforced with bars both ways. Typical house plans show '
          '10 mm bars at 40 cm on fill and 10–12 mm at 15–20 cm for '
          'suspended slabs. Always follow the plans.',
    ),
    InfoSection(
      'Lap splice',
      'Bars longer than 6 m are joined by overlapping them. 40 bar '
          'diameters suits Grade 33–40 bars in ordinary concrete; Grade 60 '
          'bars need about 60.',
    ),
    InfoSection(
      'Forms used',
      'Plywood and lumber forms are reused for later pours. A whole slab '
          'poured at once uses its forms once.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Multiply the slab area by its thickness, add the waste allowance, '
          'then multiply by the mix factors. Class A takes 9 bags of cement, '
          '0.5 m³ of sand and 1.0 m³ of gravel per m³; Class B 7.5 bags and '
          'Class C 6 bags with the same sand and gravel.',
      formula:
          'volume = length × width × thickness × (1 + waste)\n'
          'cement = round up(volume × bags per m³)\n'
          'sand = volume × 0.5;  gravel = volume × 1.0, bought by the '
          'half m³',
    ),
    InfoSection(
      'Bars',
      'Bars run both ways inside a cover of 40 mm on fill or 20 mm when '
          'suspended. Runs up to 6 m are cut whole from 6 m bars, as many '
          'as fit, and the offcuts are not reused. Longer runs are spliced '
          'with the chosen lap.',
      formula:
          'runs = round down((width − 2 × cover) ÷ spacing) + 1\n'
          'run ≤ 6 m: bars = round up(runs ÷ round down(6 ÷ run length))\n'
          'run > 6 m: bars = round up(runs × (run + laps) ÷ 6)',
    ),
    InfoSection(
      'Tie wire',
      'Every crossing of two bars is tied with about 30 cm of #16 wire; '
          'a kilogram is about 53 m.',
      formula: 'tie wire = crossings × 0.30 m ÷ 53 m per kg',
    ),
    InfoSection(
      'Gravel bed and forms',
      'A slab on fill sits on a gravel bed of the chosen thickness. A '
          'suspended slab needs plywood for its whole underside, about 10 '
          'board feet of lumber per m² for joists and shores, and 0.20 kg of '
          'nails per m².',
      formula:
          'plywood = round up(area ÷ 2.88 ÷ uses)\n'
          'lumber = plywood × 28.8 bd ft;  nails = area × 0.20 kg',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2',
    'https://aedoconstruction.com/blog/concrete-mix-ratio-philippines/',
    'NSCP 2015, Table 420.6.1.3.1 (concrete cover)',
  ],
);

final footing = MaterialSpec(
  id: 'footing',
  name: 'Footings',
  category: MaterialCategory.structural,
  icon: Icons.foundation,
  blurb: 'Isolated column footings with a bar mat',
  keywords: const ['footing', 'pundasyon', 'foundation', 'pad', 'concrete'],
  numbers: const [
    NumberField(
      id: 'count',
      label: 'Number of footings',
      unit: 'pcs',
      integer: true,
      max: 10000,
    ),
    NumberField(id: 'length', label: 'Footing length', unit: 'm', max: 20),
    NumberField(id: 'width', label: 'Footing width', unit: 'm', max: 20),
    NumberField(
      id: 'thickness',
      label: 'Thickness',
      unit: 'm',
      hint: 'Usually 0.25–0.30 m',
      initial: '0.25',
      max: 5,
    ),
    _cementPrice,
  ],
  choices: [
    _classChoice,
    _barSize('bar', 'Bar size', const [12, 16, 20], '12'),
    _spacing('spacing', 'Bar spacing, both ways', const [
      0.10,
      0.15,
      0.20,
      0.25,
    ], '0.15'),
    const ChoiceField(
      id: 'sides',
      label: 'Side forms',
      initial: 'none',
      helper: 'Footings are often cast against the excavated soil',
      options: [
        ChoiceOption('none', 'None, cast against soil'),
        ChoiceOption('plywood', 'Plywood forms'),
      ],
    ),
    _formPlywood.copyWithVisibility((s) => s['sides'] == 'plywood'),
    _reuse('3').copyWithVisibility((s) => s['sides'] == 'plywood'),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final count = input['count'].round();
    final length = input['length'];
    final width = input['width'];
    final thickness = input['thickness'];
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final volume = count * length * width * thickness;
    final concrete = _mix(volume, mix, waste);

    final barMm = int.parse(input.choice('bar').id);
    final spacing = input.choice('spacing').value;
    final alongLength = ((width - 2 * coverEarth) / spacing + 1e-9).floor() + 1;
    final alongWidth = ((length - 2 * coverEarth) / spacing + 1e-9).floor() + 1;
    final bars =
        stockBars(count * alongLength, length - 2 * coverEarth, 0) +
        stockBars(count * alongWidth, width - 2 * coverEarth, 0);
    final ties = count * alongLength * alongWidth;
    final formed = input.chose('sides', 'plywood');
    final formArea = formed ? count * 2 * (length + width) * thickness : 0.0;
    final uses = formed ? input.choice('reuse').value : 1.0;

    return CalcResult(
      label:
          '${formatCount(count, 'footing')} '
          '${formatNumber(length)} × ${formatNumber(width)} × '
          '${formatNumber(thickness)} m, ${mix.label}',
      area: count * length * width,
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ..._mixDetails(volume, mix, waste, concrete.cement),
        ResultDetail(
          'Bars per footing, $barMm mm',
          '$alongLength + $alongWidth',
        ),
        ResultDetail('6 m bars to buy', formatCount(bars, 'bar')),
        if (formed) ..._formDetails(formArea, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        buy(rebarKey(barMm), bars.toDouble()),
        _tieWire(ties, barMm),
        if (formed)
          ..._forms(
            formArea,
            plywood: input.choice('plywood').id,
            uses: uses,
            lumberPerSheet: columnFrameLumber[input.choice('plywood').id]!,
          ),
      ],
      note:
          'Column dowels are counted with the columns. Footing size, bars '
          'and spacing must follow the structural plans.',
    );
  },
  definitions: const [
    InfoSection(
      'Isolated footing',
      'A square or rectangular pad of reinforced concrete under each '
          'column that spreads its load on the soil. Enter footings of the '
          'same size together.',
    ),
    InfoSection(
      'Bar mat',
      'A grid of bars both ways near the bottom of the footing, 75 mm above '
          'the soil. Typical house plans use 12 or 16 mm bars at 15 cm.',
    ),
    InfoSection(
      'Side forms',
      'Footings are usually poured against the sides of the excavation. '
          'Where the soil is loose, plywood forms hold the concrete.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Volume of all footings with the waste allowance, times the mix '
          'factors per m³.',
      formula:
          'volume = count × length × width × thickness × (1 + waste)\n'
          'cement = round up(volume × bags per m³)',
    ),
    InfoSection(
      'Bars',
      'With 75 mm cover all round, each footing has a run of bars each way. '
          'Several short bars are cut from each 6 m bar.',
      formula:
          'bars each way = round down((side − 0.15) ÷ spacing) + 1\n'
          'stock bars = pieces ÷ round down(6 ÷ piece length)',
    ),
    InfoSection(
      'Tie wire',
      'About 30 cm of wire for each crossing up to 12 mm bars, 40 cm for '
          'larger bars, at 53 m per kg.',
      formula: 'tie wire = crossings × length per tie ÷ 53',
    ),
    InfoSection(
      'Side forms',
      'When chosen, plywood lines the four sides of each footing, reused '
          'the chosen number of times, with the column table\'s frame lumber '
          'per sheet and 0.20 kg of nails per m².',
      formula:
          'form area = count × 2 × (length + width) × thickness\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2',
    'NSCP 2015, Table 420.6.1.3.1 (concrete cover)',
  ],
);

final column = MaterialSpec(
  id: 'column',
  name: 'Columns',
  category: MaterialCategory.structural,
  icon: Icons.view_column_outlined,
  blurb: 'Reinforced concrete columns with ties and forms',
  keywords: const ['column', 'poste', 'haligi', 'concrete', 'rebar', 'ties'],
  numbers: const [
    NumberField(
      id: 'count',
      label: 'Number of columns',
      unit: 'pcs',
      integer: true,
      max: 10000,
    ),
    NumberField(id: 'width', label: 'Column width', unit: 'm', max: 5),
    NumberField(id: 'depth', label: 'Column depth', unit: 'm', max: 5),
    NumberField(
      id: 'height',
      label: 'Column height',
      unit: 'm',
      hint: 'From the top of the footing to the beam',
      max: 100,
    ),
    _cementPrice,
  ],
  choices: [
    _classChoice,
    const ChoiceField(
      id: 'bars',
      label: 'Main bars per column',
      initial: '4',
      options: [
        ChoiceOption('4', '4 bars', 4),
        ChoiceOption('6', '6 bars', 6),
        ChoiceOption('8', '8 bars', 8),
        ChoiceOption('12', '12 bars', 12),
      ],
    ),
    _barSize('bar', 'Main bar size', const [12, 16, 20, 25], '16'),
    _spacing(
      'tieSpacing',
      '10 mm tie spacing',
      const [0.10, 0.15, 0.20],
      '0.15',
      helper: 'Closer near the ends of the column in earthquake zones',
    ),
    _lapChoice,
    _formPlywood,
    _reuse('3'),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final count = input['count'].round();
    final width = input['width'];
    final depth = input['depth'];
    final height = input['height'];
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final volume = count * width * depth * height;
    final concrete = _mix(volume, mix, waste);

    final barMm = int.parse(input.choice('bar').id);
    final perColumn = input.choice('bars').value.round();
    final lap = input.choice('lap').value * barMm / 1000;
    final mainLength = height + lap;
    final mainBars = stockBars(count * perColumn, mainLength, lap);

    const tieMm = 10;
    final spacing = input.choice('tieSpacing').value;
    final tiesEach = (height / spacing + 1e-9).floor() + 1;
    final tieLength =
        2 * (width - 2 * coverFormed) +
        2 * (depth - 2 * coverFormed) +
        2 * hookLength(tieMm);
    if (width - 2 * coverFormed <= 0 || depth - 2 * coverFormed <= 0) {
      throw ArgumentError('Columns must be wider than their 40 mm cover');
    }
    final tieBars = stockBars(count * tiesEach, tieLength, 0);
    final crossings = count * tiesEach * perColumn;
    final tieWire = buy(
      'tie_wire',
      crossings * tieWirePerTie(barMm) / tieWireMetresPerKg,
    );

    final formArea = count * (2 * (width + depth) + 0.20) * height;
    final uses = input.choice('reuse').value;
    final plywood = input.choice('plywood').id;

    return CalcResult(
      label:
          '${formatCount(count, 'column')} '
          '${formatNumber(width)} × ${formatNumber(depth)} m × '
          '${formatNumber(height)} m, ${mix.label}',
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ..._mixDetails(volume, mix, waste, concrete.cement),
        ResultDetail(
          'Main bars, $perColumn × $barMm mm, '
          '${formatLength(roundUp(mainLength))} each',
          formatCount(mainBars, 'bar'),
        ),
        ResultDetail(
          'Ties, $tiesEach per column, ${formatLength(roundUp(tieLength))} '
          'each',
          formatCount(tieBars, 'bar'),
        ),
        ..._formDetails(formArea, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        buy(rebarKey(barMm), mainBars.toDouble()),
        buy(rebarKey(tieMm), tieBars.toDouble()),
        tieWire,
        ..._forms(
          formArea,
          plywood: plywood,
          uses: uses,
          lumberPerSheet: columnFrameLumber[plywood]!,
        ),
      ],
      note:
          'Columns with 6 or more bars also need cross ties, not counted '
          'here. Bars and ties must follow the structural plans.',
    );
  },
  definitions: const [
    InfoSection(
      'Column size and height',
      'Width and depth of the column section, and its height from the top '
          'of the footing to the underside of the beam. Enter columns of '
          'the same size together.',
    ),
    InfoSection(
      'Main bars and ties',
      'Vertical bars carry the load; 10 mm ties wrapped around them at '
          'regular spacing hold them in place and confine the concrete. '
          'Each tie ends in two 135° hooks.',
    ),
    InfoSection(
      'Lap splice',
      'Each main bar continues into the next floor or footing dowel by one '
          'lap length: 40 bar diameters for Grade 33–40 bars, about 60 for '
          'Grade 60.',
    ),
    InfoSection(
      'Forms used',
      'Column forms are usually made once and reused for two or three sets '
          'of columns.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Volume of all columns with the waste allowance, times the mix '
          'factors per m³.',
      formula: 'volume = count × width × depth × height × (1 + waste)',
    ),
    InfoSection(
      'Main bars',
      'Each bar is the column height plus one lap splice. Short bars are '
          'cut from 6 m bars; longer ones are spliced.',
      formula: 'bar length = height + lap × bar diameter',
    ),
    InfoSection(
      'Ties',
      'Ties are spaced along the height. Each one goes round the bars '
          'inside 40 mm of cover and has two 135° hooks of max(6d, 75 mm) '
          'plus 3d for the bend.',
      formula:
          'ties = round down(height ÷ spacing) + 1\n'
          'tie length = 2 × (width − 0.08) + 2 × (depth − 0.08) + 2 × hook',
    ),
    InfoSection(
      'Tie wire',
      'Each tie is wired to every main bar: about 30 cm of wire per crossing '
          'for 12 mm main bars, 40 cm for larger ones, at 53 m per kg.',
      formula: 'tie wire = ties × main bars × length per tie ÷ 53',
    ),
    InfoSection(
      'Forms',
      'Form area is the column perimeter plus 0.20 m for laps, times the '
          'height. A plywood sheet covers 2.88 m². Fajardo\'s table gives '
          'the 2"×2" frame lumber per sheet: 29.67 bd ft with ¼" plywood, '
          '20.33 with ½". Nails are about 0.20 kg per m².',
      formula:
          'form area = count × (perimeter + 0.20) × height\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2 and '
        'forms tables',
    'NSCP 2015, Sections 425.3 (hooks) and 420.6.1.3.1 (cover)',
  ],
);

final beam = MaterialSpec(
  id: 'beam',
  name: 'Beams',
  category: MaterialCategory.structural,
  icon: Icons.table_rows_outlined,
  blurb: 'Reinforced concrete beams with stirrups and forms',
  keywords: const ['beam', 'biga', 'girder', 'tie beam', 'concrete', 'rebar'],
  numbers: const [
    NumberField(
      id: 'count',
      label: 'Number of beams',
      unit: 'pcs',
      integer: true,
      max: 10000,
    ),
    NumberField(id: 'width', label: 'Beam width', unit: 'm', max: 5),
    NumberField(id: 'depth', label: 'Beam depth', unit: 'm', max: 5),
    NumberField(
      id: 'length',
      label: 'Beam length',
      unit: 'm',
      hint: 'Clear span between columns',
      max: 100,
    ),
    _cementPrice,
  ],
  choices: [
    _classChoice,
    const ChoiceField(
      id: 'bars',
      label: 'Main bars per beam',
      initial: '4',
      options: [
        ChoiceOption('4', '4 bars', 4),
        ChoiceOption('5', '5 bars', 5),
        ChoiceOption('6', '6 bars', 6),
        ChoiceOption('8', '8 bars', 8),
      ],
    ),
    _barSize('bar', 'Main bar size', const [12, 16, 20, 25], '16'),
    _spacing(
      'tieSpacing',
      '10 mm stirrup spacing',
      const [0.10, 0.15, 0.20],
      '0.15',
      helper: 'Closer near the supports in earthquake zones',
    ),
    _lapChoice,
    _formPlywood,
    _reuse('2'),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final count = input['count'].round();
    final width = input['width'];
    final depth = input['depth'];
    final length = input['length'];
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final volume = count * width * depth * length;
    final concrete = _mix(volume, mix, waste);

    final barMm = int.parse(input.choice('bar').id);
    final perBeam = input.choice('bars').value.round();
    final lap = input.choice('lap').value * barMm / 1000;
    // Bars run into the columns with a 90° hook of 12 d at each end.
    final mainLength = length + 2 * 12 * barMm / 1000;
    final mainBars = stockBars(count * perBeam, mainLength, lap);

    const tieMm = 10;
    final spacing = input.choice('tieSpacing').value;
    if (width - 2 * coverFormed <= 0 || depth - 2 * coverFormed <= 0) {
      throw ArgumentError('Beams must be wider than their 40 mm cover');
    }
    final stirrupsEach = (length / spacing + 1e-9).floor() + 1;
    final stirrupLength =
        2 * (width - 2 * coverFormed) +
        2 * (depth - 2 * coverFormed) +
        2 * hookLength(tieMm);
    final stirrupBars = stockBars(count * stirrupsEach, stirrupLength, 0);
    final crossings = count * stirrupsEach * perBeam;
    final tieWire = buy(
      'tie_wire',
      crossings * tieWirePerTie(barMm) / tieWireMetresPerKg,
    );

    final formArea = count * (2 * depth + width + 0.10) * length;
    final uses = input.choice('reuse').value;
    final plywood = input.choice('plywood').id;

    return CalcResult(
      label:
          '${formatCount(count, 'beam')} '
          '${formatNumber(width)} × ${formatNumber(depth)} m × '
          '${formatNumber(length)} m, ${mix.label}',
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ..._mixDetails(volume, mix, waste, concrete.cement),
        ResultDetail(
          'Main bars, $perBeam × $barMm mm, '
          '${formatLength(roundUp(mainLength))} each',
          formatCount(mainBars, 'bar'),
        ),
        ResultDetail(
          'Stirrups, $stirrupsEach per beam, '
          '${formatLength(roundUp(stirrupLength))} each',
          formatCount(stirrupBars, 'bar'),
        ),
        ..._formDetails(formArea, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        buy(rebarKey(barMm), mainBars.toDouble()),
        buy(rebarKey(tieMm), stirrupBars.toDouble()),
        tieWire,
        ..._forms(
          formArea,
          plywood: plywood,
          uses: uses,
          lumberPerSheet: beamFrameLumber[plywood]!,
        ),
      ],
      note:
          'Extra bars over the supports and shoring posts are not counted. '
          'Bars and stirrups must follow the structural plans.',
    );
  },
  definitions: const [
    InfoSection(
      'Beam size and length',
      'Width and total depth of the beam section, and its clear span '
          'between columns. Enter beams of the same size together.',
    ),
    InfoSection(
      'Main bars and stirrups',
      'Top and bottom bars run the length of the beam and hook into the '
          'columns. 10 mm stirrups wrap around them at regular spacing.',
    ),
    InfoSection(
      'Forms used',
      'Beam forms cover both sides and the bottom. They are usually reused '
          'once or twice.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Volume of all beams with the waste allowance, times the mix factors '
          'per m³.',
      formula: 'volume = count × width × depth × length × (1 + waste)',
    ),
    InfoSection(
      'Main bars',
      'Each bar is the span plus a 90° hook of 12 bar diameters into the '
          'column at each end. Bars over 6 m are spliced with laps.',
      formula: 'bar length = length + 2 × 12 × bar diameter',
    ),
    InfoSection(
      'Stirrups',
      'Stirrups are spaced along the span, inside 40 mm of cover, each with '
          'two 135° hooks.',
      formula:
          'stirrups = round down(length ÷ spacing) + 1\n'
          'stirrup length = 2 × (width − 0.08) + 2 × (depth − 0.08) + '
          '2 × hook',
    ),
    InfoSection(
      'Tie wire',
      'Each stirrup is wired to every main bar: about 30 cm of wire per '
          'crossing for 12 mm main bars, 40 cm for larger ones, at 53 m per '
          'kg.',
      formula: 'tie wire = stirrups × main bars × length per tie ÷ 53',
    ),
    InfoSection(
      'Forms',
      'Form area covers two sides and the bottom plus 0.10 m for laps. '
          'Fajardo\'s table gives 25.06 bd ft of 2"×2" frame lumber per '
          'sheet with ¼" plywood, 18.66 with ½".',
      formula:
          'form area = count × (2 × depth + width + 0.10) × length\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, forms tables',
    'NSCP 2015, Sections 425.3 (hooks) and 420.6.1.3.1 (cover)',
  ],
);

extension on ChoiceField {
  ChoiceField copyWithVisibility(VisibleWhen visibleWhen) => ChoiceField(
    id: id,
    label: label,
    options: options,
    initial: initial,
    helper: helper,
    leading: leading,
    visibleWhen: visibleWhen,
  );
}
