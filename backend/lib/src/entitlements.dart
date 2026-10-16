/// The plans the app is sold in.
enum Plan { free, business, enterprise }

/// Where an account's plan comes from.
enum PlanSource { free, trial, paid, organization }

/// Roles in an organization, from most to least rights.
enum Role {
  owner,
  admin,
  estimator,
  viewer;

  static Role? byName(String? name) {
    for (final r in values) {
      if (r.name == name) return r;
    }
    return null;
  }

  /// Can add, remove and change members and the company price book.
  bool get manages => this == owner || this == admin;

  /// Can change the company's projects.
  bool get edits => this != viewer;
}

/// An organization membership, as the plan sees it.
typedef OrgAccess = ({
  String id,
  String name,
  Role role,
  int seats,
  DateTime? paidUntil,
});

/// What an account may use right now.
class Entitlement {
  const Entitlement({
    required this.plan,
    required this.source,
    this.trialEndsAt,
    this.paidUntil,
    this.inGrace = false,
    this.trialAvailable = false,
    this.organization,
    this.projectLimit,
  });

  final Plan plan;
  final PlanSource source;
  final DateTime? trialEndsAt;

  /// When the paid plan (the account's own, or its organization's) ends.
  final DateTime? paidUntil;

  /// Paid time has run out but the grace days have not.
  final bool inGrace;

  /// The account has never had a trial and is not paying.
  final bool trialAvailable;

  /// The organization that gives the Enterprise plan.
  final OrgAccess? organization;

  /// Projects the account may keep in the cloud; null for no limit.
  final int? projectLimit;

  Map<String, dynamic> toJson() => {
    'plan': plan.name,
    'source': source.name,
    'trialEndsAt': trialEndsAt?.toUtc().toIso8601String(),
    'paidUntil': paidUntil?.toUtc().toIso8601String(),
    'inGrace': inGrace,
    'trialAvailable': trialAvailable,
    'organization': organization == null
        ? null
        : {
            'id': organization!.id,
            'name': organization!.name,
            'role': organization!.role.name,
            'seats': organization!.seats,
          },
    'projectLimit': projectLimit,
  };
}

/// Works out an account's plan at [now]: an active organization gives
/// Enterprise, the account's own paid time gives Business, then a running
/// trial gives Business, and otherwise the plan is free. Paid time keeps
/// working for [graceDays] after it ends.
Entitlement resolveEntitlement({
  required DateTime now,
  DateTime? trialStartedAt,
  DateTime? trialEndsAt,
  DateTime? paidUntil,
  List<OrgAccess> organizations = const [],
  int graceDays = 3,
  int freeProjects = 2,
}) {
  final grace = Duration(days: graceDays);
  bool active(DateTime? until) =>
      until != null && now.isBefore(until.add(grace));

  final orgs = [
    for (final o in organizations)
      if (active(o.paidUntil)) o,
  ]..sort((a, b) => b.paidUntil!.compareTo(a.paidUntil!));
  if (orgs.isNotEmpty) {
    final org = orgs.first;
    return Entitlement(
      plan: Plan.enterprise,
      source: PlanSource.organization,
      paidUntil: org.paidUntil,
      inGrace: !now.isBefore(org.paidUntil!),
      organization: org,
    );
  }
  if (active(paidUntil)) {
    return Entitlement(
      plan: Plan.business,
      source: PlanSource.paid,
      paidUntil: paidUntil,
      inGrace: !now.isBefore(paidUntil!),
      trialEndsAt: trialEndsAt,
    );
  }
  if (trialEndsAt != null && now.isBefore(trialEndsAt)) {
    return Entitlement(
      plan: Plan.business,
      source: PlanSource.trial,
      trialEndsAt: trialEndsAt,
      paidUntil: paidUntil,
    );
  }
  return Entitlement(
    plan: Plan.free,
    source: PlanSource.free,
    trialEndsAt: trialEndsAt,
    paidUntil: paidUntil,
    trialAvailable: trialStartedAt == null,
    projectLimit: freeProjects,
  );
}
