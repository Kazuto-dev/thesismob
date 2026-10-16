// End-to-end tests of the API against a real PostgreSQL database.
//
//   TEST_DATABASE_URL=postgres://bq:bq@localhost:5432/bq_test dart test
//
// The database is emptied before each test. Without TEST_DATABASE_URL the
// tests are skipped.
import 'dart:convert';
import 'dart:io';

import 'package:buildquantify_server/buildquantify_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const clientId = 'web-client.apps.googleusercontent.com';
const admin = 'owner@buildquantify.ph';

/// Signs in whoever the token names: `ana` is ana@example.com.
class FakeGoogle implements GoogleVerifier {
  @override
  Future<GoogleIdentity> verify({String? idToken, String? accessToken}) async {
    final token = idToken ?? accessToken ?? '';
    if (token == 'bad') throw GoogleAuthException('Google did not accept it');
    final [who, audience] = token.contains('|')
        ? token.split('|')
        : [token, clientId];
    final email = who.contains('@') ? who : '$who@example.com';
    return (
      subject: 'sub-$email',
      email: email,
      emailVerified: true,
      name: who[0].toUpperCase() + who.substring(1).split('@').first,
      audience: audience,
    );
  }
}

void main() {
  final url = Platform.environment['TEST_DATABASE_URL'];
  if (url == null) {
    test('API tests need TEST_DATABASE_URL', () {}, skip: 'no database');
    return;
  }

  late Pool<void> pool;
  late LogMailer mailer;
  late Handler handler;
  late DateTime now;

  Config config({List<String> clients = const [clientId]}) => Config(
    database: DatabaseSettings.parse(url),
    googleClientIds: clients,
    adminEmails: {admin},
    allowedOrigins: const ['https://app.buildquantify.ph'],
    salesEmail: 'sales@buildquantify.ph',
  );

  Handler build(Config c) => Api(
    store: Store(pool, c, clock: () => now),
    google: FakeGoogle(),
    mailer: mailer,
  ).handler;

  setUpAll(() async {
    pool = openPool(DatabaseSettings.parse(url), maxConnections: 4);
  });
  tearDownAll(() => pool.close());

  setUp(() async {
    await pool.execute('drop schema public cascade');
    await pool.execute('create schema public');
    await migrate(pool);
    mailer = LogMailer();
    now = DateTime.utc(2026, 10, 16, 9);
    handler = build(config());
  });

  Future<(int, Map<String, dynamic>)> call(
    String method,
    String path, {
    String? token,
    Object? body,
    Map<String, String> headers = const {},
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://api.test$path'),
        headers: {
          if (token != null) 'authorization': 'Bearer $token',
          if (body != null) 'content-type': 'application/json',
          ...headers,
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
    final text = await response.readAsString();
    return (
      response.statusCode,
      text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>,
    );
  }

  Future<String> signIn(String who) async {
    final (status, body) = await call(
      'POST',
      '/v1/auth/google',
      body: {'accessToken': who},
    );
    expect(status, 200, reason: '$body');
    return body['token'] as String;
  }

  Future<Map<String, dynamic>> plan(String token) async =>
      (await call('GET', '/v1/me', token: token)).$2['plan']
          as Map<String, dynamic>;

  Future<String> issue(
    String adminToken, {
    String plan = 'business',
    int months = 1,
    String? email,
    int seats = 1,
    String note = '',
    bool send = false,
  }) async {
    final (status, body) = await call(
      'POST',
      '/v1/admin/codes',
      token: adminToken,
      body: {
        'plan': plan,
        'months': months,
        'email': ?email,
        'seats': seats,
        'note': note,
        'send': send,
      },
    );
    expect(status, 201, reason: '$body');
    return body['code'] as String;
  }

  String errorCode(Map<String, dynamic> body) =>
      (body['error'] as Map)['code'] as String;

  test('health and plans need no account', () async {
    expect((await call('GET', '/health')).$2['ok'], isTrue);
    final (_, plans) = await call('GET', '/v1/plans');
    expect(plans['trialDays'], 14);
    expect(plans['freeProjects'], 2);
    final business = (plans['plans'] as List)[1] as Map;
    expect(business['priceUsd'], 20);
    expect(business['pricePhp'], 1150);
    expect((await call('GET', '/nowhere')).$1, 404);
  });

  test('Google sign-in creates an account on the free plan', () async {
    final (status, body) = await call(
      'POST',
      '/v1/auth/google',
      body: {'idToken': 'ana'},
    );
    expect(status, 200);
    expect(body['user']['email'], 'ana@example.com');
    expect(body['user']['isAdmin'], isFalse);
    expect(body['plan']['plan'], 'free');
    expect(body['plan']['trialAvailable'], isTrue);
    expect(body['plan']['projectLimit'], 2);

    // Tokens for another app, or refused by Google, are turned away.
    expect(
      (await call(
        'POST',
        '/v1/auth/google',
        body: {'idToken': 'ana|other'},
      )).$1,
      401,
    );
    expect(
      (await call('POST', '/v1/auth/google', body: {'idToken': 'bad'})).$1,
      401,
    );
    // Signing in again is the same account.
    final again = await signIn('ana');
    final (_, me) = await call('GET', '/v1/me', token: again);
    expect(me['user']['id'], body['user']['id']);
  });

  test('sign-in is off until a client id is set', () async {
    handler = build(config(clients: const []));
    final (status, body) = await call(
      'POST',
      '/v1/auth/google',
      body: {'idToken': 'ana'},
    );
    expect(status, 503);
    expect(errorCode(body), 'sign_in_off');
    expect((await call('GET', '/v1/plans')).$2['signInEnabled'], isFalse);
  });

  test('sessions end on sign-out and after 30 days unused', () async {
    final token = await signIn('ana');
    expect((await call('GET', '/v1/me')).$1, 401);
    expect((await call('GET', '/v1/me', token: 'nonsense')).$1, 401);
    await call('POST', '/v1/auth/logout', token: token);
    expect((await call('GET', '/v1/me', token: token)).$1, 401);

    final other = await signIn('ana');
    now = now.add(const Duration(days: 20));
    expect((await call('GET', '/v1/me', token: other)).$1, 200);
    // Using it extended it, so 20 more days are fine; 31 unused are not.
    now = now.add(const Duration(days: 20));
    expect((await call('GET', '/v1/me', token: other)).$1, 200);
    now = now.add(const Duration(days: 31));
    expect((await call('GET', '/v1/me', token: other)).$1, 401);
  });

  test('the 14-day trial runs once per account', () async {
    final token = await signIn('ana');
    final (status, body) = await call('POST', '/v1/trial', token: token);
    expect(status, 200);
    expect(body['plan']['plan'], 'business');
    expect(body['plan']['source'], 'trial');
    expect(body['plan']['trialEndsAt'], '2026-10-30T09:00:00.000Z');

    final (again, error) = await call('POST', '/v1/trial', token: token);
    expect(again, 409);
    expect(errorCode(error), 'already_subscribed');

    now = now.add(const Duration(days: 15));
    expect((await plan(token))['plan'], 'free');
    final (_, used) = await call('POST', '/v1/trial', token: token);
    expect(errorCode(used), 'trial_used');
  });

  test('a Business code adds paid months once, for its account', () async {
    final adminToken = await signIn(admin);
    final ana = await signIn('ana');
    final ben = await signIn('ben');

    // Only admins issue codes.
    expect(
      (await call(
        'POST',
        '/v1/admin/codes',
        token: ana,
        body: {'plan': 'business'},
      )).$1,
      403,
    );

    final code = await issue(
      adminToken,
      months: 1,
      email: 'ana@example.com',
      send: true,
    );
    expect(mailer.sent.single.to, 'ana@example.com');
    expect(mailer.sent.single.text, contains(code));

    final (wrong, wrongBody) = await call(
      'POST',
      '/v1/codes/redeem',
      token: ben,
      body: {'code': code},
    );
    expect(wrong, 403);
    expect(errorCode(wrongBody), 'code_other_account');
    expect((wrongBody['error'] as Map)['message'], contains('a**@example.com'));

    final (ok, me) = await call(
      'POST',
      '/v1/codes/redeem',
      token: ana,
      // As typed from the email, in lower case with spaces.
      body: {'code': code.toLowerCase().replaceAll('-', ' ')},
    );
    expect(ok, 200, reason: '$me');
    expect(me['plan']['plan'], 'business');
    expect(me['plan']['source'], 'paid');
    expect(me['plan']['paidUntil'], '2026-11-16T09:00:00.000Z');

    final (used, usedBody) = await call(
      'POST',
      '/v1/codes/redeem',
      token: ana,
      body: {'code': code},
    );
    expect(used, 409);
    expect(errorCode(usedBody), 'code_used');

    // A renewal adds to the time left.
    final renewal = await issue(adminToken, months: 12);
    await call('POST', '/v1/codes/redeem', token: ana, body: {'code': renewal});
    expect((await plan(ana))['paidUntil'], '2027-11-16T09:00:00.000Z');

    // Paid time keeps working for three days of grace, then lapses.
    now = DateTime.utc(2027, 11, 18);
    final later = await signIn('ana');
    expect((await plan(later))['inGrace'], isTrue);
    now = DateTime.utc(2027, 11, 20);
    expect((await plan(later))['plan'], 'free');
  });

  test('wrong, expired and cancelled codes are refused', () async {
    final adminToken = await signIn(admin);
    var ana = await signIn('ana');
    Future<String> redeem(String code) async => errorCode(
      (await call(
        'POST',
        '/v1/codes/redeem',
        token: ana,
        body: {'code': code},
      )).$2,
    );

    expect(await redeem('hello'), 'code_invalid');
    expect(await redeem('BQ-0000-0000-0000-0000'), 'code_not_found');

    final cancelled = await issue(adminToken);
    final (_, list) = await call(
      'GET',
      '/v1/admin/codes?status=open',
      token: adminToken,
    );
    final id = ((list['codes'] as List).single as Map)['id'] as String;
    expect(((list['codes'] as List).single as Map)['hint'], startsWith('…'));
    expect(
      (await call('POST', '/v1/admin/codes/$id/revoke', token: adminToken)).$1,
      200,
    );
    expect(await redeem(cancelled), 'code_revoked');

    final late = await issue(adminToken);
    now = now.add(const Duration(days: 31));
    ana = await signIn('ana');
    expect(await redeem(late), 'code_expired');
  });

  test('guessing codes is slowed down', () async {
    final ana = await signIn('ana');
    var last = 0;
    for (var i = 0; i < 11; i++) {
      last = (await call(
        'POST',
        '/v1/codes/redeem',
        token: ana,
        body: {'code': 'BQ-0000-0000-0000-000$i'.substring(0, 22)},
      )).$1;
    }
    expect(last, 429);
  });

  test('the free plan keeps two projects; more need Business', () async {
    var ana = await signIn('ana');
    Future<(int, Map<String, dynamic>)> save(
      String id, {
      int? base,
      String name = 'House',
    }) => call(
      'PUT',
      '/v1/projects/$id',
      token: ana,
      body: {
        'data': {'id': id, 'name': name, 'items': []},
        'baseVersion': ?base,
      },
    );

    expect((await save('p1')).$1, 200);
    now = now.add(const Duration(minutes: 1));
    expect((await save('p2')).$1, 200);
    final (limited, limitBody) = await save('p3');
    expect(limited, 402);
    expect(errorCode(limitBody), 'plan_limit');

    // Edits carry the version they started from; a stale one conflicts.
    final (ok, saved) = await save('p1', base: 1, name: 'Reyes house');
    expect(ok, 200);
    expect(saved['version'], 2);
    final (conflict, conflictBody) = await save('p1', base: 1);
    expect(conflict, 409);
    expect((conflictBody['error'] as Map)['version'], 2);

    final (_, loaded) = await call('GET', '/v1/projects/p1', token: ana);
    expect(loaded['data']['name'], 'Reyes house');
    expect(loaded['version'], 2);

    // On Business there is no limit.
    final adminToken = await signIn(admin);
    final code = await issue(adminToken);
    await call('POST', '/v1/codes/redeem', token: ana, body: {'code': code});
    now = now.add(const Duration(minutes: 1));
    expect((await save('p3')).$1, 200);

    // When Business lapses, the two oldest stay editable and the rest
    // become read-only, still there to open and export.
    now = now.add(const Duration(days: 40));
    ana = await signIn('ana');
    final (_, list) = await call('GET', '/v1/projects', token: ana);
    final readOnly = {
      for (final p in list['projects'] as List) (p as Map)['id']: p['readOnly'],
    };
    expect(readOnly, {'p1': false, 'p2': false, 'p3': true});
    expect((await save('p3', base: 1)).$1, 402);
    expect((await call('GET', '/v1/projects/p3', token: ana)).$1, 200);

    // Others cannot see them.
    final ben = await signIn('ben');
    expect((await call('GET', '/v1/projects/p1', token: ben)).$1, 404);
    expect(
      (await call(
        'PUT',
        '/v1/projects/p1',
        token: ben,
        body: {
          'data': {'name': 'x'},
        },
      )).$1,
      404,
    );

    expect((await call('DELETE', '/v1/projects/p2', token: ana)).$1, 200);
    final (_, after) = await call('GET', '/v1/projects', token: ana);
    expect(
      [for (final p in after['projects'] as List) (p as Map)['id']],
      ['p3', 'p1'],
    );
  });

  test('an account keeps its own documents, such as its price book', () async {
    final ana = await signIn('ana');
    expect((await call('GET', '/v1/documents/price_book', token: ana)).$1, 404);
    await call(
      'PUT',
      '/v1/documents/price_book',
      token: ana,
      body: {
        'data': {'cement_40kg': 245},
      },
    );
    final (_, doc) = await call('GET', '/v1/documents/price_book', token: ana);
    expect(doc['data'], {'cement_40kg': 245});
    expect(
      (await call(
        'PUT',
        '/v1/documents/Bad%20Name',
        token: ana,
        body: {'data': 1},
      )).$1,
      400,
    );
  });

  test('an Enterprise code sets up a company that shares projects', () async {
    final adminToken = await signIn(admin);
    final owner = await signIn('ana');
    final estimator = await signIn('ben');
    final code = await issue(
      adminToken,
      plan: 'enterprise',
      months: 12,
      seats: 3,
      note: 'Reyes Builders',
    );
    final (_, me) = await call(
      'POST',
      '/v1/codes/redeem',
      token: owner,
      body: {'code': code},
    );
    expect(me['plan']['plan'], 'enterprise');
    final org = (me['organizations'] as List).single as Map;
    expect(org['name'], 'Reyes Builders');
    expect(org['role'], 'owner');
    final id = org['id'] as String;

    // Add an existing account, and invite someone without one.
    var (status, body) = await call(
      'POST',
      '/v1/orgs/$id/members',
      token: owner,
      body: {'email': 'ben@example.com', 'role': 'estimator'},
    );
    expect(status, 200, reason: '$body');
    (status, body) = await call(
      'POST',
      '/v1/orgs/$id/members',
      token: owner,
      body: {'email': 'Cara@Example.com', 'role': 'viewer'},
    );
    expect(body['invitations'], [
      {'email': 'cara@example.com', 'role': 'viewer'},
    ]);
    expect(mailer.sent.map((m) => m.to), contains('Cara@Example.com'));
    // Three seats: the owner, Ben and Cara's invitation.
    (status, body) = await call(
      'POST',
      '/v1/orgs/$id/members',
      token: owner,
      body: {'email': 'dan@example.com'},
    );
    expect(status, 402);
    expect(errorCode(body), 'seats_full');

    // Members get Enterprise; Cara joins when she first signs in.
    expect((await plan(estimator))['plan'], 'enterprise');
    final viewer = await signIn('cara');
    expect((await plan(viewer))['organization']['role'], 'viewer');

    // An estimator files a project with the company; a viewer can open it
    // but not change it; members of other companies cannot see it.
    expect(
      (await call(
        'PUT',
        '/v1/projects/c1',
        token: estimator,
        body: {
          'data': {'name': 'Clinic'},
          'orgId': id,
        },
      )).$1,
      200,
    );
    expect((await call('GET', '/v1/projects/c1', token: viewer)).$1, 200);
    expect(
      (await call(
        'PUT',
        '/v1/projects/c1',
        token: viewer,
        body: {
          'data': {'name': 'x'},
          'baseVersion': 1,
        },
      )).$1,
      403,
    );
    final (_, listed) = await call('GET', '/v1/projects', token: viewer);
    expect((listed['projects'] as List).single['readOnly'], isTrue);

    // The company price book: managers write it, members read it.
    expect(
      (await call(
        'PUT',
        '/v1/orgs/$id/documents/price_book',
        token: estimator,
        body: {'data': {}},
      )).$1,
      403,
    );
    await call(
      'PUT',
      '/v1/orgs/$id/documents/price_book',
      token: owner,
      body: {
        'data': {'cement_40kg': 238},
      },
    );
    expect(
      (await call(
        'GET',
        '/v1/orgs/$id/documents/price_book',
        token: viewer,
      )).$2['data'],
      {'cement_40kg': 238},
    );

    // The last owner cannot leave or step down.
    final ownerId = me['user']['id'];
    final (leave, leaveBody) = await call(
      'DELETE',
      '/v1/orgs/$id/members/$ownerId',
      token: owner,
    );
    expect(leave, 409);
    expect(errorCode(leaveBody), 'last_owner');
    final benId =
        ((await call('GET', '/v1/me', token: estimator)).$2['user']
            as Map)['id'];
    expect(
      (await call(
        'PATCH',
        '/v1/orgs/$id/members/$benId',
        token: estimator,
        body: {'role': 'admin'},
      )).$1,
      403,
    );
    expect(
      (await call(
        'PATCH',
        '/v1/orgs/$id/members/$benId',
        token: owner,
        body: {'role': 'admin'},
      )).$2['members'],
      contains(containsPair('role', 'admin')),
    );
  });

  test('Enterprise inquiries reach sales without an account', () async {
    final (status, body) = await call(
      'POST',
      '/v1/inquiries',
      body: {
        'name': 'Maria Santos',
        'email': 'maria@santosbuilders.ph',
        'company': 'Santos Builders',
        'seats': 12,
        'message': 'We have 12 estimators.',
      },
    );
    expect(status, 201, reason: '$body');
    final sent = mailer.sent.single;
    expect(sent.to, 'sales@buildquantify.ph');
    expect(sent.subject, contains('Santos Builders'));
    expect(sent.replyTo, 'maria@santosbuilders.ph');
    expect(
      (await call(
        'POST',
        '/v1/inquiries',
        body: {'name': 'x', 'email': 'no'},
      )).$1,
      400,
    );

    final adminToken = await signIn(admin);
    final (_, list) = await call(
      'GET',
      '/v1/admin/inquiries',
      token: adminToken,
    );
    final inquiry = (list['inquiries'] as List).single as Map;
    expect(inquiry['seats'], 12);
    await call(
      'POST',
      '/v1/admin/inquiries/${inquiry['id']}/handled',
      token: adminToken,
    );
    expect(
      ((await call(
                'GET',
                '/v1/admin/inquiries',
                token: adminToken,
              )).$2['inquiries']
              as List)
          .isEmpty,
      isTrue,
    );
  });

  test('admins see counts, accounts and the audit log', () async {
    final adminToken = await signIn(admin);
    final ana = await signIn('ana');
    await call('POST', '/v1/trial', token: ana);
    final (_, stats) = await call('GET', '/v1/admin/stats', token: adminToken);
    expect(stats['users'], 2);
    expect(stats['trials'], 1);
    final (_, users) = await call(
      'GET',
      '/v1/admin/users?q=ana',
      token: adminToken,
    );
    final anaRow = (users['users'] as List).single as Map;
    expect(anaRow['plan']['source'], 'trial');
    final (_, extended) = await call(
      'POST',
      '/v1/admin/users/${anaRow['id']}/extend',
      token: adminToken,
      body: {'months': 2},
    );
    expect(extended['source'], 'paid');
    final (_, audit) = await call('GET', '/v1/admin/audit', token: adminToken);
    expect([
      for (final e in audit['entries'] as List) (e as Map)['action'],
    ], containsAll(['account.created', 'trial.started', 'plan.extended']));
    expect((await call('GET', '/v1/admin/stats', token: ana)).$1, 403);
  });

  test('browsers may call it only from the app\'s own address', () async {
    final preflight = await handler(
      Request(
        'OPTIONS',
        Uri.parse('http://api.test/v1/me'),
        headers: {'origin': 'https://app.buildquantify.ph'},
      ),
    );
    expect(preflight.statusCode, 204);
    expect(
      preflight.headers['access-control-allow-origin'],
      'https://app.buildquantify.ph',
    );
    expect(
      preflight.headers['access-control-allow-headers'],
      contains('authorization'),
    );
    final other = await handler(
      Request(
        'GET',
        Uri.parse('http://api.test/health'),
        headers: {'origin': 'https://evil.example'},
      ),
    );
    expect(other.headers['access-control-allow-origin'], isNull);
  });

  test('an account can be deleted with its projects', () async {
    final ana = await signIn('ana');
    await call(
      'PUT',
      '/v1/projects/p1',
      token: ana,
      body: {
        'data': {'name': 'House'},
      },
    );
    expect((await call('DELETE', '/v1/me', token: ana)).$1, 200);
    expect((await call('GET', '/v1/me', token: ana)).$1, 401);
    final rows = await pool.execute('select count(*) from projects');
    expect(rows.first[0], 0);
  });

  test('bad requests get a readable error', () async {
    final ana = await signIn('ana');
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://api.test/v1/codes/redeem'),
        headers: {'authorization': 'Bearer $ana'},
        body: '{not json',
      ),
    );
    expect(response.statusCode, 400);
    final big = await handler(
      Request(
        'PUT',
        Uri.parse('http://api.test/v1/documents/price_book'),
        headers: {'authorization': 'Bearer $ana'},
        body: jsonEncode({'data': 'x' * (2 << 20)}),
      ),
    );
    expect(big.statusCode, 413);
  });
}
