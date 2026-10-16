import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/job_plan.dart';
import 'package:thesismob/data/project.dart';

import 'sample_house.dart';

void main() {
  group('cash flow', () {
    test('money in and out add up to the price and the cost', () {
      final p = sampleHouse();
      final flow = cashFlow(p);
      final b = p.breakdown;
      final schedule = Schedule.of(p);
      // Signing, the working months, and a month for the last payment.
      expect(flow.months.first.month, 0);
      expect(
        flow.months,
        hasLength((schedule.days / workDaysPerMonth).ceil() + 2),
      );
      expect(flow.months.first.received, closeTo(b.subtotal * 0.30, 0.01));
      expect(flow.months.first.costs, 0);
      // Before VAT: the client pays the price, the job costs its direct
      // cost with escalation and contingency.
      expect(flow.totalReceived, closeTo(b.subtotal, 1));
      expect(
        flow.totalCosts,
        closeTo(b.direct + b.escalation + b.contingency, 1),
      );
      expect(
        flow.months.fold<double>(0, (s, m) => s + m.billed),
        closeTo(b.subtotal, 1),
      );
      expect(
        flow.months.last.cumulative,
        closeTo(flow.totalReceived - flow.totalCosts, 1),
      );
    });

    test('the peak cash need is the lowest point of the running total', () {
      final flow = cashFlow(sampleHouse());
      final lowest = flow.months
          .map((m) => m.cumulative)
          .reduce((a, b) => a < b ? a : b);
      expect(flow.peakNeed, greaterThan(0));
      expect(flow.peakNeed, closeTo(-lowest, 0.01));
      expect(
        flow.months[flow.peakMonth!].cumulative,
        closeTo(-flow.peakNeed, 0.01),
      );
    });

    test('slower payment and no downpayment need more working capital', () {
      final usual = cashFlow(sampleHouse()).peakNeed;
      final slow = cashFlow(
        sampleHouse(
          contract: const ContractData(terms: QuoteTerms(paymentDays: 60)),
        ),
      );
      expect(slow.peakNeed, greaterThan(usual));
      expect(slow.months, hasLength(cashFlow(sampleHouse()).months.length + 1));
      final noDown = cashFlow(
        sampleHouse(
          contract: const ContractData(terms: QuoteTerms(downpaymentPct: 0)),
        ),
      );
      expect(noDown.peakNeed, greaterThan(usual));
      expect(noDown.months.first.received, 0);
    });

    test('the retention comes with the last payment', () {
      final p = sampleHouse();
      final flow = cashFlow(p);
      final last = flow.months.last;
      expect(last.costs, 0);
      expect(
        last.received,
        greaterThanOrEqualTo(p.breakdown.subtotal * 0.10 - 0.01),
      );
    });

    test('a company client keeps back its 2% until tax time', () {
      final flow = cashFlow(
        sampleHouse(
          contract: const ContractData(
            terms: QuoteTerms(client: ClientType.company),
          ),
        ),
      );
      final b = sampleHouse().breakdown;
      expect(flow.totalReceived, closeTo(b.subtotal * 0.98, 1));
    });

    test('months carry dates with a start date', () {
      final flow = cashFlow(
        sampleHouse(contract: ContractData(startDate: DateTime(2026, 11, 2))),
      );
      expect(flow.months[0].from, DateTime(2026, 11, 2));
      expect(flow.months[1].from, DateTime(2026, 11, 2));
      expect(flow.months[2].from!.isAfter(DateTime(2026, 11, 28)), isTrue);
      expect(cashFlow(sampleHouse()).months[1].from, isNull);
      expect(cashFlow(Project.create('Empty')).months, isEmpty);
      expect(cashFlow(Project.create('Empty')).peakNeed, 0);
    });
  });
}
