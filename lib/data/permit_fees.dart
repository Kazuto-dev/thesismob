import 'package:flutter/foundation.dart';

import '../materials/work_items.dart';
import 'project.dart';
import 'unit_prices.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// Whole units for a fee charged "per unit or fraction thereof".
double _whole(double value) => value <= 0 ? 0 : (value - 1e-9).ceilToDouble();

/// What a building is used for, as the National Building Code (PD 1096)
/// fee schedule groups it.
enum PermitUse {
  /// Division A-1: a house for one family.
  house('House for one family (Division A-1)'),

  /// Divisions B-1, E, F-1, G, H and I-1: apartments and hotels, shops and
  /// offices, factories, storage and assembly buildings.
  commercial('Apartment, shop, office, factory or warehouse (Groups B, E–I)');

  const PermitUse(this.label);

  final String label;
}

/// A fence's material and height, which set its fee per metre.
enum FenceKind {
  masonry('Masonry, concrete or metal, up to 1.80 m high', 3),
  tallMasonry('Masonry, concrete or metal, over 1.80 m high', 4),
  wire('Wire or light materials', 2.40);

  const FenceKind(this.label, this.ratePerMetre);

  final String label;

  /// Pesos per metre of fence or fraction of a metre.
  final double ratePerMetre;
}

/// The fixtures a plumbing permit counts.
typedef PlumbingFixtures = ({
  int waterClosets,
  int lavatories,
  int sinks,
  int floorDrains,
  int showers,
  int faucets,
});

/// A typical house's fixtures: a toilet, lavatory, shower and floor drain
/// per bathroom, a kitchen sink and a laundry sink, a floor drain in the
/// laundry and a faucet for each sink plus one outside.
PlumbingFixtures fixturesFor(int bathrooms) {
  final b = bathrooms < 0 ? 0 : bathrooms;
  return (
    waterClosets: b,
    lavatories: b,
    sinks: 2,
    floorDrains: b + 1,
    showers: b,
    faucets: b + 3,
  );
}

/// What the permit fees are worked out from.
@immutable
class PermitInputs {
  const PermitInputs({
    this.use = PermitUse.house,
    this.floorArea = 0,
    this.storeys = 1,
    this.projectCost = 0,
    this.frontage = 10,
    this.excavation = 0,
    this.fenceLength = 0,
    this.fence = FenceKind.masonry,
    this.connectedLoad = 0,
    this.airconUnits = 0,
    this.bathrooms = 1,
    this.otherLguFees = 0,
  });

  /// Sensible inputs for [project]: its floor area, cost and measured
  /// excavation, and a typical electrical load and bathrooms for the area.
  factory PermitInputs.forProject(Project project, {int storeys = 1}) {
    final area = project.floorArea ?? 0;
    final floors = storeys < 1 ? 1 : storeys;
    final measured = excavationOf(project);
    return PermitInputs(
      floorArea: area,
      storeys: floors,
      projectCost: costBeforeFees(project),
      excavation: measured > 0
          ? (measured * 10).ceilToDouble() / 10
          : (area / floors * 0.5).ceilToDouble(),
      connectedLoad: typicalConnectedLoad(area),
      bathrooms: typicalBathrooms(area, floors),
    );
  }

  final PermitUse use;

  /// Total floor area of every storey, in m².
  final double floorArea;
  final int storeys;

  /// The building's cost, for the fire code and zoning fees.
  final double projectCost;

  /// Length of the lot along the street, in metres, for line and grade.
  final double frontage;

  /// Excavation for the foundations, in m³.
  final double excavation;
  final double fenceLength;
  final FenceKind fence;

  /// Total connected electrical load, in kVA.
  final double connectedLoad;

  /// Window or split air-conditioners to be installed.
  final int airconUnits;
  final int bathrooms;

  /// Other local fees the user adds, such as filing, processing and the
  /// barangay clearance.
  final double otherLguFees;

  PlumbingFixtures get fixtures => fixturesFor(bathrooms);

  PermitInputs copyWith({
    PermitUse? use,
    double? floorArea,
    int? storeys,
    double? projectCost,
    double? frontage,
    double? excavation,
    double? fenceLength,
    FenceKind? fence,
    double? connectedLoad,
    int? airconUnits,
    int? bathrooms,
    double? otherLguFees,
  }) => PermitInputs(
    use: use ?? this.use,
    floorArea: floorArea ?? this.floorArea,
    storeys: storeys ?? this.storeys,
    projectCost: projectCost ?? this.projectCost,
    frontage: frontage ?? this.frontage,
    excavation: excavation ?? this.excavation,
    fenceLength: fenceLength ?? this.fenceLength,
    fence: fence ?? this.fence,
    connectedLoad: connectedLoad ?? this.connectedLoad,
    airconUnits: airconUnits ?? this.airconUnits,
    bathrooms: bathrooms ?? this.bathrooms,
    otherLguFees: otherLguFees ?? this.otherLguFees,
  );
}

