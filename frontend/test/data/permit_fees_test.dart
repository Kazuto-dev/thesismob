import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/permit_fees.dart';
import 'package:thesismob/data/project.dart';

void main() {
  test('a house pays one rate on its whole area by bracket', () {
    expect(buildingFee(PermitUse.house, 0), 0);
    expect(buildingFee(PermitUse.house, 20), 40);
    expect(buildingFee(PermitUse.house, 75), 360); // DPWH's sample
    expect(buildingFee(PermitUse.house, 100), 480);
    expect(buildingFee(PermitUse.house, 140), 840);
    expect(buildingFee(PermitUse.house, 200), 1440);
  });

  test('other groups pay each band of area at its own rate', () {
    expect(buildingFee(PermitUse.commercial, 500), 11500);
    expect(buildingFee(PermitUse.commercial, 600), 11500 + 2200);
    // 500 × 23 + 100 × (22 + 20.5 + 19.5 + 18 + 17) + 200 × 16
    expect(buildingFee(PermitUse.commercial, 1200), 24400);
    expect(
      buildingFee(PermitUse.commercial, 3500),
      closeTo(11500 + 9700 + 500 * 16 + 500 * 15 + 1000 * 14 + 500 * 12, 0.001),
    );
  });

  test('ancillary fees follow the schedule', () {
    expect(lineAndGradeFee(10), 24);
    expect(lineAndGradeFee(12.5), closeTo(31.2, 0.001));
    expect(electricalFee(5), 200);
    expect(electricalFee(6), 220); // Puerto Princesa's worked example
    expect(electricalFee(50), 1100);
    expect(electricalFee(300), 3600);
    expect(mechanicalFee(3), 120);
    expect(excavationFee(34.2), 105);
    expect(fencingFee(20, FenceKind.masonry), 60);
    expect(fencingFee(20, FenceKind.tallMasonry), 80);
    expect(fencingFee(20, FenceKind.wire), 48);
  });

  test('one plumbing unit covers a small bathroom and kitchen', () {
    const toilet = (
      waterClosets: 1,
      lavatories: 0,
      sinks: 0,
      floorDrains: 0,
      showers: 0,
      faucets: 0,
    );
    expect(plumbingFee(toilet), 24, reason: 'part of a unit');
    expect(plumbingFee(fixturesFor(1)), 24 + 3 + 2);
    // Two bathrooms: one more WC, lavatory, shower, floor drain and two
    // faucets, and the laundry sink.
    expect(plumbingFee(fixturesFor(2)), 24 + 7 + 7 + 2 + 3 + 3 + 4);
  });

  test('occupancy, zoning and fire code fees', () {
    expect(occupancyFee(PermitUse.house, 150000), 100);
    expect(occupancyFee(PermitUse.house, 850000), 400);
    expect(occupancyFee(PermitUse.house, 1200000), 800);
    expect(occupancyFee(PermitUse.house, occupancyCost(140)), 1600);
    expect(occupancyFee(PermitUse.commercial, 3000000), 3000);
    expect(zoningFee(PermitUse.house, 3700000), 4220);
    expect(zoningFee(PermitUse.commercial, 3700000), 0);
    expect(fireSafetyEvaluationFee(3700000), 3700);
    expect(fireSafetyEvaluationFee(80000000), 50000);
    expect(fireSafetyInspectionFee(1600), 500);
    expect(fireSafetyInspectionFee(10000), 1500);
  });

  test('a 140 m² two-storey house costing ₱3.7M', () {
    const p = PermitInputs(
      floorArea: 140,
      storeys: 2,
      projectCost: 3700000,
      excavation: 35,
      connectedLoad: 8,
      bathrooms: 2,
    );
    final fees = {for (final l in permitFees(p)) l.label: l.amount};
    expect(fees['Building fee'], 840);
    expect(fees['Line and grade'], 24);
    expect(fees['Excavation'], 105);
    expect(fees['Electrical permit'], 260);
    expect(fees['Plumbing permit'], 50);
    expect(fees['Zoning (locational) clearance'], 4220);
    expect(fees['Fire safety evaluation clearance (BFP)'], 3700);
    expect(fees['Certificate of occupancy'], 1600);
    expect(fees['Fire safety inspection for occupancy (BFP)'], 500);
    expect(fees.containsKey('Fencing'), isFalse);
    expect(permitTotal(p), 11299);
  });

  test('a project fills in its floor area and a typical load', () {
    final p = Project.create('House').copyWith(floorArea: 140);
    final inputs = PermitInputs.forProject(p, storeys: 2);
    expect(inputs.floorArea, 140);
    expect(inputs.connectedLoad, 8);
    expect(inputs.bathrooms, 2);
    expect(inputs.excavation, 35);
    expect(inputs.projectCost, 0, reason: 'no items yet');
  });
}
