import 'package:postgres/postgres.dart';

import 'config.dart';
import 'entitlements.dart';
import 'errors.dart';
import 'google.dart';
import 'secrets.dart';

/// An account.
typedef User = ({String id, String email, String name});

/// A code just issued; [code] is shown this once.
typedef IssuedCode = ({
  String id,
  String code,
  Plan plan,
  int months,
  int seats,
  String? email,
  DateTime redeemBy,
});

/// A cloud project as listed, without its data.
typedef ProjectSummary = ({
  String id,
  String name,
  int version,
  DateTime updatedAt,
  String? orgId,
  String ownerEmail,
  bool readOnly,
});

User _user(Map<String, dynamic> row) => (
  id: row['id'] as String,
  email: row['email'] as String,
  name: row['name'] as String,
);

String _iso(DateTime? d) => d?.toUtc().toIso8601String() ?? '';

/// Every read and write of the database, with the rules that go with
/// them: who may see and change what, plan limits, and the audit log.
class Store {
  Store(this.pool, this.config, {DateTime Function()? clock})
    : now = clock ?? (() => DateTime.now().toUtc());

  final Pool<void> pool;
  final Config config;

  /// The current time; tests move it to check trials and expiry.
  final DateTime Function() now;

  Future<List<Map<String, dynamic>>> _rows(
    Session s,
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) async => [
    for (final r in await s.execute(Sql.named(sql), parameters: parameters))
      r.toColumnMap(),
  ];