/// The project's total without what it holds for permits and professional
/// fees, so working those out does not count them in their own base.
double costBeforeFees(Project project) {
  if (project.items.isEmpty) return 0;
  final general = {...project.costs.general}
    ..remove('permits')
    ..remove('professional');
  return CostBreakdown.of(
    project.items,
    project.costs.copyWith(general: general),
    months: project.months,
  ).total;
}

/// Excavation the project's estimates measured, in m³.
double excavationOf(Project project) => project.items.fold(
  0,
  (sum, e) =>
      sum +
      worksOf(e)
          .where((w) => w.key == Work.excavation)
          .fold<double>(0, (s, w) => s + w.quantity),
);

/// A first guess of a house's connected load, in whole kVA: general
/// lighting at 24 VA a m² plus two small-appliance circuits and a laundry
/// circuit at 1,500 VA each (Philippine Electrical Code dwelling loads),
/// before air-conditioners.
double typicalConnectedLoad(double floorArea) =>
    floorArea <= 0 ? 0 : (floorArea * 0.024 + 4.5).ceilToDouble();

/// A first guess of bathrooms: one a storey, and one for every 70 m².
int typicalBathrooms(double floorArea, int storeys) {
  final byArea = (floorArea / 70).ceil();
  return byArea > storeys ? byArea : storeys;
}

/// The building fee for [area] m² of floor (Revised IRR of PD 1096, as
/// reissued in NBCDO Memorandum Circular 03 s.2016). A house pays one rate
/// on its whole area by the size bracket; other groups pay each band of
/// area at its own rate.
double buildingFee(PermitUse use, double area) {
  if (area <= 0) return 0;
  switch (use) {
    case PermitUse.house:
      final rate = switch (area) {
        <= 20 => 2.00,
        <= 50 => 3.40,
        <= 100 => 4.80,
        <= 150 => 6.00,
        _ => 7.20,
      };
      return _centavos(area * rate);
    case PermitUse.commercial:
      const bands = [
        (500.0, 23.00),
        (600.0, 22.00),
        (700.0, 20.50),
        (800.0, 19.50),
        (900.0, 18.00),
        (1000.0, 17.00),
        (1500.0, 16.00),
        (2000.0, 15.00),
        (3000.0, 14.00),
        (double.infinity, 12.00),
      ];
      var fee = 0.0;
      var from = 0.0;
      for (final (upTo, rate) in bands) {
        if (area <= from) break;
        fee += ((area < upTo ? area : upTo) - from) * rate;
        from = upTo;
      }
      return _centavos(fee);
  }
}

/// Line and grade: ₱24 for the first 10 m of street frontage and ₱2.40
/// for each metre or fraction after.
double lineAndGradeFee(double frontage) =>
    frontage <= 0 ? 0 : _centavos(24 + 2.40 * _whole(frontage - 10));

/// The electrical permit fee on the total connected load, by whole kVA.
double electricalFee(double kva) {
  final load = _whole(kva);
  final fee = switch (load) {
    <= 0 => 0.0,
    <= 5 => 200.0,
    <= 50 => 200 + 20 * (load - 5),
    <= 300 => 1100 + 10 * (load - 50),
    <= 1500 => 3600 + 5 * (load - 300),
    <= 6000 => 9600 + 2.5 * (load - 1500),
    _ => 20850 + 1.25 * (load - 6000),
  };
  return _centavos(fee);
}

/// The mechanical permit fee for air-conditioners, ₱40 a unit.
double mechanicalFee(int airconUnits) =>
    airconUnits <= 0 ? 0 : airconUnits * 40.0;

/// The plumbing permit fee: ₱24 for the first "unit" (a water closet, two
/// floor drains, a lavatory, a sink, three faucets and a shower head; part
/// of a unit counts as a whole one) and so much for each fixture beyond it.
double plumbingFee(PlumbingFixtures f) {
  final count =
      f.waterClosets +
      f.lavatories +
      f.sinks +
      f.floorDrains +
      f.showers +
      f.faucets;
  if (count <= 0) return 0;
  int extra(int have, int inUnit) => have > inUnit ? have - inUnit : 0;
  return 24.0 +
      7 * extra(f.waterClosets, 1) +
      3 * extra(f.floorDrains, 2) +
      7 * extra(f.lavatories, 1) +
      3 * extra(f.sinks, 1) +
      2 * extra(f.faucets, 3) +
      2 * extra(f.showers, 1);
}

/// The excavation fee: ₱3 a cubic metre or fraction.
double excavationFee(double cubicMetres) => 3 * _whole(cubicMetres);

/// The fencing fee for [length] metres of fence or fraction.
double fencingFee(double length, FenceKind kind) =>
    _centavos(kind.ratePerMetre * _whole(length));

