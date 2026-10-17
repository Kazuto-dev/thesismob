import 'package:flutter/foundation.dart';

import 'estimate.dart';

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

double _number(Object? value, double fallback) =>
    value is num && value.isFinite ? value.toDouble() : fallback;

String _text(Object? value) => value is String ? value : '';

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

/// Who the client is, which sets the taxes they withhold from each
/// payment to a contractor.
enum ClientType {
  /// A homeowner or other person not in business, who withholds nothing.
  individual('Individual or household'),

  /// A corporation or other business, which withholds 2% creditable
  /// income tax (expanded withholding tax) on payments to contractors.
  company('Private company'),

  /// A national agency, local government or government corporation,
  /// which also withholds 5% VAT, or 3% percentage tax from a contractor
  /// not registered for VAT.
  government('Government');

  const ClientType(this.label);

  final String label;
}

/// The taxes a client withholds from a payment, as percentages of the
/// amount before VAT.
typedef WithholdingRates = ({
  /// Creditable income tax: the expanded withholding tax on contractors.
  double incomeTax,

  /// VAT withheld by government from a VAT-registered contractor, or
  /// percentage tax from one that is not.
  double businessTax,
});

/// The taxes [client] withholds from a contractor's payments:
/// RR 2-98 as amended by RR 11-2018 for the 2% on contractors, NIRC
/// sec. 114(C) as amended by the TRAIN law for the 5% VAT (creditable
/// since 2021), and NIRC sec. 116 for the 3% percentage tax.
/// [vatRegistered] is whether the contractor charges VAT.
WithholdingRates withholdingRates(
  ClientType client, {
  required bool vatRegistered,
}) => switch (client) {
  ClientType.individual => (incomeTax: 0, businessTax: 0),
  ClientType.company => (incomeTax: 2, businessTax: 0),
  ClientType.government => (incomeTax: 2, businessTax: vatRegistered ? 5 : 3),
};

/// The terms a quotation offers: how long it is valid, how the client
/// pays, the warranty, and what is and is not included.
@immutable
class QuoteTerms {
  const QuoteTerms({
    this.validityDays = 30,
    this.downpaymentPct = 30,
    this.retentionPct = 10,
    this.warrantyMonths = 12,
    this.inclusions = '',
    this.exclusions = '',
    this.client = ClientType.individual,
    this.paymentDays = 30,
  });

  factory QuoteTerms.fromJson(Map<String, dynamic> json) => QuoteTerms(
    validityDays: _number(json['validityDays'], 30),
    downpaymentPct: _number(json['downpaymentPct'], 30),
    retentionPct: _number(json['retentionPct'], 10),
    warrantyMonths: _number(json['warrantyMonths'], 12),
    inclusions: _text(json['inclusions']),
    exclusions: _text(json['exclusions']),
    client: ClientType.values.firstWhere(
      (c) => c.name == json['client'],
      orElse: () => ClientType.individual,
    ),
    paymentDays: _number(json['paymentDays'], 30).clamp(0, 365).toDouble(),
  );

  final double validityDays;

  /// Paid on signing, then recouped from each progress billing.
  final double downpaymentPct;

  /// Held back from each billing until the work is accepted.
  final double retentionPct;
  final double warrantyMonths;

  /// The user's own scope notes, one item per line.
  final String inclusions;
  final String exclusions;

  /// Who the client is, for the taxes withheld from billings.
  final ClientType client;

  /// Days the client takes to pay a billing, for the cash flow.
  final double paymentDays;

  static const defaultExclusions =
      'Building permit and professional fees\n'
      'Utility connections and meter deposits\n'
      'Furniture, appliances and loose fixtures\n'
      'Work not shown in the bill of quantities';

  QuoteTerms copyWith({
    double? validityDays,
    double? downpaymentPct,
    double? retentionPct,
    double? warrantyMonths,
    String? inclusions,
    String? exclusions,
    ClientType? client,
    double? paymentDays,
  }) => QuoteTerms(
    validityDays: validityDays ?? this.validityDays,
    downpaymentPct: downpaymentPct ?? this.downpaymentPct,
    retentionPct: retentionPct ?? this.retentionPct,
    warrantyMonths: warrantyMonths ?? this.warrantyMonths,
    inclusions: inclusions ?? this.inclusions,
    exclusions: exclusions ?? this.exclusions,
    client: client ?? this.client,
    paymentDays: paymentDays ?? this.paymentDays,
  );