  Future<Map<String, dynamic>?> _row(
    Session s,
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final rows = await _rows(s, sql, parameters);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _audit(
    Session s,
    String actor,
    String action, {
    String target = '',
    Map<String, Object?> details = const {},
  }) => s.execute(
    Sql.named(
      'insert into audit_log (at, actor, action, target, details) '
      'values (@at:timestamptz, @actor, @action, @target, @details:jsonb)',
    ),
    parameters: {
      'at': now(),
      'actor': actor,
      'action': action,
      'target': target,
      'details': details,
    },
  );

  // Accounts and sessions

  /// The account for a Google sign-in, created on first sign-in. Pending
  /// invitations to companies for its email are accepted.
  Future<User> signInWithGoogle(GoogleIdentity identity) => pool.runTx((
    tx,
  ) async {
    final at = now();
    final existing = await _row(
      tx,
      'select id, email, name from users '
      'where google_sub = @sub or lower(email) = lower(@email) '
      'order by (google_sub = @sub) desc nulls last limit 1',
      {'sub': identity.subject, 'email': identity.email},
    );
    final Map<String, dynamic> row;
    if (existing == null) {
      row = (await _row(
        tx,
        'insert into users (email, name, google_sub, created_at, '
        'last_seen_at) values (@email, @name, @sub, @at:timestamptz, '
        '@at:timestamptz) returning id, email, name',
        {
          'email': identity.email,
          'name': identity.name,
          'sub': identity.subject,
          'at': at,
        },
      ))!;
      await _audit(tx, identity.email, 'account.created');
    } else {
      row = (await _row(
        tx,
        'update users set google_sub = @sub, email = @email, '
        "name = case when @name = '' then name else @name end, "
        'last_seen_at = @at:timestamptz where id = @id:uuid '
        'returning id, email, name',
        {
          'id': existing['id'],
          'sub': identity.subject,
          'email': identity.email,
          'name': identity.name,
          'at': at,
        },
      ))!;
    }
    final user = _user(row);
    final invites = await _rows(
      tx,
      'delete from invitations where email = lower(@email) '
      'returning org_id, role',
      {'email': user.email},
    );
    for (final i in invites) {
      await tx.execute(
        Sql.named(
          'insert into memberships (org_id, user_id, role, created_at) '
          'values (@org:uuid, @user:uuid, @role, @at:timestamptz) '
          'on conflict do nothing',
        ),
        parameters: {
          'org': i['org_id'],
          'user': user.id,
          'role': i['role'],
          'at': at,
        },
      );
      await _audit(tx, user.email, 'org.joined', target: i['org_id'] as String);
    }
    return user;
  });

  /// A new session for [userId], valid for the configured days.
  Future<({String token, DateTime expiresAt})> createSession(
    String userId, {
    String userAgent = '',
  }) async {
    final token = newSessionToken();
    final at = now();
    final expires = at.add(Duration(days: config.sessionDays));
    await pool.execute(
      Sql.named(
        'insert into sessions (token_hash, user_id, created_at, last_used_at, '
        'expires_at, user_agent) values (@hash:bytea, @user:uuid, '
        '@at:timestamptz, @at:timestamptz, @expires:timestamptz, @agent)',
      ),
      parameters: {
        'hash': hashSecret(token),
        'user': userId,
        'at': at,
        'expires': expires,
        'agent': userAgent.length > 200
            ? userAgent.substring(0, 200)
            : userAgent,
      },
    );
    return (token: token, expiresAt: expires);
  }

  /// The account a session token belongs to, or null when the token is
  /// unknown or expired. A session in use is extended, at most once a day.
  Future<User?> userForToken(String token) async {
    final at = now();
    final row = await _row(
      pool,
      'select u.id, u.email, u.name, s.last_used_at from sessions s '
      'join users u on u.id = s.user_id '
      'where s.token_hash = @hash:bytea and s.expires_at > @at:timestamptz',
      {'hash': hashSecret(token), 'at': at},
    );
    if (row == null) return null;
    final lastUsed = row['last_used_at'] as DateTime;
    if (at.difference(lastUsed) > const Duration(days: 1)) {
      await pool.execute(
        Sql.named(
          'update sessions set last_used_at = @at:timestamptz, '
          'expires_at = @expires:timestamptz where token_hash = @hash:bytea',
        ),
        parameters: {
          'hash': hashSecret(token),
          'at': at,
          'expires': at.add(Duration(days: config.sessionDays)),
        },
      );
      await pool.execute(
        Sql.named(
          'update users set last_seen_at = @at:timestamptz where id = @id:uuid',
        ),
        parameters: {'at': at, 'id': row['id']},
      );
    }
    return _user(row);
  }

  Future<void> deleteSession(String token) => pool.execute(
    Sql.named('delete from sessions where token_hash = @hash:bytea'),
    parameters: {'hash': hashSecret(token)},
  );

  /// Signs the account out everywhere.
  Future<void> deleteSessionsOf(String userId) => pool.execute(
    Sql.named('delete from sessions where user_id = @id:uuid'),
    parameters: {'id': userId},
  );

  Future<User?> userById(String id) async {
    final row = await _row(
      pool,
      'select id, email, name from users where id = @id:uuid',
      {'id': id},
    );
    return row == null ? null : _user(row);
  }

  Future<User?> userByEmail(String email) async {
    final row = await _row(
      pool,
      'select id, email, name from users where lower(email) = lower(@email)',
      {'email': email},
    );
    return row == null ? null : _user(row);
  }

  /// Deletes the account and everything only it owns. Its companies stay
  /// with their other members.
  Future<void> deleteAccount(User user) => pool.runTx((tx) async {
    final owned = await _rows(
      tx,
      "select org_id from memberships where user_id = @id:uuid and role = 'owner'",
      {'id': user.id},
    );
    for (final o in owned) {
      final others = await _row(
        tx,
        'select count(*)::int as n from memberships where org_id = @org:uuid '
        "and role = 'owner' and user_id <> @id:uuid",
        {'org': o['org_id'], 'id': user.id},
      );
      if ((others!['n'] as int) == 0) {
        throw ApiError(
          409,
          'last_owner',
          'Make someone else an owner of your company before you delete '
              'your account.',
        );
      }
    }
    await tx.execute(
      Sql.named("delete from documents where scope = 'user:' || @id"),
      parameters: {'id': user.id},
    );
    await tx.execute(
      Sql.named('delete from users where id = @id:uuid'),
      parameters: {'id': user.id},
    );
    await _audit(tx, user.email, 'account.deleted');
  });

  // Plans

  Future<List<OrgAccess>> organizationsOf(String userId, [Session? s]) async =>
      [
        for (final r in await _rows(
          s ?? pool,
          'select o.id, o.name, o.seats, o.paid_until, m.role '
          'from memberships m join organizations o on o.id = m.org_id '
          'where m.user_id = @id:uuid order by o.created_at',
          {'id': userId},
        ))
          (
            id: r['id'] as String,
            name: r['name'] as String,
            role: Role.byName(r['role'] as String)!,
            seats: r['seats'] as int,
            paidUntil: r['paid_until'] as DateTime?,
          ),
      ];

  /// What [userId] may use right now.
  Future<Entitlement> entitlementOf(String userId, [Session? s]) async {
    final sub = await _row(
      s ?? pool,
      'select trial_started_at, trial_ends_at, paid_until from subscriptions '
      'where user_id = @id:uuid',
      {'id': userId},
    );
    return resolveEntitlement(
      now: now(),
      trialStartedAt: sub?['trial_started_at'] as DateTime?,
      trialEndsAt: sub?['trial_ends_at'] as DateTime?,
      paidUntil: sub?['paid_until'] as DateTime?,
      organizations: await organizationsOf(userId, s),
      graceDays: config.graceDays,
      freeProjects: config.freeProjects,
    );
  }

  /// Starts the account's one free trial of Business.
  Future<Entitlement> startTrial(User user) => pool.runTx((tx) async {
    final current = await entitlementOf(user.id, tx);
    if (current.plan != Plan.free) {
      throw ApiError(409, 'already_subscribed', 'You already have this plan.');
    }
    if (!current.trialAvailable) {
      throw ApiError(
        409,
        'trial_used',
        'The free trial has been used on this account.',
      );
    }
    final at = now();
    await tx.execute(
      Sql.named(
        'insert into subscriptions (user_id, trial_started_at, trial_ends_at, '
        'updated_at) values (@id:uuid, @at:timestamptz, @ends:timestamptz, '
        '@at:timestamptz) on conflict (user_id) do update set '
        'trial_started_at = @at:timestamptz, trial_ends_at = @ends:timestamptz, '
        'updated_at = @at:timestamptz',
      ),
      parameters: {
        'id': user.id,
        'at': at,
        'ends': at.add(Duration(days: config.trialDays)),
      },
    );
    await _audit(tx, user.email, 'trial.started');
    return entitlementOf(user.id, tx);
  });

  /// Issues a code for [plan] and [months]. With [email], only the account
  /// with that email can redeem it.
  Future<IssuedCode> issueCode({
    required Plan plan,
    required int months,
    int seats = 1,
    String? email,
    String note = '',
    required String createdBy,
  }) async {
    if (plan == Plan.free) {
      throw ApiError.badRequest('Codes are for paid plans.');
    }
    if (months < 1 || months > 36) {
      throw ApiError.badRequest('Months must be 1 to 36.');
    }
    if (seats < 1 || seats > 1000) {
      throw ApiError.badRequest('Seats must be 1 to 1,000.');
    }
    final cleanEmail = (email ?? '').trim().toLowerCase();
    if (cleanEmail.isNotEmpty && !isEmail(cleanEmail)) {
      throw ApiError.badRequest('That email does not look right.');
    }
    final code = newActivationCode();
    final normalized = normalizeActivationCode(code)!;
    final redeemBy = now().add(Duration(days: config.codeValidDays));
    return pool.runTx((tx) async {
      final row = await _row(
        tx,
        'insert into license_codes (code_hash, hint, plan, months, seats, '
        'email, note, created_by, created_at, redeem_by) values (@hash:bytea, '
        '@hint, @plan, @months:int4, @seats:int4, @email, @note, @by, '
        '@at:timestamptz, @redeemBy:timestamptz) returning id',
        {
          'hash': hashSecret(normalized),
          'hint': normalized.substring(12),
          'plan': plan.name,
          'months': months,
          'seats': plan == Plan.enterprise ? seats : 1,
          'email': cleanEmail.isEmpty ? null : cleanEmail,
          'note': note.trim(),
          'by': createdBy,
          'at': now(),
          'redeemBy': redeemBy,
        },
      );
      final id = row!['id'] as String;
      await _audit(
        tx,
        createdBy,
        'code.issued',
        target: id,
        details: {
          'plan': plan.name,
          'months': months,
          'seats': seats,
          'email': cleanEmail,
        },
      );
      return (
        id: id,
        code: code,
        plan: plan,
        months: months,
        seats: plan == Plan.enterprise ? seats : 1,
        email: cleanEmail.isEmpty ? null : cleanEmail,
        redeemBy: redeemBy,
      );
    });
  }

  /// Applies a code to [user]'s account: Business time to the account, or
  /// Enterprise time and seats to the company the account owns, which is
  /// created on the first Enterprise code. A code works once.
  Future<Entitlement> redeemCode(User user, String code) async {
    final normalized = normalizeActivationCode(code);
    if (normalized == null) {
      throw ApiError(
        400,
        'code_invalid',
        'That is not a code. Codes look like BQ-XXXX-XXXX-XXXX-XXXX.',
      );
    }
    return pool.runTx((tx) async {
      final at = now();
      final c = await _row(
        tx,
        'select id, plan, months, seats, email, note, redeem_by, redeemed_at, '
        'revoked_at from license_codes where code_hash = @hash:bytea for update',
        {'hash': hashSecret(normalized)},
      );
      if (c == null) {
        throw ApiError(
          404,
          'code_not_found',
          'That code is not valid. Check it against the email we sent.',
        );
      }
      if (c['revoked_at'] != null) {
        throw ApiError(410, 'code_revoked', 'That code has been cancelled.');
      }
      if (c['redeemed_at'] != null) {
        throw ApiError(409, 'code_used', 'That code has already been used.');
      }
      if (!at.isBefore(c['redeem_by'] as DateTime)) {
        throw ApiError(
          410,
          'code_expired',
          'That code has expired. Ask us for a new one.',
        );
      }
      final forEmail = c['email'] as String?;
      if (forEmail != null && forEmail != user.email.toLowerCase()) {
        throw ApiError(
          403,
          'code_other_account',
          'That code is for ${maskEmail(forEmail)}. Sign in with that Google '
              'account to use it.',
        );
      }
      final months = c['months'] as int;
      final plan = c['plan'] as String;
      if (plan == 'business') {
        await tx.execute(
          Sql.named(
            'insert into subscriptions (user_id, paid_until, updated_at) '
            'values (@id:uuid, @at:timestamptz + make_interval(months => @m:int4), '
            '@at:timestamptz) on conflict (user_id) do update set '
            'paid_until = greatest(@at:timestamptz, '
            'coalesce(subscriptions.paid_until, @at:timestamptz)) '
            '+ make_interval(months => @m:int4), updated_at = @at:timestamptz',
          ),
          parameters: {'id': user.id, 'at': at, 'm': months},
        );
      } else {
        final owned = await _row(
          tx,
          'select o.id from organizations o join memberships m '
          "on m.org_id = o.id and m.user_id = @id:uuid and m.role = 'owner' "
          'order by o.created_at limit 1',
          {'id': user.id},
        );
        if (owned == null) {
          final note = (c['note'] as String).trim();
          final org = await _row(
            tx,
            'insert into organizations (name, seats, paid_until, created_at) '
            'values (@name, @seats:int4, @at:timestamptz + '
            'make_interval(months => @m:int4), @at:timestamptz) returning id',
            {
              'name': note.isNotEmpty
                  ? note
                  : '${user.name.isEmpty ? user.email : user.name}\'s company',
              'seats': c['seats'],
              'at': at,
              'm': months,
            },
          );
          await tx.execute(
            Sql.named(
              'insert into memberships (org_id, user_id, role, created_at) '
              "values (@org:uuid, @user:uuid, 'owner', @at:timestamptz)",
            ),
            parameters: {'org': org!['id'], 'user': user.id, 'at': at},
          );
        } else {
          await tx.execute(
            Sql.named(
              'update organizations set paid_until = greatest(@at:timestamptz, '
              'coalesce(paid_until, @at:timestamptz)) + '
              'make_interval(months => @m:int4), seats = greatest(seats, '
              '@seats:int4) where id = @org:uuid',
            ),
            parameters: {
              'org': owned['id'],
              'at': at,
              'm': months,
              'seats': c['seats'],
            },
          );
        }
      }
      await tx.execute(
        Sql.named(
          'update license_codes set redeemed_by = @user:uuid, '
          'redeemed_at = @at:timestamptz where id = @id:uuid',
        ),
        parameters: {'user': user.id, 'at': at, 'id': c['id']},
      );
      await _audit(tx, user.email, 'code.redeemed', target: c['id'] as String);
      return entitlementOf(user.id, tx);
    });
  }

  Future<List<Map<String, Object?>>> listCodes({String status = 'all'}) async {
    final where = switch (status) {
      'open' =>
        'where redeemed_at is null and revoked_at is null '
            'and redeem_by > @at:timestamptz',
      'redeemed' => 'where redeemed_at is not null',
      'revoked' => 'where revoked_at is not null',
      _ => '',
    };
    return [
      for (final r in await _rows(
        pool,
        'select c.id, c.hint, c.plan, c.months, c.seats, c.email, c.note, '
        'c.created_by, c.created_at, c.redeem_by, c.redeemed_at, c.revoked_at, '
        'u.email as redeemed_by from license_codes c left join users u '
        'on u.id = c.redeemed_by $where order by c.created_at desc limit 500',
        {if (where.contains('@at')) 'at': now()},
      ))
        {
          'id': r['id'],
          'hint': '…${r['hint']}',
          'plan': r['plan'],
          'months': r['months'],
          'seats': r['seats'],
          'email': r['email'],
          'note': r['note'],
          'createdBy': r['created_by'],
          'createdAt': _iso(r['created_at'] as DateTime?),
          'redeemBy': _iso(r['redeem_by'] as DateTime?),
          'redeemedAt': r['redeemed_at'] == null
              ? null
              : _iso(r['redeemed_at'] as DateTime?),
          'redeemedBy': r['redeemed_by'],
          'revokedAt': r['revoked_at'] == null
              ? null
              : _iso(r['revoked_at'] as DateTime?),
        },
    ];
  }

  /// Cancels a code that has not been used.
  Future<void> revokeCode(String id, String actor) => pool.runTx((tx) async {
    final row = await _row(
      tx,
      'update license_codes set revoked_at = @at:timestamptz '
      'where id = @id:uuid and redeemed_at is null and revoked_at is null '
      'returning id',
      {'id': id, 'at': now()},
    );
    if (row == null) {
      throw ApiError.notFound('No unused code with that id.');
    }
    await _audit(tx, actor, 'code.revoked', target: id);
  });

  /// Adds (or with negative [months], removes) Business time to an
  /// account by hand, e.g. after a refund or as a goodwill gesture.
  Future<Entitlement> extendBusiness(
    User user,
    int months,
    String actor,
  ) => pool.runTx((tx) async {
    if (months == 0 || months.abs() > 36) {
      throw ApiError.badRequest('Months must be 1 to 36, or −1 to −36.');
    }
    final at = now();
    await tx.execute(
      Sql.named(
        'insert into subscriptions (user_id, paid_until, updated_at) '
        'values (@id:uuid, @at:timestamptz + make_interval(months => @m:int4), '
        '@at:timestamptz) on conflict (user_id) do update set '
        'paid_until = greatest(@at:timestamptz, '
        'coalesce(subscriptions.paid_until, @at:timestamptz)) '
        '+ make_interval(months => @m:int4), updated_at = @at:timestamptz',
      ),
      parameters: {'id': user.id, 'at': at, 'm': months},
    );
    await _audit(
      tx,
      actor,
      'plan.extended',
      target: user.email,
      details: {'months': months},
    );
    return entitlementOf(user.id, tx);
  });

  // Projects

  bool _isViewer(OrgAccess? org) => org != null && !org.role.edits;

  /// Projects [user] can open: their own, then their companies'.
  Future<List<ProjectSummary>> listProjects(User user) async {
    final entitlement = await entitlementOf(user.id);
    final editable = await _editableOwn(pool, user, entitlement);
    final orgs = {for (final o in await organizationsOf(user.id)) o.id: o};
    return [
      for (final r in await _rows(
        pool,
        'select p.id, p.name, p.version, p.updated_at, p.org_id, u.email '
        'from projects p join users u on u.id = p.owner_id '
        'where p.deleted_at is null and ((p.owner_id = @id:uuid and '
        'p.org_id is null) or p.org_id in (select org_id from memberships '
        'where user_id = @id:uuid)) order by p.updated_at desc',
        {'id': user.id},
      ))
        (
          id: r['id'] as String,
          name: r['name'] as String,
          version: r['version'] as int,
          updatedAt: r['updated_at'] as DateTime,
          orgId: r['org_id'] as String?,
          ownerEmail: r['email'] as String,
          readOnly: r['org_id'] == null
              ? !editable.contains(r['id'])
              : _isViewer(orgs[r['org_id']]),
        ),
    ];
  }

  /// The ids of [user]'s own projects they may change: all of them on a
  /// paid plan, the oldest few up to the free limit otherwise.
  Future<Set<String>> _editableOwn(
    Session s,
    User user,
    Entitlement entitlement,
  ) async {
    final limit = entitlement.projectLimit;
    final rows = await _rows(
      s,
      'select id from projects where owner_id = @id:uuid and org_id is null '
      'and deleted_at is null order by created_at, id'
      '${limit == null ? '' : ' limit @limit:int4'}',
      {'id': user.id, if (limit != null) 'limit': limit},
    );
    return {for (final r in rows) r['id'] as String};
  }

  /// A project with its data, if [user] may open it.
  Future<Map<String, Object?>> getProject(User user, String id) async {
    final r = await _row(
      pool,
      'select id, owner_id, org_id, data, version, updated_at from projects '
      'where id = @id and deleted_at is null',
      {'id': id},
    );
    if (r == null || !await _canRead(pool, user, r)) {
      throw ApiError.notFound('No such project.');
    }
    return {
      'id': r['id'],
      'orgId': r['org_id'],
      'version': r['version'],
      'updatedAt': _iso(r['updated_at'] as DateTime?),
      'data': r['data'],
    };
  }

  Future<OrgAccess?> _membership(
    Session s,
    String userId,
    String? orgId,
  ) async {
    if (orgId == null) return null;
    for (final o in await organizationsOf(userId, s)) {
      if (o.id == orgId) return o;
    }
    return null;
  }

  Future<bool> _canRead(
    Session s,
    User user,
    Map<String, dynamic> project,
  ) async =>
      project['owner_id'] == user.id && project['org_id'] == null ||
      await _membership(s, user.id, project['org_id'] as String?) != null;

  /// Saves a project. [baseVersion] is the version the app last loaded;
  /// when someone saved since, nothing is saved and a conflict is
  /// reported, so neither edit is lost. New projects count against the
  /// free plan's limit; [orgId] files a new project with a company.
  Future<({int version, DateTime updatedAt})> saveProject(
    User user,
    String id,
    Map<String, Object?> data, {
    int? baseVersion,
    String? orgId,
  }) {
    if (id.isEmpty || id.length > 100) {
      throw ApiError.badRequest('The project id must be 1 to 100 characters.');
    }
    final name = data['name'] is String ? data['name'] as String : '';
    return pool.runTx((tx) async {
      final at = now();
      final existing = await _row(
        tx,
        'select owner_id, org_id, version, deleted_at from projects '
        'where id = @id for update',
        {'id': id},
      );
      if (existing == null || existing['deleted_at'] != null) {
        if (existing != null && existing['owner_id'] != user.id) {
          throw ApiError(409, 'id_taken', 'That project id is in use.');
        }
        if (orgId != null) {
          final org = await _membership(tx, user.id, orgId);
          if (org == null || !org.role.edits) {
            throw ApiError.forbidden(
              'You cannot add projects to that company.',
            );
          }
        } else {
          final entitlement = await entitlementOf(user.id, tx);
          final limit = entitlement.projectLimit;
          if (limit != null) {
            final count = await _row(
              tx,
              'select count(*)::int as n from projects where owner_id = '
              '@id:uuid and org_id is null and deleted_at is null',
              {'id': user.id},
            );
            if ((count!['n'] as int) >= limit) {
              throw ApiError(
                402,
                'plan_limit',
                'The free plan keeps $limit projects in the cloud. Upgrade '
                    'to Business for unlimited projects.',
                {'limit': limit},
              );
            }
          }
        }
        await tx.execute(
          Sql.named(
            'insert into projects (id, owner_id, org_id, name, data, version, '
            'created_at, updated_at, updated_by) values (@id, @owner:uuid, '
            '@org:uuid, @name, @data:jsonb, 1, @at:timestamptz, '
            '@at:timestamptz, @owner:uuid) on conflict (id) do update set '
            'org_id = @org:uuid, name = @name, data = @data:jsonb, version = 1, '
            'created_at = @at:timestamptz, updated_at = @at:timestamptz, '
            'updated_by = @owner:uuid, deleted_at = null',
          ),
          parameters: {
            'id': id,
            'owner': user.id,
            'org': orgId,
            'name': name,
            'data': data,
            'at': at,
          },
        );
        return (version: 1, updatedAt: at);
      }
      final projectOrg = existing['org_id'] as String?;
      if (projectOrg == null) {
        if (existing['owner_id'] != user.id) {
          throw ApiError.notFound('No such project.');
        }
        final entitlement = await entitlementOf(user.id, tx);
        if (!(await _editableOwn(tx, user, entitlement)).contains(id)) {
          throw ApiError(
            402,
            'plan_limit',
            'On the free plan this project is read-only. Upgrade to Business '
                'to change it, or delete a newer project.',
            {'limit': entitlement.projectLimit},
          );
        }
      } else {
        final org = await _membership(tx, user.id, projectOrg);
        if (org == null) throw ApiError.notFound('No such project.');
        if (!org.role.edits) {
          throw ApiError.forbidden('Viewers cannot change projects.');
        }
      }
      final version = existing['version'] as int;
      if (baseVersion != null && baseVersion != version) {
        throw ApiError(
          409,
          'conflict',
          'This project was changed on another device. Load the latest '
              'version first.',
          {'version': version},
        );
      }
      await tx.execute(
        Sql.named(
          'update projects set name = @name, data = @data:jsonb, '
          'version = version + 1, updated_at = @at:timestamptz, '
          'updated_by = @user:uuid where id = @id',
        ),
        parameters: {
          'id': id,
          'name': name,
          'data': data,
          'at': at,
          'user': user.id,
        },
      );
      return (version: version + 1, updatedAt: at);
    });
  }

  Future<void> deleteProject(User user, String id) => pool.runTx((tx) async {
    final r = await _row(
      tx,
      'select owner_id, org_id from projects where id = @id and '
      'deleted_at is null',
      {'id': id},
    );
    if (r == null || !await _canRead(tx, user, r)) {
      throw ApiError.notFound('No such project.');
    }
    if (r['org_id'] != null && r['owner_id'] != user.id) {
      final org = await _membership(tx, user.id, r['org_id'] as String);
      if (org == null || !org.role.manages) {
        throw ApiError.forbidden(
          'Only the project\'s owner or a company admin can delete it.',
        );
      }
    }
    await tx.execute(
      Sql.named(
        'update projects set deleted_at = @at:timestamptz where id = @id',
      ),
      parameters: {'id': id, 'at': now()},
    );
  });

  // Documents

  Future<Map<String, Object?>?> getDocument(String scope, String key) async {
    final r = await _row(
      pool,
      'select data, updated_at from documents where scope = @scope and key = @key',
      {'scope': scope, 'key': key},
    );
    return r == null
        ? null
        : {'data': r['data'], 'updatedAt': _iso(r['updated_at'] as DateTime?)};
  }

  Future<DateTime> putDocument(
    String scope,
    String key,
    Object? data,
    String userId,
  ) async {
    if (!RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(key)) {
      throw ApiError.badRequest('Document names are lower-case words.');
    }
    final at = now();
    await pool.execute(
      Sql.named(
        'insert into documents (scope, key, data, updated_at, updated_by) '
        'values (@scope, @key, @data:jsonb, @at:timestamptz, @user:uuid) '
        'on conflict (scope, key) do update set data = @data:jsonb, '
        'updated_at = @at:timestamptz, updated_by = @user:uuid',
      ),
      parameters: {
        'scope': scope,
        'key': key,
        'data': data,
        'at': at,
        'user': userId,
      },
    );
    return at;
  }

  // Companies

  /// [user]'s membership of [orgId], or an error when they have none.
  Future<OrgAccess> requireMember(User user, String orgId) async {
    final org = await _membership(pool, user.id, orgId);
    if (org == null) throw ApiError.notFound('No such company.');
    return org;
  }

  Future<OrgAccess> requireManager(User user, String orgId) async {
    final org = await requireMember(user, orgId);
    if (!org.role.manages) {
      throw ApiError.forbidden('Only owners and admins can do that.');
    }
    return org;
  }

  Future<Map<String, Object?>> organization(User user, String orgId) async {
    final org = await requireMember(user, orgId);
    final members = await _rows(
      pool,
      'select u.id, u.email, u.name, m.role, m.created_at from memberships m '
      'join users u on u.id = m.user_id where m.org_id = @org:uuid '
      'order by m.created_at',
      {'org': orgId},
    );
    final invites = await _rows(
      pool,
      'select email, role, created_at from invitations where org_id = @org:uuid '
      'order by created_at',
      {'org': orgId},
    );
    return {
      'id': org.id,
      'name': org.name,
      'seats': org.seats,
      'paidUntil': _iso(org.paidUntil),
      'role': org.role.name,
      'members': [
        for (final m in members)
          {
            'userId': m['id'],
            'email': m['email'],
            'name': m['name'],
            'role': m['role'],
          },
      ],
      'invitations': [
        for (final i in invites) {'email': i['email'], 'role': i['role']},
      ],
    };
  }

  Future<void> renameOrganization(User user, String orgId, String name) async {
    await requireManager(user, orgId);
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 120) {
      throw ApiError.badRequest('The name must be 1 to 120 characters.');
    }
    await pool.execute(
      Sql.named('update organizations set name = @name where id = @org:uuid'),
      parameters: {'org': orgId, 'name': clean},
    );
  }