/// The cost the building official uses for the certificate of occupancy:
/// the floor area at ₱10,000 a m² (Table II.G.1 of NBCDO MC 03 s.2016).
double occupancyCost(double floorArea) =>
    floorArea <= 0 ? 0 : floorArea * 10000;

/// The certificate of occupancy fee, by the cost of the building.
double occupancyFee(PermitUse use, double cost) {
  if (cost <= 0) return 0;
  final (a, b, c, d) = switch (use) {
    PermitUse.house => (100.0, 200.0, 400.0, 800.0),
    PermitUse.commercial => (200.0, 400.0, 800.0, 1000.0),
  };
  if (cost <= 150000) return a;
  if (cost <= 400000) return b;
  if (cost <= 850000) return c;
  if (cost <= 1200000) return d;
  return d + d * ((cost - 1200000) / 1000000).ceilToDouble();
}

/// The zoning (locational) clearance for a house, on the schedule many
/// LGUs adopted from HLURB Resolution 912 s.2013. Other uses have their
/// own brackets, so this is 0 for them.
double zoningFee(PermitUse use, double cost) {
  if (use != PermitUse.house || cost <= 0) return 0;
  if (cost <= 100000) return 288;
  if (cost <= 200000) return 576;
  return _centavos(720 + (cost - 200000) * 0.001);
}

/// The Bureau of Fire Protection's fee for the fire safety evaluation
/// clearance needed before the building permit: 0.10% of the building's
/// estimated value, at most ₱50,000 (RA 9514, Fire Code).
double fireSafetyEvaluationFee(double cost) {
  if (cost <= 0) return 0;
  final fee = cost * 0.001;
  return _centavos(fee > 50000 ? 50000 : fee);
}

/// The BFP's fire safety inspection fee before occupancy: 15% of the
/// local fees for the occupancy permit, at least ₱500 (2019 Revised IRR of
/// RA 9514).
double fireSafetyInspectionFee(double occupancy) {
  if (occupancy <= 0) return 0;
  final fee = occupancy * 0.15;
  return _centavos(fee < 500 ? 500 : fee);
}

/// One fee in the breakdown: what it is, how it was worked out, and the
/// amount.
typedef FeeLine = ({String label, String basis, double amount});

/// Every permit fee for [p], in the order they are paid.
List<FeeLine> permitFees(PermitInputs p) {
  String n(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(v * 10 == (v * 10).roundToDouble() ? 1 : 2);
  final occupancy = occupancyFee(p.use, occupancyCost(p.floorArea));
  final f = p.fixtures;
  return [
    (
      label: 'Building fee',
      basis: '${n(p.floorArea)} m² of floor',
      amount: buildingFee(p.use, p.floorArea),
    ),
    (
      label: 'Line and grade',
      basis: '${n(p.frontage)} m of street frontage',
      amount: lineAndGradeFee(p.frontage),
    ),
    (
      label: 'Excavation',
      basis: '${n(p.excavation)} m³',
      amount: excavationFee(p.excavation),
    ),
    if (p.fenceLength > 0)
      (
        label: 'Fencing',
        basis: '${n(p.fenceLength)} m',
        amount: fencingFee(p.fenceLength, p.fence),
      ),
    (
      label: 'Electrical permit',
      basis: '${n(p.connectedLoad)} kVA connected load',
      amount: electricalFee(p.connectedLoad),
    ),
    if (p.airconUnits > 0)
      (
        label: 'Mechanical permit',
        basis: '${p.airconUnits} air-conditioners',
        amount: mechanicalFee(p.airconUnits),
      ),
    (
      label: 'Plumbing permit',
      basis:
          '${f.waterClosets} WC, ${f.lavatories} lavatories, ${f.sinks} '
          'sinks, ${f.showers} showers, ${f.floorDrains} floor drains, '
          '${f.faucets} faucets',
      amount: plumbingFee(f),
    ),
    if (p.use == PermitUse.house)
      (
        label: 'Zoning (locational) clearance',
        basis: 'LGU, on the project cost',
        amount: zoningFee(p.use, p.projectCost),
      ),
    (
      label: 'Fire safety evaluation clearance (BFP)',
      basis: '0.1% of the project cost, at most ₱50,000',
      amount: fireSafetyEvaluationFee(p.projectCost),
    ),
    (
      label: 'Certificate of occupancy',
      basis: 'Floor area at ₱10,000 a m²',
      amount: occupancy,
    ),
    (
      label: 'Fire safety inspection for occupancy (BFP)',
      basis: '15% of the occupancy fee, at least ₱500',
      amount: fireSafetyInspectionFee(occupancy),
    ),
    if (p.otherLguFees > 0)
      (
        label: 'Other LGU fees',
        basis: 'Your figure',
        amount: _centavos(p.otherLguFees),
      ),
  ];
}

/// The permit fees together.
double permitTotal(PermitInputs p) =>
    _centavos(permitFees(p).fold(0, (sum, l) => sum + l.amount));
