import 'package:flutter/foundation.dart';

import 'material_spec.dart';

/// Who and what a work item needs for one day: workers by trade level and
/// rented equipment, each priced from the project's daily rates.
@immutable
class Crew {
  const Crew({
    this.foreman = 0,
    this.skilled = 0,
    this.helpers = 0,
    this.equipment = const {},
  });

  /// Workers, as fractions where a foreman or helper is shared with other
  /// crews.
  final double foreman;
  final double skilled;
  final double helpers;

  /// Equipment rented per crew-day, by [DailyRates] key, e.g. a mixer.
  final Map<String, double> equipment;

  /// Labour of one crew-day at [rates].
  double labourPerDay(Map<String, double> rates) =>
      foreman * (rates[DailyRates.foreman] ?? 0) +
      skilled * (rates[DailyRates.skilled] ?? 0) +
      helpers * (rates[DailyRates.helper] ?? 0);

  /// Equipment rental for one crew-day at [rates].
  double equipmentPerDay(Map<String, double> rates) => equipment.entries.fold(
    0,
    (sum, e) => sum + e.value * (rates[e.key] ?? 0),
  );
}

/// Keys and default amounts of the daily rates a project pays. Labour is
/// a Metro Manila rate for late 2026: above the ₱755 minimum wage with the
/// employer's share of 13th-month pay and SSS, PhilHealth and Pag-IBIG
/// contributions. Equipment is a day's rental.
abstract final class DailyRates {
  static const foreman = 'foreman';
  static const skilled = 'skilled';
  static const helper = 'helper';
  static const mixer = 'mixer';
  static const vibrator = 'vibrator';
  static const compactor = 'compactor';
  static const scaffold = 'scaffold';

  static const defaults = <String, double>{
    foreman: 1400,
    skilled: 1100,
    helper: 900,
    mixer: 1800,
    vibrator: 1000,
    compactor: 2000,
    scaffold: 600,
  };

  static const labels = <String, String>{
    foreman: 'Foreman',
    skilled: 'Skilled worker',
    helper: 'Helper',
    mixer: 'One-bagger mixer',
    vibrator: 'Concrete vibrator',
    compactor: 'Plate compactor',
    scaffold: 'Scaffolding set',
  };

  /// Whether [key] is a worker rather than equipment.
  static bool isLabour(String key) =>
      key == foreman || key == skilled || key == helper;
}

/// A kind of work measured and paid for in a bill of quantities, such as
/// "Concrete for footings" in m³, with the crew it takes and how much that
/// crew does in a day.
@immutable
class WorkItem {
  const WorkItem(
    this.key,
    this.description,
    this.unit, {
    required this.trade,
    required this.crew,
    required this.output,
    this.reference,
  });

  final String key;

  /// The bill of quantities description.
  final String description;

  /// Unit of measurement: m³, m², kg, m, pc, set.
  final String unit;
  final MaterialCategory trade;
  final Crew crew;

  /// What one crew does in an eight-hour day, in [unit].
  final double output;

  /// The DPWH pay item it corresponds to, e.g. "900", when there is one.
  final String? reference;

  /// Crew-days for [quantity], at [productivity] (1 = the usual pace).
  double crewDays(
    double quantity, {
    double effort = 1,
    double productivity = 1,
  }) => output <= 0 || productivity <= 0
      ? 0
      : quantity * effort / (output * productivity);
}

/// Keys of the work items, for calculators to report what they measure.
abstract final class Work {
  // Earthworks and concrete
  static const excavation = 'excavation';
  static const backfill = 'backfill';
  static const gravelBedding = 'gravel_bedding';
  static const concreteFooting = 'concrete_footing';
  static const concreteSlabOnFill = 'concrete_slab_on_fill';
  static const concreteSlabSuspended = 'concrete_slab_suspended';
  static const concreteColumn = 'concrete_column';
  static const concreteBeam = 'concrete_beam';
  static const rebar = 'rebar';
  static const formwork = 'formwork';

  // Masonry and carpentry
  static const chb4 = 'chb_4';
  static const chb6 = 'chb_6';
  static const chb8 = 'chb_8';
  static const plaster = 'plaster';
  static const plywood = 'plywood';
  static const ceiling = 'ceiling';
  static const insulation = 'insulation';

