import 'package:flutter/foundation.dart';

import 'boq.dart';
import 'estimate.dart';
import 'project.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// What a quote or a bill for bidders covers: the whole job, or one
/// section of the bill of quantities.
typedef BidScope = ({String key, String letter, String label});

/// The scope key for the whole job.
const wholeJob = 'job';

/// The scope key for section F, general requirements and hauling.
const generalScope = 'general';

/// Every scope, in bill of quantities order: the whole job, the trades
/// A–E, then general requirements.
final List<BidScope> bidScopes = [
  (key: wholeJob, letter: '', label: 'Whole job'),
  for (final (trade, letter) in tradeSections)
    (key: trade?.name ?? 'other', letter: letter, label: tradeLabel(trade)),
  (key: generalScope, letter: 'F', label: 'General requirements'),
];

/// The scope with [key]; the whole job for a key this version does not
/// know.
BidScope bidScope(String key) =>
    bidScopes.firstWhere((s) => s.key == key, orElse: () => bidScopes.first);

/// The scopes [project] has work in: the whole job, its trades and, when
/// it has any, its general requirements.
List<BidScope> scopesOf(Project project) {
  final trades = {
    for (final s in workSections(project)) s.trade?.name ?? 'other',
  };
  return [
    for (final s in bidScopes)
      if (s.key == wholeJob ||
          trades.contains(s.key) ||
          (s.key == generalScope && generalLines(project).isNotEmpty))
        s,
  ];
}

/// The app's estimate for [scope]: its direct cost and, [withMarkups], its
/// share of the contingency, markups and VAT, spread in proportion to
/// direct cost as in the contract lines. For the whole job with markups it
/// is the project total.
double scopeEstimate(Project project, String scope, {bool withMarkups = true}) {
  final b = project.breakdown;
  if (scope == wholeJob) return withMarkups ? b.total : b.direct;
  final direct = scope == generalScope
      ? generalLines(project).fold<double>(0, (s, g) => s + g.amount)
      : workSections(project)
            .where((s) => (s.trade?.name ?? 'other') == scope)
            .expand((s) => s.entries)
            .fold<double>(0, (s, e) => s + e.analysis.directCost);
  return _centavos(
    withMarkups && b.direct > 0 ? direct * b.total / b.direct : direct,
  );
}

/// A price from a bidder or subcontractor for the whole job or one
/// section of it.
@immutable
class BidQuote {
  const BidQuote({
    required this.id,
    required this.bidder,
    required this.amount,
    required this.date,
    this.scope = wholeJob,
    this.validityDays = 30,
    this.inclusions = '',
    this.exclusions = '',
    this.awarded = false,
  });

  factory BidQuote.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    if (id is! String || amount is! num || !amount.isFinite) {
      throw FormatException('BidQuote is malformed', json);
    }
    String text(String key) => json[key] is String ? json[key] as String : '';
    final days = json['validityDays'];
    return BidQuote(
      id: id,
      bidder: text('bidder'),
      amount: amount.toDouble(),
      date:
          DateTime.tryParse(text('date')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scope: json['scope'] is String ? json['scope'] as String : wholeJob,
      validityDays: days is num && days.isFinite && days >= 0
          ? days.toInt()
          : 30,
      inclusions: text('inclusions'),
      exclusions: text('exclusions'),
      awarded: json['awarded'] == true,
    );
  }

  final String id;

  /// The contractor, subcontractor or supplier's name.
  final String bidder;

  /// The quoted price in pesos, as the bidder wrote it.
  final double amount;

  /// The date on the quote.
  final DateTime date;

  /// A [BidScope] key.
  final String scope;

  /// Days the price holds from [date].
  final int validityDays;

  /// What the bidder says is included and left out, as typed.
  final String inclusions;
  final String exclusions;

  /// Whether this quote won the work in its scope.
  final bool awarded;

  DateTime get validUntil => DateTime(
    date.year,
    date.month,
    date.day,
  ).add(Duration(days: validityDays));