  /// Adds [email] to the company: as a member when they have an account,
  /// otherwise as an invitation they take up when they first sign in.
  /// Returns true for an invitation.
  Future<bool> addMember(
    User user,
    String orgId,
    String email,
    Role role,
  ) => pool.runTx((tx) async {
    final org = await _membership(tx, user.id, orgId);
    if (org == null) throw ApiError.notFound('No such company.');
    if (!org.role.manages) {
      throw ApiError.forbidden('Only owners and admins can add people.');
    }
    if (role == Role.owner && org.role != Role.owner) {
      throw ApiError.forbidden('Only owners can add owners.');
    }
    final clean = email.trim().toLowerCase();
    if (!isEmail(clean)) {
      throw ApiError.badRequest('That email does not look right.');
    }
    final used = await _row(
      tx,
      'select (select count(*) from memberships where org_id = @org:uuid) + '
      '(select count(*) from invitations where org_id = @org:uuid) as n',
      {'org': orgId},
    );
    if ((used!['n'] as int) >= org.seats) {
      throw ApiError(
        402,
        'seats_full',
        'All ${org.seats} seats are taken. Ask us for more seats.',
        {'seats': org.seats},
      );
    }
    final existing = await _row(
      tx,
      'select id from users where lower(email) = @email',
      {'email': clean},
    );
    final at = now();
    if (existing == null) {
      if (role == Role.owner) {
        throw ApiError.badRequest(
          'Owners need an account first: ask them to sign in once.',
        );
      }
      await tx.execute(
        Sql.named(
          'insert into invitations (org_id, email, role, invited_by, created_at) '
          'values (@org:uuid, @email, @role, @by:uuid, @at:timestamptz) '
          'on conflict (org_id, email) do update set role = @role',
        ),
        parameters: {
          'org': orgId,
          'email': clean,
          'role': role.name,
          'by': user.id,
          'at': at,
        },
      );
    } else {
      final added = await _row(
        tx,
        'insert into memberships (org_id, user_id, role, created_at) values '
        '(@org:uuid, @user:uuid, @role, @at:timestamptz) on conflict do nothing '
        'returning user_id',
        {'org': orgId, 'user': existing['id'], 'role': role.name, 'at': at},
      );
      if (added == null) {
        throw ApiError(409, 'already_member', '$clean is already a member.');
      }
    }
    await _audit(
      tx,
      user.email,
      existing == null ? 'org.invited' : 'org.member_added',
      target: orgId,
      details: {'email': clean, 'role': role.name},
    );
    return existing == null;
  });

