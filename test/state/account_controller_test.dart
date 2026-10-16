import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/account.dart';
import 'package:thesismob/data/api_client.dart';
import 'package:thesismob/state/account_controller.dart';

import '../fake_server.dart';

void main() {
  late FakeServer server;
  var now = DateTime.utc(2026, 10, 16, 9);

  Future<AccountController> controller([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    return AccountController(
      await SharedPreferences.getInstance(),
      ApiClient(baseUrl: 'https://api.test/', client: server.client),
      clock: () => now,
    );
  }

  setUp(() {
    now = DateTime.utc(2026, 10, 16, 9);
    server = FakeServer(clock: () => now);
  });

  test(
    'without a server address the plan is free and nothing is asked',
    () async {
      SharedPreferences.setMockInitialValues({});
      final c = AccountController(
        await SharedPreferences.getInstance(),
        ApiClient(baseUrl: ''),
      );
      expect(c.isConfigured, isFalse);
      expect(c.plan, AppPlan.free);
      await c.refresh();
      expect(c.isSignedIn, isFalse);
    },
  );

  test('signs in, starts the trial and keeps the plan for next time', () async {
    final c = await controller();
    await c.refresh();
    expect(c.offer.businessPhp, 1150);
    expect(await c.signInWithGoogle('google-token'), isNull);
    expect(c.isSignedIn, isTrue);
    expect(c.plan, AppPlan.free);
    expect(c.status!.trialAvailable, isTrue);

    expect(await c.startTrial(), isNull);
    expect(c.plan, AppPlan.business);
    expect(c.status!.trialDaysLeft(now), 14);
    expect(await c.startTrial(), 'The free trial has been used.');

    // A new start of the app reads the saved session and plan.
    final prefs = await SharedPreferences.getInstance();
    final again = AccountController(
      prefs,
      ApiClient(baseUrl: 'https://api.test', client: server.client),
      clock: () => now,
    );
    expect(again.plan, AppPlan.business);
    // Offline, the trial still ends on its date.
    now = DateTime.utc(2026, 10, 31);
    expect(again.plan, AppPlan.free);
  });

  test('a code switches Business on; a wrong one says why', () async {
    final c = await controller();
    await c.signInWithGoogle('google-token');
    expect(
      await c.redeem('BQ-0000-0000-0000-0000'),
      'That code is not valid. Check it against the email we sent.',
    );
    expect(await c.redeem(' BQ-AAAA-BBBB-CCCC-DDDD '), isNull);
    expect(c.plan, AppPlan.business);
    expect(c.status!.paidUntil, DateTime.utc(2026, 11, 16, 9));
    // Paid time keeps working three days after it ends.
    now = DateTime.utc(2026, 11, 18);
    expect(c.plan, AppPlan.business);
    now = DateTime.utc(2026, 11, 20);
    expect(c.plan, AppPlan.free);
  });

  test('a session the server no longer knows is dropped', () async {
    final c = await controller({
      AccountController.tokenKey: 'stale',
      AccountController.meKey:
          '{"user":{"id":"u1","email":"maria@example.com"},'
          '"plan":{"plan":"business","source":"paid",'
          '"paidUntil":"2027-01-01T00:00:00.000Z"}}',
    });
    expect(c.plan, AppPlan.business);
    await c.refresh();
    expect(c.isSignedIn, isFalse);
    expect(c.plan, AppPlan.free);
  });

  test('no connection is reported plainly and changes nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final c = AccountController(
      await SharedPreferences.getInstance(),
      ApiClient(baseUrl: 'https://down.test'),
    );
    final error = await c.sendInquiry(name: 'Maria', email: 'm@x.ph');
    expect(error, contains("Couldn't reach BuildQuantify"));
  });
}
