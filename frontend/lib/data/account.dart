import 'package:flutter/foundation.dart';

/// The editions the app is sold in.
enum AppPlan {
  free('Homeowners Edition'),
  business('Business Edition'),
  enterprise('Enterprise Edition');

  const AppPlan(this.label);

  final String label;
}

DateTime? _date(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toUtc() : null;

/// An account and its plan as the server last reported them, kept on the
/// device so the plan still applies offline.
@immutable
class AccountStatus {
  const AccountStatus({
    required this.userId,
    required this.email,
    this.name = '',
    this.isAdmin = false,
    this.plan = AppPlan.free,
    this.source = 'free',
    this.trialEndsAt,
    this.paidUntil,
    this.trialAvailable = false,
    this.organization,
    this.orgRole,
    this.projectLimit,
    required this.raw,
  });

  /// Reads the answer of `GET /v1/me`.
  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map : const {};
    final plan = json['plan'] is Map ? json['plan'] as Map : const {};
    final org = plan['organization'] is Map
        ? plan['organization'] as Map
        : null;
    return AccountStatus(
      userId: '${user['id'] ?? ''}',
      email: '${user['email'] ?? ''}',
      name: user['name'] is String ? user['name'] as String : '',
      isAdmin: user['isAdmin'] == true,
      plan: AppPlan.values.asNameMap()[plan['plan']] ?? AppPlan.free,
      source: plan['source'] is String ? plan['source'] as String : 'free',
      trialEndsAt: _date(plan['trialEndsAt']),
      paidUntil: _date(plan['paidUntil']),
      trialAvailable: plan['trialAvailable'] == true,
      organization: org?['name'] as String?,
      orgRole: org?['role'] as String?,
      projectLimit: plan['projectLimit'] is int
          ? plan['projectLimit'] as int
          : null,
      raw: json,
    );
  }

  final String userId;
  final String email;
  final String name;
  final bool isAdmin;

  /// The plan the server reported.
  final AppPlan plan;

  /// `free`, `trial`, `paid` or `organization`.
  final String source;
  final DateTime? trialEndsAt;
  final DateTime? paidUntil;
  final bool trialAvailable;

  /// The company that gives the Enterprise plan, and the user's role in it.
  final String? organization;
  final String? orgRole;

  /// Cloud projects allowed; null for no limit.
  final int? projectLimit;

  /// The server's answer, saved as it came.
  final Map<String, dynamic> raw;

  bool get onTrial => source == 'trial';

  /// The plan at [now], worked out from the saved dates so a trial or a
  /// paid month ends on time even without a connection. Paid time keeps
  /// working [graceDays] after it ends, as on the server.
  AppPlan planAt(DateTime now, {int graceDays = 3}) {
    final grace = Duration(days: graceDays);
    switch (source) {
      case 'organization' || 'paid':
        final until = paidUntil;
        return until != null && now.isBefore(until.add(grace))
            ? plan
            : AppPlan.free;
      case 'trial':
        final ends = trialEndsAt;
        return ends != null && now.isBefore(ends) ? plan : AppPlan.free;
      default:
        return AppPlan.free;
    }
  }

  /// Whole days left in the trial at [now], at least 1 while it runs.
  int trialDaysLeft(DateTime now) {
    final ends = trialEndsAt;
    if (ends == null || !now.isBefore(ends)) return 0;
    return (ends.difference(now).inHours / 24).ceil();
  }
}

/// The plans' prices and limits, from `GET /v1/plans`, with the launch
/// figures until the server has answered.
@immutable
class PlanOffer {
  const PlanOffer({
    this.businessUsd = 20,
    this.businessPhp = 1150,
    this.trialDays = 14,
    this.freeProjects = 2,
    this.salesEmail = '',
    this.signInEnabled = true,
  });

  factory PlanOffer.fromJson(Map<String, dynamic> json) {
    final plans = json['plans'] is List ? json['plans'] as List : const [];
    final business = plans.whereType<Map<String, dynamic>>().firstWhere(
      (p) => p['id'] == 'business',
      orElse: () => const <String, dynamic>{},
    );
    int number(Object? v, int fallback) => v is num ? v.round() : fallback;
    return PlanOffer(
      businessUsd: number(business['priceUsd'], 20),
      businessPhp: number(business['pricePhp'], 1150),
      trialDays: number(json['trialDays'], 14),
      freeProjects: number(json['freeProjects'], 2),
      salesEmail: json['salesEmail'] is String
          ? json['salesEmail'] as String
          : '',
      signInEnabled: json['signInEnabled'] != false,
    );
  }

  final int businessUsd;
  final int businessPhp;
  final int trialDays;
  final int freeProjects;
  final String salesEmail;
  final bool signInEnabled;
}
