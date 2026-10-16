import 'dart:convert';
import 'dart:io';

import 'package:buildquantify_server/buildquantify_server.dart';

const _usage = '''
BuildQuantify admin tool. Runs on the server against the same database.

  admin issue-code --plan business --months 1 [--email ana@example.com]
                   [--seats 5] [--note "Reyes Builders"] [--send]
      Issues an activation code and prints it. With --email, only that
      Google account can use it; with --send, it is emailed there too.
      Enterprise codes take --seats and create the customer's company.

  admin codes [open|redeemed|revoked|all]   Lists codes (not the codes
                                             themselves: only their ends).
  admin revoke-code <id>                     Cancels an unused code.
  admin users [search]                       Lists accounts and their plans.
  admin extend --email ana@example.com --months 1
                                             Adds Business time by hand
                                             (negative to take it back).
  admin org --id <id> [--seats 10] [--months 12]
                                             Changes a company's seats or
                                             adds paid months.
  admin inquiries [all]                      Lists Enterprise inquiries.
  admin handled <id>                         Marks an inquiry as handled.
  admin stats                                Counts of accounts and plans.
  admin audit                                The latest changes.
  admin migrate                              Brings the database up to date.

In Docker:  docker compose exec api admin issue-code --plan business --months 1
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    stdout.write(_usage);
    return;
  }
  final config = Config.fromEnvironment(Platform.environment);
  final pool = openPool(config.database, maxConnections: 2);
  final store = Store(pool, config);
  try {
    await migrate(pool);
    await _run(store, config, args.first, args.skip(1).toList());
  } on ApiError catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 2;
  } finally {
    await pool.close();
  }
}

Future<void> _run(
  Store store,
  Config config,
  String command,
  List<String> rest,
) async {
  final options = _options(rest);
  String? positional() =>
      rest.isEmpty || rest.first.startsWith('--') ? null : rest.first;
  int? number(String key) {
    final v = options[key];
    if (v == null) return null;
    return int.tryParse(v) ??
        (throw FormatException('--$key must be a number'));
  }

  switch (command) {
    case 'issue-code':
      final plan = Plan.values.asNameMap()[options['plan'] ?? 'business'];
      if (plan == null || plan == Plan.free) {
        throw const FormatException('--plan must be business or enterprise');
      }
      final issued = await store.issueCode(
        plan: plan,
        months: number('months') ?? 1,
        seats: number('seats') ?? 1,
        email: options['email'],
        note: options['note'] ?? '',
        createdBy: 'admin tool',
      );
      stdout
        ..writeln(issued.code)
        ..writeln(
          '${issued.plan.name}, ${issued.months} month(s)'
          '${issued.plan == Plan.enterprise ? ', ${issued.seats} seats' : ''}'
          '${issued.email == null ? '' : ', for ${issued.email}'}; '
          'use by ${issued.redeemBy.toIso8601String().substring(0, 10)}',
        );
      if (options.containsKey('send')) {
        if (issued.email == null) {
          throw const FormatException('--send needs --email');
        }
        final mailer = config.smtp == null
            ? LogMailer()
            : SmtpMailer(config.smtp!, config.mailFrom);
        final sent = await trySend(mailer, codeEmail(issued, config));
        stdout.writeln(sent ? 'Emailed to ${issued.email}' : 'Email failed');
      }
    case 'codes':
      _print(await store.listCodes(status: positional() ?? 'open'));
    case 'revoke-code':
      final id =
          positional() ?? (throw const FormatException('Which code id?'));
      await store.revokeCode(id, 'admin tool');
      stdout.writeln('Revoked');
    case 'users':
      _print(await store.listUsers(query: positional() ?? ''));
    case 'extend':
      final email =
          options['email'] ?? (throw const FormatException('--email'));
      final user = await store.userByEmail(email);
      if (user == null) {
        throw FormatException('$email has not signed in yet');
      }
      _print(
        (await store.extendBusiness(
          user,
          number('months') ?? 1,
          'admin tool',
        )).toJson(),
      );
    case 'org':
      await store.updateOrganization(
        options['id'] ?? (throw const FormatException('--id')),
        seats: number('seats'),
        addMonths: number('months'),
        actor: 'admin tool',
      );
      stdout.writeln('Updated');
    case 'inquiries':
      _print(await store.listInquiries(open: positional() != 'all'));
    case 'handled':
      await store.markInquiryHandled(
        positional() ?? (throw const FormatException('Which inquiry id?')),
      );
      stdout.writeln('Marked as handled');
    case 'stats':
      _print(await store.stats());
    case 'audit':
      _print(await store.auditLog(limit: 50));
    case 'migrate':
      stdout.writeln('Up to date');
    default:
      stdout.write(_usage);
      exitCode = 2;
  }
}

/// `--key value` pairs; a flag with no value is stored as empty.
Map<String, String> _options(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;
    final key = a.substring(2);
    final next = i + 1 < args.length ? args[i + 1] : null;
    if (next != null && !next.startsWith('--')) {
      out[key] = next;
      i++;
    } else {
      out[key] = '';
    }
  }
  return out;
}

void _print(Object? value) =>
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(value));