  Map<String, dynamic> toJson() => {
    'validityDays': validityDays,
    'downpaymentPct': downpaymentPct,
    'retentionPct': retentionPct,
    'warrantyMonths': warrantyMonths,
    if (inclusions.isNotEmpty) 'inclusions': inclusions,
    if (exclusions.isNotEmpty) 'exclusions': exclusions,
    if (client != ClientType.individual) 'client': client.name,
    if (paymentDays != 30) 'paymentDays': paymentDays,
  };

  @override
  bool operator ==(Object other) =>
      other is QuoteTerms &&
      other.validityDays == validityDays &&
      other.downpaymentPct == downpaymentPct &&
      other.retentionPct == retentionPct &&
      other.warrantyMonths == warrantyMonths &&
      other.inclusions == inclusions &&
      other.exclusions == exclusions &&
      other.client == client &&
      other.paymentDays == paymentDays;

  @override
  int get hashCode => Object.hash(
    validityDays,
    downpaymentPct,
    retentionPct,
    warrantyMonths,
    inclusions,
    exclusions,
    client,
    paymentDays,
  );
}

/// A change to the contract after it was agreed: extra work (a positive
/// [amount]) or work taken out (negative), in pesos including markups.
@immutable
class VariationOrder {
  const VariationOrder({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  factory VariationOrder.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) throw FormatException('VariationOrder', json);
    return VariationOrder(
      id: id,
      date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      description: _text(json['description']),
      amount: _number(json['amount'], 0),
    );
  }

  final String id;
  final DateTime date;
  final String description;
  final double amount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': _day(date),
    'description': description,
    'amount': amount,
  };
}

/// What was actually spent, to compare with the budget.
enum ExpenseKind {
  materials('Materials'),
  labour('Labour'),
  equipment('Equipment'),
  subcontract('Subcontract'),
  other('Other');

  const ExpenseKind(this.label);

  final String label;
}

@immutable
class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.kind,
    required this.amount,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) throw FormatException('Expense', json);
    return Expense(
      id: id,
      date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      description: _text(json['description']),
      kind: ExpenseKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ExpenseKind.other,
      ),
      amount: _number(json['amount'], 0),
    );
  }

  final String id;
  final DateTime date;
  final String description;
  final ExpenseKind kind;
  final double amount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': _day(date),
    'description': description,
    'kind': kind.name,
    'amount': amount,
  };
}

/// A progress billing: how far each line of the bill of quantities had
/// got by [date], as a cumulative percentage.
@immutable
class Billing {
  const Billing({
    required this.id,
    required this.date,
    this.progress = const {},
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) throw FormatException('Billing', json);
    return Billing(
      id: id,
      date: _date(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      progress: {
        for (final e in (json['progress'] as Map? ?? const {}).entries)
          if (e.key is String && e.value is num)
            e.key as String: (e.value as num).toDouble().clamp(0, 100),
      },
    );
  }

  final String id;
  final DateTime date;

  /// Cumulative percent complete, by contract line key.
  final Map<String, double> progress;

  Billing copyWith({DateTime? date, Map<String, double>? progress}) => Billing(
    id: id,
    date: date ?? this.date,
    progress: progress ?? this.progress,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': _day(date),
    'progress': progress,
  };
}

/// Everything that follows the estimate once a job goes ahead: the
/// quotation terms, the schedule settings, billings, changes and the
/// money actually spent.
@immutable
class ContractData {
  const ContractData({
    this.terms = const QuoteTerms(),
    this.startDate,
    this.crews = const {},
    this.billings = const [],
    this.variations = const [],
    this.expenses = const [],
    this.rainPct = defaultRainPct,
    this.targetWeeks,
    this.finishBy,
  });

  /// The usual allowance for rain and unworkable days: about one working
  /// day in ten, as in DPWH contract times.
  static const defaultRainPct = 10.0;

  factory ContractData.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final out = <T>[];
      for (final raw in json[key] as List? ?? const []) {
        if (raw is! Map<String, dynamic>) continue;
        try {
          out.add(parse(raw));
        } on FormatException {
          // Skip a damaged entry.
        }
      }
      return List.unmodifiable(out);
    }