  /// Whether the price no longer holds on [today].
  bool isExpiredOn(DateTime today) =>
      DateTime(today.year, today.month, today.day).isAfter(validUntil);

  BidQuote copyWith({
    String? bidder,
    double? amount,
    DateTime? date,
    String? scope,
    int? validityDays,
    String? inclusions,
    String? exclusions,
    bool? awarded,
  }) => BidQuote(
    id: id,
    bidder: bidder ?? this.bidder,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    scope: scope ?? this.scope,
    validityDays: validityDays ?? this.validityDays,
    inclusions: inclusions ?? this.inclusions,
    exclusions: exclusions ?? this.exclusions,
    awarded: awarded ?? this.awarded,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bidder': bidder,
    'amount': amount,
    'date': date.toIso8601String().substring(0, 10),
    if (scope != wholeJob) 'scope': scope,
    if (validityDays != 30) 'validityDays': validityDays,
    if (inclusions.isNotEmpty) 'inclusions': inclusions,
    if (exclusions.isNotEmpty) 'exclusions': exclusions,
    if (awarded) 'awarded': true,
  };

  /// A fresh id for a quote.
  static String newId() => Estimate.newId(DateTime.now());
}

/// Reads saved quotes, skipping damaged ones.
List<BidQuote> quotesFromJson(Object? json) {
  if (json is! List) return const [];
  final out = <BidQuote>[];
  for (final raw in json) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      out.add(BidQuote.fromJson(raw));
    } on FormatException {
      // Skip a damaged quote.
    }
  }
  return List.unmodifiable(out);
}

/// [quotes] with [id] awarded and any other quote for the same scope not;
/// awarding the awarded quote again takes the award away.
List<BidQuote> awardQuote(List<BidQuote> quotes, String id) {
  final chosen = quotes.where((q) => q.id == id).firstOrNull;
  if (chosen == null) return quotes;
  return List.unmodifiable([
    for (final q in quotes)
      q.id == id
          ? q.copyWith(awarded: !q.awarded)
          : q.scope == chosen.scope && q.awarded
          ? q.copyWith(awarded: false)
          : q,
  ]);
}

/// A quote this far below the estimate, in percent, is flagged: a price
/// that low often means part of the scope was missed.
const farBelowPct = 20.0;

/// One quote against the estimate for its scope.
typedef QuoteCheck = ({
  BidQuote quote,

  /// Quote minus estimate, in pesos: below zero when the quote is lower.
  double difference,

  /// [difference] as a percentage of the estimate; null without one.
  double? percent,

  /// The lowest quote for its scope.
  bool lowest,

  /// More than [farBelowPct] below the estimate.
  bool farBelow,
});

/// The quotes for one scope, lowest first, against the app's estimate.
typedef ScopeQuotes = ({
  BidScope scope,
  double estimate,
  List<QuoteCheck> quotes,
});

/// [project]'s quotes grouped by scope in bill of quantities order, each
/// against [scopeEstimate].
List<ScopeQuotes> compareQuotes(Project project, {bool withMarkups = true}) => [
  for (final s in bidScopes)
    if (project.quotes.any((q) => bidScope(q.scope).key == s.key))
      () {
        final estimate = scopeEstimate(
          project,
          s.key,
          withMarkups: withMarkups,
        );
        final quotes = [
          for (final q in project.quotes)
            if (bidScope(q.scope).key == s.key) q,
        ]..sort((a, b) => a.amount.compareTo(b.amount));
        final low = quotes.first.amount;
        return (
          scope: s,
          estimate: estimate,
          quotes: [
            for (final q in quotes)
              () {
                final percent = estimate > 0
                    ? (q.amount - estimate) / estimate * 100
                    : null;
                return (
                  quote: q,
                  difference: _centavos(q.amount - estimate),
                  percent: percent == null
                      ? null
                      : (percent * 10).roundToDouble() / 10,
                  lowest: q.amount == low,
                  farBelow: percent != null && percent < -farBelowPct,
                );
              }(),
          ],
        );
      }(),
];