  Future<void> setRole(User user, String orgId, String memberId, Role role) =>
      pool.runTx((tx) async {
        final org = await _membership(tx, user.id, orgId);
        if (org == null) throw ApiError.notFound('No such company.');
        if (!org.role.manages) throw ApiError.forbidden();
        final current = await _row(
          tx,
          'select role from memberships where org_id = @org:uuid and '
          'user_id = @user:uuid for update',
          {'org': orgId, 'user': memberId},
        );
        if (current == null) throw ApiError.notFound('No such member.');
        final wasOwner = current['role'] == 'owner';
        if ((wasOwner || role == Role.owner) && org.role != Role.owner) {
          throw ApiError.forbidden('Only owners can change owners.');
        }
        if (wasOwner && role != Role.owner) {
          await _keepAnOwner(tx, orgId, memberId);
        }
        await tx.execute(
          Sql.named(
            'update memberships set role = @role where org_id = @org:uuid and '
            'user_id = @user:uuid',
          ),
          parameters: {'org': orgId, 'user': memberId, 'role': role.name},
        );
        await _audit(
          tx,
          user.email,
          'org.role_changed',
          target: orgId,
          details: {'member': memberId, 'role': role.name},
        );
      });

  Future<void> _keepAnOwner(Session tx, String orgId, String leaving) async {
    final others = await _row(
      tx,
      'select count(*)::int as n from memberships where org_id = @org:uuid '
      "and role = 'owner' and user_id <> @user:uuid",
      {'org': orgId, 'user': leaving},
    );
    if ((others!['n'] as int) == 0) {
      throw ApiError(
        409,
        'last_owner',
        'A company needs an owner. Make someone else an owner first.',
      );
    }
  }