    return ContractData(
      terms: json['terms'] is Map<String, dynamic>
          ? QuoteTerms.fromJson(json['terms'] as Map<String, dynamic>)
          : const QuoteTerms(),
      startDate: _date(json['startDate']),
      crews: {
        for (final e in (json['crews'] as Map? ?? const {}).entries)
          if (e.key is String && e.value is num && (e.value as num) >= 1)
            e.key as String: (e.value as num).toDouble(),
      },
      billings: list('billings', Billing.fromJson),
      variations: list('variations', VariationOrder.fromJson),
      expenses: list('expenses', Expense.fromJson),
      rainPct: _number(
        json['rainPct'],
        defaultRainPct,
      ).clamp(0, 100).toDouble(),
      targetWeeks:
          json['targetWeeks'] is num && (json['targetWeeks'] as num) > 0
          ? (json['targetWeeks'] as num).toDouble()
          : null,
      finishBy: _date(json['finishBy']),
    );
  }

  final QuoteTerms terms;

  /// The first working day, for the schedule.
  final DateTime? startDate;

  /// Crews working at once in the trades the user has set, by category
  /// name (`other` for other works). The schedule sizes the crews of the
  /// other trades itself.
  final Map<String, double> crews;
  final List<Billing> billings;
  final List<VariationOrder> variations;
  final List<Expense> expenses;

  /// Allowance for rain and unworkable days, as a percentage of the
  /// working days.
  final double rainPct;

  /// The working weeks the job should take, when the user set a target.
  final double? targetWeeks;

  /// The date the job should finish by, when the user set one. It needs a
  /// [startDate], and wins over [targetWeeks].
  final DateTime? finishBy;

  bool get isEmpty =>
      terms == const QuoteTerms() &&
      startDate == null &&
      crews.isEmpty &&
      billings.isEmpty &&
      variations.isEmpty &&
      expenses.isEmpty &&
      rainPct == defaultRainPct &&
      targetWeeks == null &&
      finishBy == null;

  /// The crews the user set for [trade], or 1. A schedule's own
  /// `crewsFor` gives the crews it uses, sized by the app where unset.
  double crewsFor(String trade) => crews[trade] ?? 1;

  /// This contract with the finish-by target set to [weeks] or [date],
  /// or cleared when both are null.
  ContractData withTarget({double? weeks, DateTime? date}) => ContractData(
    terms: terms,
    startDate: startDate,
    crews: crews,
    billings: billings,
    variations: variations,
    expenses: expenses,
    rainPct: rainPct,
    targetWeeks: weeks,
    finishBy: date,
  );

  double get variationsTotal => variations.fold(0, (s, v) => s + v.amount);

  double get spent => expenses.fold(0, (s, e) => s + e.amount);

  ContractData copyWith({
    QuoteTerms? terms,
    DateTime? startDate,
    Map<String, double>? crews,
    List<Billing>? billings,
    List<VariationOrder>? variations,
    List<Expense>? expenses,
    double? rainPct,
  }) => ContractData(
    terms: terms ?? this.terms,
    startDate: startDate ?? this.startDate,
    crews: crews ?? this.crews,
    billings: billings ?? this.billings,
    variations: variations ?? this.variations,
    expenses: expenses ?? this.expenses,
    rainPct: rainPct ?? this.rainPct,
    targetWeeks: targetWeeks,
    finishBy: finishBy,
  );

  Map<String, dynamic> toJson() => {
    'terms': terms.toJson(),
    if (startDate != null) 'startDate': _day(startDate!),
    if (crews.isNotEmpty) 'crews': crews,
    if (billings.isNotEmpty) 'billings': [for (final b in billings) b.toJson()],
    if (variations.isNotEmpty)
      'variations': [for (final v in variations) v.toJson()],
    if (expenses.isNotEmpty) 'expenses': [for (final e in expenses) e.toJson()],
    if (rainPct != defaultRainPct) 'rainPct': rainPct,
    if (targetWeeks != null) 'targetWeeks': targetWeeks,
    if (finishBy != null) 'finishBy': _day(finishBy!),
  };

  /// A fresh id for a billing, change or expense.
  static String newId() => Estimate.newId(DateTime.now());
}
