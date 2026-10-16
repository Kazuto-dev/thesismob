import 'dart:math' as math;

import 'contract_math.dart';
import 'project.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// Calendar days in an average month, for the days a client takes to pay.
const _daysPerMonth = 30.44;

/// One month of a job's cash flow, before VAT. Month 0 is the signing;
/// month 1 is the first [workDaysPerMonth] working days, and so on.
typedef CashFlowMonth = ({
  int month,

  /// The first working day of the month, when the job has a start date.
  DateTime? from,

  /// Money out: materials, labour, equipment and site costs.
  double costs,

  /// The work billed at the end of the month, before VAT.
  double billed,

  /// Money in: the downpayment, billings paid and the retention released.
  double received,

  /// Money in less money out this month.
  double net,

  /// Money in less money out since the signing; negative when the job is
  /// running on the contractor's own money.
  double cumulative,
});

/// A job's cash flow month by month, before VAT, which the contractor
/// collects for the BIR and passes on.
class CashFlow {
  const CashFlow(this.months);

  final List<CashFlowMonth> months;

  /// The most money the job needs from the contractor at once: its
  /// working capital. 0 when the downpayment and billings always cover
  /// the costs.
  double get peakNeed => months.isEmpty
      ? 0
      : math.max(0, -months.map((m) => m.cumulative).reduce(math.min));

  /// The month of [peakNeed], or null when there is none.
  int? get peakMonth {
    if (peakNeed <= 0) return null;
    return months.reduce((a, b) => b.cumulative < a.cumulative ? b : a).month;
  }

  double get totalCosts => months.fold(0, (s, m) => s + m.costs);
  double get totalReceived => months.fold(0, (s, m) => s + m.received);
}

/// [project]'s planned cash flow, before VAT:
///
/// - money out: each task's materials bought when it starts, its labour,
///   tools and equipment as the work is done, and general requirements
///   and hauling evenly over the job, with escalation and contingency in
///   proportion;
/// - money in: the downpayment on signing, then each month's work billed
///   at the end of the month from the S-curve, less the downpayment
///   recouped, the retention and the income tax the client withholds,
///   paid [QuoteTerms.paymentDays] later; the retention is paid that long
///   after the job is finished and accepted.
CashFlow cashFlow(Project project) {
  final schedule = Schedule.of(project);
  final days = schedule.days;
  if (days <= 0) return const CashFlow([]);
  final b = project.breakdown;
  final terms = project.contract.terms;
  final price = b.subtotal;
  final start = project.contract.startDate;
  final count = (days / workDaysPerMonth).ceil();
  final lag = (terms.paymentDays / _daysPerMonth).ceil();
  final scheduled =
      schedule.tasks.fold<double>(0, (s, t) => s + t.cost) + schedule.costs;
  final spend = scheduled <= 0
      ? 0.0
      : (b.direct + b.escalation + b.contingency) / scheduled;
  final incomeTax = withholding(project).incomeTax;

  double overlap(double from, double to, double a, double z) =>
      math.max(0, math.min(to, z) - math.max(from, a));

  final costs = List<double>.filled(count + lag + 1, 0);
  final billed = List<double>.filled(count + lag + 1, 0);
  final received = List<double>.filled(count + lag + 1, 0);
  received[0] = price * terms.downpaymentPct / 100;
  for (var m = 1; m <= count; m++) {
    final from = ((m - 1) * workDaysPerMonth).toDouble();
    final to = m == count ? days : (m * workDaysPerMonth).toDouble();
    var out = schedule.costs * overlap(from, to, 0, days) / days;
    for (final t in schedule.tasks) {
      if (t.start >= from && (t.start < to || m == count)) out += t.materials;
      if (t.days > 0) {
        out +=
            (t.cost - t.materials) *
            overlap(from, to, t.start, t.start + t.days) /
            t.days;
      }
    }
    costs[m] = out * spend;
    final work = price * (schedule.progressAt(to) - schedule.progressAt(from));
    billed[m] = work;
    received[m + lag] +=
        work *
        (1 - (terms.downpaymentPct + terms.retentionPct + incomeTax) / 100);
  }
  received[count + lag] += price * terms.retentionPct / 100;

  var cumulative = 0.0;
  return CashFlow([
    for (var m = 0; m <= count + lag; m++)
      () {
        final net = received[m] - costs[m];
        cumulative += net;
        return (
          month: m,
          from: start == null || m == 0
              ? start
              : Schedule.addWorkingDays(
                  start,
                  ((m - 1) * workDaysPerMonth).toDouble(),
                ),
          costs: _centavos(costs[m]),
          billed: _centavos(billed[m]),
          received: _centavos(received[m]),
          net: _centavos(net),
          cumulative: _centavos(cumulative),
        );
      }(),
  ]);
}