  /// Removes a member; anyone may remove themselves.
  Future<void> removeMember(User user, String orgId, String memberId) =>
      pool.runTx((tx) async {
        final org = await _membership(tx, user.id, orgId);
        if (org == null) throw ApiError.notFound('No such company.');
        if (memberId != user.id && !org.role.manages) {
          throw ApiError.forbidden();
        }
        final current = await _row(
          tx,
          'select role from memberships where org_id = @org:uuid and '
          'user_id = @user:uuid for update',
          {'org': orgId, 'user': memberId},
        );
        if (current == null) throw ApiError.notFound('No such member.');
        if (current['role'] == 'owner') {
          if (memberId != user.id && org.role != Role.owner) {
            throw ApiError.forbidden('Only owners can remove owners.');
          }
          await _keepAnOwner(tx, orgId, memberId);
        }
        await tx.execute(
          Sql.named(
            'delete from memberships where org_id = @org:uuid and '
            'user_id = @user:uuid',
          ),
          parameters: {'org': orgId, 'user': memberId},
        );
        await _audit(
          tx,
          user.email,
          'org.member_removed',
          target: orgId,
          details: {'member': memberId},
        );
      });

  Future<void> removeInvitation(User user, String orgId, String email) async {
    await requireManager(user, orgId);
    await pool.execute(
      Sql.named(
        'delete from invitations where org_id = @org:uuid and email = lower(@email)',
      ),
      parameters: {'org': orgId, 'email': email},
    );
  }

