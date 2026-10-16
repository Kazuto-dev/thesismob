import 'boq.dart';
import 'contract.dart';
import 'project.dart';

export 'schedule.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// A line of the contract: a work item, a general requirement or a
/// variation order, with its share of the contract price (markups and VAT
/// included).
typedef ContractLine = ({
  String key,
  String number,
  String description,
  double quantity,
  String unit,
  double amount,
});

/// The project's contract lines, numbered as in the bill of quantities.
/// Markups and VAT are spread over the lines in proportion to their direct
/// cost, so the lines add up to the contract price.
List<ContractLine> contractLines(Project project) {
  final b = project.breakdown;
  final factor = b.direct > 0 ? b.total / b.direct : 1.0;
  final lines = <ContractLine>[];
  for (final section in workSections(project)) {
    for (final (:number, :analysis) in section.entries) {
      final a = analysis;
      lines.add((
        key: '${a.estimate.id}|${a.work.key}',
        number: number,
        description: workDescription(a),
        quantity: a.quantity,
        unit: a.unit,
        amount: _centavos(a.directCost * factor),
      ));
    }
  }
  for (final (i, g) in generalLines(project).indexed) {
    lines.add((
      key: 'general|${g.key}',
      number: 'F.${i + 1}',
      description: g.description,
      quantity: g.quantity,
      unit: g.unit,
      amount: _centavos(g.amount * factor),
    ));
  }
  // Put the rounding difference on the largest line, so the lines add up
  // to the total exactly.
  if (lines.isNotEmpty) {
    final sum = lines.fold<double>(0, (s, l) => s + l.amount);
    final diff = _centavos(b.total - sum);
    if (diff != 0) {
      var largest = 0;
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].amount > lines[largest].amount) largest = i;
      }
      final l = lines[largest];
      lines[largest] = (
        key: l.key,
        number: l.number,
        description: l.description,
        quantity: l.quantity,
        unit: l.unit,
        amount: _centavos(l.amount + diff),
      );
    }
  }
  for (final (i, v) in project.contract.variations.indexed) {
    lines.add((
      key: 'vo|${v.id}',
      number: 'VO-${i + 1}',
      description: v.description,
      quantity: 1,
      unit: 'lot',
      amount: _centavos(v.amount),
    ));
  }
  return lines;
}

/// The original contract price plus the variation orders.
double contractPrice(Project project) =>
    _centavos(project.breakdown.total + project.contract.variationsTotal);

/// One progress billing worked out: what was accomplished, less what was
/// billed before, the downpayment recouped and the retention held, and
/// what the contractor receives once the client withholds its taxes.
typedef BillingStatement = ({
  int number,
  DateTime date,
  double percentComplete,
  double toDate,
  double previous,
  double thisPeriod,
  double recoupment,
  double retention,
  double netDue,

  /// Creditable income tax the client withholds, on this billing before
  /// VAT.
  double incomeTax,

  /// VAT, or percentage tax, the government withholds, on this billing
  /// before VAT.
  double businessTax,

  /// All the taxes withheld: [incomeTax] and [businessTax].
  double withholding,

  /// What the contractor receives: [netDue] less [withholding].
  double received,
});

/// The value of the work done by [billing], over [lines].
double accomplished(List<ContractLine> lines, Billing billing) => _centavos(
  lines.fold(
    0,
    (s, l) => s + l.amount * (billing.progress[l.key] ?? 0).clamp(0, 100) / 100,
  ),
);

/// Every billing of the project, in order.
List<BillingStatement> billingStatements(Project project) {
  final lines = contractLines(project);
  final price = contractPrice(project);
  final terms = project.contract.terms;
  final rates = withholding(project);
  final vat = project.costs.vatPct;
  var previous = 0.0;
  final out = <BillingStatement>[];
  for (final (i, b) in project.contract.billings.indexed) {
    final toDate = accomplished(lines, b);
    final period = _centavos(toDate - previous);
    final recoupment = _centavos(period * terms.downpaymentPct / 100);
    final retention = _centavos(period * terms.retentionPct / 100);
    final netDue = _centavos(period - recoupment - retention);
    final base = period / (1 + vat / 100);
    final incomeTax = _centavos(base * rates.incomeTax / 100);
    final businessTax = _centavos(base * rates.businessTax / 100);
    out.add((
      number: i + 1,
      date: b.date,
      percentComplete: price <= 0 ? 0 : toDate / price * 100,
      toDate: toDate,
      previous: previous,
      thisPeriod: period,
      recoupment: recoupment,
      retention: retention,
      netDue: netDue,
      incomeTax: incomeTax,
      businessTax: businessTax,
      withholding: _centavos(incomeTax + businessTax),
      received: _centavos(netDue - incomeTax - businessTax),
    ));
    previous = toDate;
  }
  return out;
}

/// The taxes [project]'s client withholds from each billing, by the
/// client type in its quotation terms and whether its price carries VAT.
WithholdingRates withholding(Project project) => withholdingRates(
  project.contract.terms.client,
  vatRegistered: project.costs.vatPct > 0,
);

/// What the money spent says about the estimate: the budgeted materials
/// and labour of the work done by the latest billing (earned) against the
/// expenses recorded for them.
typedef ActualsReview = ({
  /// Percent complete by the latest billing.
  double percentComplete,
  double earnedMaterials,
  double spentMaterials,
  double earnedLabour,
  double spentLabour,

  /// How fast the crews work against the estimate, in percent: earned
  /// labour ÷ labour spent × 100. Null before any labour is recorded.
  double? productivity,

  /// The productivity setting that matches what the crews did: the
  /// project's own times [productivity]. Null when labour is not priced
  /// by crews or nothing is known yet.
  double? suggestedProductivity,
});

/// [project]'s [ActualsReview], or null before the first billing with
/// progress.
ActualsReview? reviewActuals(Project project) {
  final billings = project.contract.billings;
  if (billings.isEmpty) return null;
  final progress = billings.last.progress;
  var materials = 0.0;
  var labour = 0.0;
  for (final section in workSections(project)) {
    for (final (number: _, :analysis) in section.entries) {
      final a = analysis;
      final done =
          (progress['${a.estimate.id}|${a.work.key}'] ?? 0).clamp(0, 100) / 100;
      materials += a.materialCost * done;
      labour += a.labourCost * done;
    }
  }
  if (materials <= 0 && labour <= 0) return null;
  double spent(ExpenseKind kind) => project.contract.expenses
      .where((e) => e.kind == kind)
      .fold(0, (s, e) => s + e.amount);
  final spentLabour = spent(ExpenseKind.labour);
  final productivity = spentLabour > 0 && labour > 0
      ? labour / spentLabour * 100
      : null;
  final costs = project.costs;
  return (
    percentComplete: billingStatements(project).last.percentComplete,
    earnedMaterials: _centavos(materials),
    spentMaterials: _centavos(spent(ExpenseKind.materials)),
    earnedLabour: _centavos(labour),
    spentLabour: _centavos(spentLabour),
    productivity: productivity,
    suggestedProductivity:
        productivity == null || costs.labourMethod != LabourMethod.crews
        ? null
        : (costs.productivityPct * productivity / 100)
              .roundToDouble()
              .clamp(25, 200)
              .toDouble(),
  );
}

/// The name of the business tax [project]'s client withholds: VAT from a
/// VAT-registered contractor, percentage tax from one that is not.
String businessTaxName(Project project) =>
    project.costs.vatPct > 0 ? 'VAT' : 'percentage tax';

/// The downpayment billed on signing.
double downpayment(Project project) => _centavos(
  project.breakdown.total * project.contract.terms.downpaymentPct / 100,
);
