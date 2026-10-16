import 'package:postgres/postgres.dart';

import 'config.dart';

/// Opens a pool of connections to the database in [settings].
Pool<void> openPool(DatabaseSettings settings, {int maxConnections = 10}) =>
    Pool.withEndpoints(
      [
        Endpoint(
          host: settings.host,
          port: settings.port,
          database: settings.database,
          username: settings.username,
          password: settings.password,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: maxConnections,
        sslMode: settings.ssl ? SslMode.require : SslMode.disable,
      ),
    );

/// Brings the database's tables up to date, applying each migration not
/// yet applied, in order, each in its own transaction. Safe to run on
/// every start; an advisory lock keeps two servers from running it at
/// once.
Future<List<int>> migrate(Pool<void> pool) => pool.runTx((tx) async {
  await tx.execute('select pg_advisory_xact_lock(4207031)');
  await tx.execute(
    'create table if not exists schema_migrations ('
    'version int primary key, '
    'applied_at timestamptz not null default now())',
  );
  final done = {
    for (final row in await tx.execute('select version from schema_migrations'))
      row[0] as int,
  };
  final applied = <int>[];
  for (final (version, sql) in migrations) {
    if (done.contains(version)) continue;
    await tx.execute(sql, queryMode: QueryMode.simple);
    await tx.execute(
      Sql.named('insert into schema_migrations (version) values (@v)'),
      parameters: {'v': version},
    );
    applied.add(version);
  }
  return applied;
});

/// The database schema, one migration per change. Never edit a migration
/// that has run on the server; add a new one.
const migrations = <(int, String)>[
  (
    1,
    r'''
create table users (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text not null default '',
  google_sub text unique,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create unique index users_email on users (lower(email));

create table sessions (
  token_hash bytea primary key,
  user_id uuid not null references users on delete cascade,
  created_at timestamptz not null default now(),
  last_used_at timestamptz not null default now(),
  expires_at timestamptz not null,
  user_agent text not null default ''
);
create index sessions_user on sessions (user_id);

-- An account's own plan: its trial and the Business time it has paid for.
create table subscriptions (
  user_id uuid primary key references users on delete cascade,
  trial_started_at timestamptz,
  trial_ends_at timestamptz,
  paid_until timestamptz,
  updated_at timestamptz not null default now()
);

-- A company on the Enterprise plan.
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  seats int not null default 5 check (seats > 0),
  paid_until timestamptz,
  created_at timestamptz not null default now()
);

create table memberships (
  org_id uuid not null references organizations on delete cascade,
  user_id uuid not null references users on delete cascade,
  role text not null check (role in ('owner', 'admin', 'estimator', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (org_id, user_id)
);
create index memberships_user on memberships (user_id);

-- People invited before they have an account; they join when they first
-- sign in. Emails are stored in lower case.
create table invitations (
  org_id uuid not null references organizations on delete cascade,
  email text not null,
  role text not null check (role in ('admin', 'estimator', 'viewer')),
  invited_by uuid references users on delete set null,
  created_at timestamptz not null default now(),
  primary key (org_id, email)
);

-- Activation codes emailed to customers. Only a hash of each code is
-- kept; the code itself is shown once, when it is issued.
create table license_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash bytea not null unique,
  hint text not null,
  plan text not null check (plan in ('business', 'enterprise')),
  months int not null check (months between 1 and 36),
  seats int not null default 1 check (seats between 1 and 1000),
  email text,
  note text not null default '',
  created_by text not null,
  created_at timestamptz not null default now(),
  redeem_by timestamptz not null,
  redeemed_by uuid references users on delete set null,
  redeemed_at timestamptz,
  revoked_at timestamptz
);

-- Projects saved to the cloud: the app's own project JSON, with a
-- version for catching edits made on two devices at once.
create table projects (
  id text primary key check (length(id) between 1 and 100),
  owner_id uuid not null references users on delete cascade,
  org_id uuid references organizations on delete set null,
  name text not null default '',
  data jsonb not null,
  version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references users on delete set null,
  deleted_at timestamptz
);
create index projects_owner on projects (owner_id) where deleted_at is null;
create index projects_org on projects (org_id) where deleted_at is null;

-- Small documents kept for an account or a company, such as the price
-- book. The scope is 'user:<id>' or 'org:<id>'.
create table documents (
  scope text not null,
  key text not null check (key ~ '^[a-z][a-z0-9_]{0,39}$'),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references users on delete set null,
  primary key (scope, key)
);

-- "Contact us" requests for the Enterprise plan.
create table inquiries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  company text not null default '',
  phone text not null default '',
  seats int,
  message text not null default '',
  created_at timestamptz not null default now(),
  handled_at timestamptz
);

-- Who changed what: codes issued and redeemed, members added, plans
-- extended.
create table audit_log (
  id bigserial primary key,
  at timestamptz not null default now(),
  actor text not null,
  action text not null,
  target text not null default '',
  details jsonb not null default '{}'
);
create index audit_log_at on audit_log (at desc);
''',
  ),
];