  /// Sets a company's seats and paid time by hand (admins).
  Future<void> updateOrganization(
    String orgId, {
    int? seats,
    int? addMonths,
    required String actor,
  }) => pool.runTx((tx) async {
    final at = now();
    final row = await _row(
      tx,
      'update organizations set seats = coalesce(@seats:int4, seats), '
      'paid_until = case when @m:int4 is null then paid_until else '
      'greatest(@at:timestamptz, coalesce(paid_until, @at:timestamptz)) + '
      'make_interval(months => @m:int4) end where id = @org:uuid returning id',
      {'org': orgId, 'seats': seats, 'm': addMonths, 'at': at},
    );
    if (row == null) throw ApiError.notFound('No such company.');
    await _audit(
      tx,
      actor,
      'org.updated',
      target: orgId,
      details: {'seats': seats, 'months': addMonths},
    );
  });

  // Inquiries

  Future<String> addInquiry({
    required String name,
    required String email,
    String company = '',
    String phone = '',
    int? seats,
    String message = '',
  }) async {
    String clip(String s, int n) =>
        s.trim().length > n ? s.trim().substring(0, n) : s.trim();
    if (name.trim().isEmpty) throw ApiError.badRequest('Tell us your name.');
    if (!isEmail(email.trim())) {
      throw ApiError.badRequest('That email does not look right.');
    }
    final row = await _row(
      pool,
      'insert into inquiries (name, email, company, phone, seats, message, '
      'created_at) values (@name, @email, @company, @phone, @seats:int4, '
      '@message, @at:timestamptz) returning id',
      {
        'name': clip(name, 120),
        'email': clip(email, 200),
        'company': clip(company, 200),
        'phone': clip(phone, 50),
        'seats': seats,
        'message': clip(message, 4000),
        'at': now(),
      },
    );
    return row!['id'] as String;
  }