  // Finishes and openings
  static const painting = 'painting';
  static const tiling = 'tiling';
  static const tileSkirting = 'tile_skirting';
  static const roofing = 'roofing';
  static const purlins = 'purlins';
  static const gutter = 'gutter';
  static const doors = 'doors';
  static const windows = 'windows';
  static const carpet = 'carpet';
  static const wallpaper = 'wallpaper';

  // Electrical
  static const roughIn = 'rough_in';
  static const panel = 'panel';
  static const wiring = 'wiring';
  static const lightFixture = 'light_fixture';
  static const wiringDevice = 'wiring_device';
  static const boxes = 'boxes';

  // Plumbing
  static const piping = 'piping';
  static const toilet = 'toilet';
  static const sink = 'sink';
  static const faucet = 'faucet';
  static const shower = 'shower';
  static const tank = 'tank';
  static const septicChb = 'septic_chb';
}

const _mason = Crew(skilled: 1, helpers: 1);
const _concrete = Crew(
  foreman: 0.5,
  skilled: 1,
  helpers: 4,
  equipment: {DailyRates.mixer: 1, DailyRates.vibrator: 1},
);
const _electrician = Crew(skilled: 1, helpers: 0.5);
const _plumber = Crew(skilled: 1, helpers: 0.5);

/// Productivity norms for small buildings in the Philippines: a crew's
/// usual output in an eight-hour day, in line with the outputs used in
/// Fajardo's *Simplified Construction Estimate* and DPWH detailed unit
/// price analyses. Real outputs vary with the site, the weather and the
/// crew; the project's productivity setting scales them all.
const workItems = <WorkItem>[
  WorkItem(
    Work.excavation,
    'Structure excavation, common soil, by hand',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, helpers: 1),
    output: 3,
    reference: '103',
  ),
  WorkItem(
    Work.backfill,
    'Backfill and compaction, by hand',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, helpers: 1),
    output: 5,
    reference: '104',
  ),
  WorkItem(
    Work.gravelBedding,
    'Gravel bedding, compacted',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, helpers: 2),
    output: 5,
    reference: '200',
  ),
  WorkItem(
    Work.concreteFooting,
    'Structural concrete, footings',
    'm³',
    trade: MaterialCategory.structural,
    crew: _concrete,
    output: 4,
    reference: '900',
  ),
  WorkItem(
    Work.concreteSlabOnFill,
    'Structural concrete, slab on fill',
    'm³',
    trade: MaterialCategory.structural,
    crew: _concrete,
    output: 6,
    reference: '900',
  ),
  WorkItem(
    Work.concreteSlabSuspended,
    'Structural concrete, suspended slab',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(
      foreman: 0.5,
      skilled: 1,
      helpers: 6,
      equipment: {DailyRates.mixer: 1, DailyRates.vibrator: 1},
    ),
    output: 5,
    reference: '900',
  ),
  WorkItem(
    Work.concreteColumn,
    'Structural concrete, columns',
    'm³',
    trade: MaterialCategory.structural,
    crew: _concrete,
    output: 2.5,
    reference: '900',
  ),
  WorkItem(
    Work.concreteBeam,
    'Structural concrete, beams',
    'm³',
    trade: MaterialCategory.structural,
    crew: _concrete,
    output: 3,
    reference: '900',
  ),
  WorkItem(
    Work.rebar,
    'Reinforcing steel, cut, bent and tied in place',
    'kg',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, skilled: 1, helpers: 1),
    output: 175,
    reference: '902',
  ),
  WorkItem(
    Work.formwork,
    'Formwork and falsework, made, set and stripped',
    'm²',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, skilled: 1, helpers: 1),
    output: 9,
    reference: '903',
  ),
  WorkItem(
    Work.chb4,
    'CHB wall, 4"',
    'm²',
    trade: MaterialCategory.structural,
    crew: _mason,
    output: 11,
    reference: '1046',
  ),
  WorkItem(
    Work.chb6,
    'CHB wall, 6"',
    'm²',
    trade: MaterialCategory.structural,
    crew: _mason,
    output: 9,
    reference: '1046',
  ),
  WorkItem(
    Work.chb8,
    'CHB wall, 8"',
    'm²',
    trade: MaterialCategory.structural,
    crew: _mason,
    output: 7,
    reference: '1046',
  ),
  WorkItem(
    Work.plaster,
    'Cement plaster finish, 16 mm',
    'm²',
    trade: MaterialCategory.structural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.scaffold: 0.5}),
    output: 14,
    reference: '1027',
  ),
  WorkItem(
    Work.plywood,
    'Plywood sheathing, installed',
    'm²',
    trade: MaterialCategory.structural,
    crew: _mason,
    output: 15,
  ),
  WorkItem(
    Work.ceiling,
    'Ceiling, boards on framing',
    'm²',
    trade: MaterialCategory.structural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.scaffold: 1}),
    output: 10,
    reference: '1013',
  ),
  WorkItem(
    Work.insulation,
    'Roof insulation, foil-faced foam',
    'm²',
    trade: MaterialCategory.structural,
    crew: _mason,
    output: 60,
  ),
  WorkItem(
    Work.painting,
    'Painting, per coat',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 0.5, equipment: {DailyRates.scaffold: 0.5}),
    output: 40,
    reference: '1032',
  ),
  WorkItem(
    Work.tiling,
    'Tiles, set and grouted',
    'm²',
    trade: MaterialCategory.architectural,
    crew: _mason,
    output: 7,
    reference: '1018',
  ),
  WorkItem(
    Work.tileSkirting,
    'Tile skirting',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 25,
  ),
  WorkItem(
    Work.roofing,
    'Roofing sheets, installed',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 2, helpers: 1),
    output: 35,
    reference: '1014',
  ),
  WorkItem(
    Work.purlins,
    'Steel purlins, installed',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 60,
  ),
  WorkItem(
    Work.gutter,
    'Gutters and downspouts',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 20,
  ),
  WorkItem(
    Work.doors,
    'Doors with jambs and hardware, installed',
    'set',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 1.5,
    reference: '1006',
  ),
  WorkItem(
    Work.windows,
    'Aluminium windows, installed',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 6,
    reference: '1010',
  ),
  WorkItem(
    Work.carpet,
    'Carpet, laid',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 30,
  ),
  WorkItem(
    Work.wallpaper,
    'Wallpaper, hung',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 20,
  ),
  WorkItem(
    Work.roughIn,
    'Electrical rough-in: conduit, boxes and wiring, per outlet',
    'pt',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1, helpers: 1),
    output: 6,
    reference: '1100',
  ),
  WorkItem(
    Work.panel,
    'Panel board with breakers, installed',
    'set',
    trade: MaterialCategory.electrical,
    crew: _electrician,
    output: 1,
    reference: '1102',
  ),
  WorkItem(
    Work.wiring,
    'Building wire, pulled in conduit',
    'm',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1, helpers: 1),
    output: 300,
  ),
  WorkItem(
    Work.lightFixture,
    'Lighting fixtures, installed',
    'pc',
    trade: MaterialCategory.electrical,
    crew: _electrician,
    output: 12,
  ),
  WorkItem(
    Work.wiringDevice,
    'Switches and outlets, installed',
    'pc',
    trade: MaterialCategory.electrical,
    crew: _electrician,
    output: 15,
  ),
  WorkItem(
    Work.boxes,
    'Junction and utility boxes, installed',
    'pc',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1),
    output: 20,
  ),
  WorkItem(
    Work.piping,
    'Water and drainage pipes with fittings, installed',
    'm',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1, helpers: 1),
    output: 20,
    reference: '1200',
  ),
  WorkItem(
    Work.toilet,
    'Water closets, installed',
    'set',
    trade: MaterialCategory.plumbing,
    crew: _plumber,
    output: 1.5,
  ),
  WorkItem(
    Work.sink,
    'Lavatories and sinks, installed',
    'set',
    trade: MaterialCategory.plumbing,
    crew: _plumber,
    output: 3,
  ),
  WorkItem(
    Work.faucet,
    'Faucets, installed',
    'pc',
    trade: MaterialCategory.plumbing,
    crew: _plumber,
    output: 10,
  ),
  WorkItem(
    Work.shower,
    'Shower sets, installed',
    'set',
    trade: MaterialCategory.plumbing,
    crew: _plumber,
    output: 3,
  ),
  WorkItem(
    Work.tank,
    'Water or septic tanks, set in place',
    'set',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1, helpers: 2),
    output: 1,
  ),
  WorkItem(
    Work.septicChb,
    'Septic tank, CHB with concrete slabs, built on site',
    'm³',
    trade: MaterialCategory.plumbing,
    crew: Crew(foreman: 0.2, skilled: 1, helpers: 2),
    output: 0.5,
    reference: '1203',
  ),
];

final _byKey = {for (final w in workItems) w.key: w};

WorkItem? workItemByKey(String key) => _byKey[key];
