import 'dart:math' as math;

import '../materials/items.dart';
import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'boq.dart';
import 'contract_math.dart';
import 'estimate.dart';
import 'project.dart';
import 'unit_prices.dart';

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
  return CashFlow(<CashFlowMonth>[
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

// Purchase schedule

/// Usual delivery lead times in calendar days, shortest and longest, by
/// group of the materials list, for small orders from Metro Manila
/// hardware stores and suppliers. Stock items arrive in 3–7 days; long-span
/// roofing is roll-formed to length and tiles are often ordered in from
/// the distributor, 7–14; plumbing fixtures up to 14; doors, jambs and
/// aluminium windows are made to the measured openings, 21–30. Ask your
/// suppliers: these vary with the place and the season.
const leadTimes = <ItemGroup, (int, int)>{
  ItemGroup.cement: (3, 7),
  ItemGroup.masonry: (3, 7),
  ItemGroup.steel: (3, 7),
  ItemGroup.lumber: (3, 7),
  ItemGroup.ceiling: (3, 7),
  ItemGroup.roofing: (7, 14),
  ItemGroup.paint: (3, 7),
  ItemGroup.tiles: (7, 14),
  ItemGroup.electrical: (3, 7),
  ItemGroup.plumbing: (3, 7),
  ItemGroup.fixtures: (7, 14),
  ItemGroup.doors: (21, 30),
  ItemGroup.other: (3, 7),
};

/// One line of the purchase schedule: a material of the shopping list,
/// when it is first needed and when to order it.
typedef PurchaseLine = ({
  MaterialLine material,

  /// The first phase that uses it.
  String phase,

  /// The working day of the schedule it is first needed on.
  double neededDay,

  /// Delivery lead time in calendar days, shortest and longest.
  int leadMin,
  int leadMax,

  /// The date it is first needed, when the job has a start date.
  DateTime? needed,

  /// The last day to order it, [leadMax] calendar days before [needed].
  DateTime? orderBy,
});

/// The work item [l] of estimate [e] goes into, as [allocateMaterials]
/// places it: the one the calculator named, gravel to the bedding, and
/// the rest (bars and forms included) to the main work.
String _workOf(String? named, String itemKey, Set<String> works, String main) {
  if (named != null && works.contains(named)) return named;
  if (itemKey == 'gravel_bedding' && works.contains(Work.gravelBedding)) {
    return Work.gravelBedding;
  }
  return main;
}

/// [project]'s purchase schedule: every material of its shopping list,
/// with the start of the earliest task that uses it and the day to order
/// it by from [leadTimes], earliest first.
List<PurchaseLine> purchaseSchedule(Project project) {
  final schedule = Schedule.of(project);
  if (schedule.tasks.isEmpty) return const [];
  final start = project.contract.startDate;

  ScheduleTask? taskAt(int phase, MaterialCategory? trade) {
    for (final t in schedule.tasks) {
      if (t.phase == phase && t.trade == trade && t.crewDays > 0) return t;
    }
    return null;
  }

  // The earliest task each material goes into, by shopping-list key.
  final first = <String, ScheduleTask>{};
  void use(String key, ScheduleTask? task) {
    if (task == null) return;
    final known = first[key];
    if (known == null || task.start < known.start) first[key] = task;
  }

  for (final section in workSections(project)) {
    final trade = section.trade;
    final byEstimate = <Estimate, List<WorkAnalysis>>{};
    for (final (number: _, :analysis) in section.entries) {
      byEstimate.putIfAbsent(analysis.estimate, () => []).add(analysis);
    }
    for (final MapEntry(key: e, value: analyses) in byEstimate.entries) {
      final own = worksOf(e);
      final main = own.isEmpty ? analyses.first.work.key : own.first.key;
      final works = {for (final w in own) w.key};
      final mainTask = taskAt(
        phaseOf(scheduleKey(analyses.first), trade),
        trade,
      );
      ScheduleTask? taskOf(String work) {
        final key = work == Work.rebar || work == Work.formwork ? main : work;
        return taskAt(phaseOf(key, trade), trade) ?? mainTask;
      }

      use(mainKeyOf(e), taskOf(main));
      for (final l in e.companions) {
        use(l.itemKey, taskOf(_workOf(l.work, l.itemKey, works, main)));
      }
    }
  }

  final lines = <PurchaseLine>[];
  for (final m in project.materials) {
    final task = first[m.key];
    final day = task?.start ?? 0;
    final (lo, hi) = leadTimes[m.group] ?? (3, 7);
    final needed = start == null ? null : Schedule.addWorkingDays(start, day);
    lines.add((
      material: m,
      phase: task?.label ?? schedulePhases.first.label,
      neededDay: day,
      leadMin: lo,
      leadMax: hi,
      needed: needed,
      orderBy: needed == null
          ? null
          : DateTime(needed.year, needed.month, needed.day - hi),
    ));
  }
  double orderDay(PurchaseLine l) => l.neededDay - l.leadMax * 6 / 7;
  lines.sort((a, b) {
    final c = orderDay(a).compareTo(orderDay(b));
    return c != 0
        ? c
        : a.material.group.index.compareTo(b.material.group.index);
  });
  return lines;
}