  Future<List<Map<String, Object?>>> listInquiries({bool open = true}) async =>
      [
        for (final r in await _rows(
          pool,
          'select id, name, email, company, phone, seats, message, created_at, '
          'handled_at from inquiries ${open ? 'where handled_at is null' : ''} '
          'order by created_at desc limit 500',
        ))
          {
            'id': r['id'],
            'name': r['name'],
            'email': r['email'],
            'company': r['company'],
            'phone': r['phone'],
            'seats': r['seats'],
            'message': r['message'],
            'createdAt': _iso(r['created_at'] as DateTime?),
            'handledAt': r['handled_at'] == null
                ? null
                : _iso(r['handled_at'] as DateTime?),
          },
      ];

  Future<void> markInquiryHandled(String id) async {
    final r = await pool.execute(
      Sql.named(
        'update inquiries set handled_at = @at:timestamptz where id = @id:uuid',
      ),
      parameters: {'id': id, 'at': now()},
    );
    if (r.affectedRows == 0) throw ApiError.notFound('No such inquiry.');
  }

  // Admin

  Future<List<Map<String, Object?>>> listUsers({String query = ''}) async {
    final rows = await _rows(
      pool,
      'select u.id, u.email, u.name, u.created_at, u.last_seen_at, '
      's.trial_ends_at, s.paid_until from users u left join subscriptions s '
      'on s.user_id = u.id where @q = \'\' or u.email ilike @like or '
      'u.name ilike @like order by u.created_at desc limit 200',
      {'q': query.trim(), 'like': '%${query.trim()}%'},
    );
    return [
      for (final r in rows)
        {
          'id': r['id'],
          'email': r['email'],
          'name': r['name'],
          'createdAt': _iso(r['created_at'] as DateTime?),
          'lastSeenAt': _iso(r['last_seen_at'] as DateTime?),
          'plan': (await entitlementOf(r['id'] as String)).toJson(),
        },
    ];
  }

