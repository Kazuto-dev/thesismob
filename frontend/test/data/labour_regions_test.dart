import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/labour_regions.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/work_items.dart';

void main() {
  test('Metro Manila gives the default rates', () {
    final ncr = LabourRegion.ncr.rates;
    for (final key in LabourRegion.tradePremium.keys) {
      expect(ncr[key], DailyRates.defaults[key], reason: key);
    }
    expect(LabourRegion.ncr.matches(DailyRates.defaults), isTrue);
  });

  test('every region has a plausible minimum wage and rates', () {
    expect(LabourRegion.values, hasLength(18));
    for (final r in LabourRegion.values) {
      expect(r.minimumWage, inInclusiveRange(400, 800), reason: r.name);
      final rates = r.rates;
      expect(rates[DailyRates.helper], greaterThanOrEqualTo(r.minimumWage));
      expect(
        rates[DailyRates.foreman],
        greaterThan(rates[DailyRates.skilled]!),
      );
      expect(rates[DailyRates.skilled], greaterThan(rates[DailyRates.helper]!));
    }
    expect(LabourRegion.centralVisayas.rates, {
      DailyRates.foreman: 1050,
      DailyRates.skilled: 850,
      DailyRates.helper: 700,
    });
    expect(LabourRegion.bicol.rates, {
      DailyRates.foreman: 850,
      DailyRates.skilled: 650,
      DailyRates.helper: 550,
    });
  });

  test('the table in docs/prices-and-costing.md', () {
    // Foreman, skilled, helper.
    const table = {
      LabourRegion.ncr: (1400, 1100, 900),
      LabourRegion.car: (900, 750, 600),
      LabourRegion.ilocos: (900, 750, 600),
      LabourRegion.cagayanValley: (900, 750, 600),
      LabourRegion.centralLuzon: (1100, 900, 750),
      LabourRegion.calabarzon: (1100, 900, 750),
      LabourRegion.mimaropa: (850, 650, 550),
      LabourRegion.bicol: (850, 650, 550),
      LabourRegion.westernVisayas: (1000, 800, 650),
      LabourRegion.negros: (1000, 800, 650),
      LabourRegion.centralVisayas: (1050, 850, 700),
      LabourRegion.easternVisayas: (850, 700, 550),
      LabourRegion.zamboanga: (850, 700, 550),
      LabourRegion.northernMindanao: (900, 750, 600),
      LabourRegion.davao: (1000, 800, 650),
      LabourRegion.soccsksargen: (850, 650, 550),
      LabourRegion.caraga: (850, 700, 600),
      LabourRegion.barmm: (800, 650, 550),
    };
    for (final MapEntry(key: region, value: (f, s, h)) in table.entries) {
      expect(region.rates, {
        DailyRates.foreman: f,
        DailyRates.skilled: s,
        DailyRates.helper: h,
      }, reason: region.name);
    }
  });

  test('a region fills the labour rates and keeps equipment', () {
    final own = {DailyRates.mixer: 1500.0, DailyRates.skilled: 1200.0};
    final davao = LabourRegion.davao.applyTo(own);
    expect(davao[DailyRates.mixer], 1500);
    expect(davao[DailyRates.skilled], 800);
    expect(davao[DailyRates.helper], 650);
    expect(davao[DailyRates.foreman], 1000);
    // Back to Metro Manila: the labour rates are the defaults again.
    expect(LabourRegion.ncr.applyTo(davao), {DailyRates.mixer: 1500.0});
    expect(
      LabourRegion.davao.matches({...DailyRates.defaults, ...davao}),
      isTrue,
    );
  });

  test('only Metro Manila maps from the price book', () {
    expect(
      LabourRegion.forPriceRegion(PriceRegion.metroManila),
      LabourRegion.ncr,
    );
    expect(LabourRegion.forPriceRegion(PriceRegion.visayas), isNull);
  });
}