  Future<Map<String, Object?>> stats() async {
    final at = now();
    final r = (await _row(
      pool,
      'select '
      '(select count(*)::int from users) as users, '
      '(select count(*)::int from users where last_seen_at > '
      "@at:timestamptz - interval '30 days') as active_30d, "
      '(select count(*)::int from subscriptions where trial_ends_at > '
      '@at:timestamptz and (paid_until is null or paid_until < @at:timestamptz)) '
      'as trials, '
      '(select count(*)::int from subscriptions where paid_until > '
      '@at:timestamptz) as business, '
      '(select count(*)::int from organizations where paid_until > '
      '@at:timestamptz) as enterprise, '
      '(select coalesce(sum(seats), 0)::int from organizations where '
      'paid_until > @at:timestamptz) as enterprise_seats, '
      '(select count(*)::int from license_codes where redeemed_at is null and '
      'revoked_at is null and redeem_by > @at:timestamptz) as open_codes, '
      '(select count(*)::int from inquiries where handled_at is null) '
      'as open_inquiries, '
      '(select count(*)::int from projects where deleted_at is null) as projects',
      {'at': at},
    ))!;
    return {
      'users': r['users'],
      'activeLast30Days': r['active_30d'],
      'trials': r['trials'],
      'businessSubscriptions': r['business'],
      'enterpriseCompanies': r['enterprise'],
      'enterpriseSeats': r['enterprise_seats'],
      'openCodes': r['open_codes'],
      'openInquiries': r['open_inquiries'],
      'projects': r['projects'],
    };
  }

  Future<List<Map<String, Object?>>> auditLog({int limit = 200}) async => [
    for (final r in await _rows(
      pool,
      'select at, actor, action, target, details from audit_log '
      'order by at desc, id desc limit @n:int4',
      {'n': limit},
    ))
      {
        'at': _iso(r['at'] as DateTime?),
        'actor': r['actor'],
        'action': r['action'],
        'target': r['target'],
        'details': r['details'],
      },
  ];
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isEmail(String s) => s.length <= 200 && _emailPattern.hasMatch(s);

/// `ana@example.com` as `a**@example.com`, to say which account a code is
/// for without giving the address away.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return email;
  return '${email[0]}${'*' * (at - 1).clamp(2, 6)}${email.substring(at)}';
}
