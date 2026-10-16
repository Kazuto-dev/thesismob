import 'package:buildquantify_server/buildquantify_server.dart';
import 'package:test/test.dart';

void main() {
  group('activation codes', () {
    test('look like BQ-XXXX-XXXX-XXXX-XXXX and are all different', () {
      final codes = {for (var i = 0; i < 1000; i++) newActivationCode()};
      expect(codes, hasLength(1000));
      for (final c in codes.take(20)) {
        expect(c, matches(RegExp(r'^BQ(-[0-9A-HJKMNP-TV-Z]{4}){4}$')));
        expect(normalizeActivationCode(c), hasLength(16));
      }
    });

    test('are read the way people type them', () {
      const code = 'BQ-7K2M-9QXD-4HTR-W8NC';
      final n = normalizeActivationCode(code);
      expect(normalizeActivationCode('bq 7k2m 9qxd 4htr w8nc'), n);
      expect(normalizeActivationCode('7K2M9QXD4HTRW8NC'), n);
      // O, I and L are read as 0, 1 and 1.
      expect(
        normalizeActivationCode('BQ-0000-1111-0000-1111'),
        normalizeActivationCode('bq-oooo-iiii-OOOO-llll'),
      );
      expect(normalizeActivationCode('BQ-7K2M-9QXD'), isNull);
      expect(normalizeActivationCode('BQ-7K2M-9QXD-4HTR-W8NU'), isNull);
    });

    test('and session tokens are stored as hashes', () {
      expect(hashSecret('abc'), hashSecret('abc'));
      expect(hashSecret('abc'), isNot(hashSecret('abd')));
      expect(hashSecret('abc'), hasLength(32));
      expect(newSessionToken(), isNot(newSessionToken()));
    });

    test('mask the email they are for', () {
      expect(maskEmail('ana@example.com'), 'a**@example.com');
      expect(maskEmail('roberto@x.ph'), 'r******@x.ph');
    });
  });

  group('entitlements', () {
    final now = DateTime.utc(2026, 10, 16);

    test('a new account is free with a trial to take', () {
      final e = resolveEntitlement(now: now);
      expect(e.plan, Plan.free);
      expect(e.trialAvailable, isTrue);
      expect(e.projectLimit, 2);
    });

    test('a running trial gives Business; an ended one does not', () {
      final started = now.subtract(const Duration(days: 3));
      final trial = resolveEntitlement(
        now: now,
        trialStartedAt: started,
        trialEndsAt: started.add(const Duration(days: 14)),
      );
      expect(trial.plan, Plan.business);
      expect(trial.source, PlanSource.trial);
      expect(trial.projectLimit, isNull);
      final ended = resolveEntitlement(
        now: now.add(const Duration(days: 12)),
        trialStartedAt: started,
        trialEndsAt: started.add(const Duration(days: 14)),
      );
      expect(ended.plan, Plan.free);
      expect(ended.trialAvailable, isFalse);
    });

    test('paid time keeps working through the grace days', () {
      final paidUntil = now.subtract(const Duration(days: 2));
      final grace = resolveEntitlement(now: now, paidUntil: paidUntil);
      expect(grace.plan, Plan.business);
      expect(grace.inGrace, isTrue);
      final lapsed = resolveEntitlement(
        now: now.add(const Duration(days: 2)),
        paidUntil: paidUntil,
      );
      expect(lapsed.plan, Plan.free);
      expect(lapsed.trialAvailable, isTrue);
    });

    test('an active company gives Enterprise over the account\'s own plan', () {
      final e = resolveEntitlement(
        now: now,
        paidUntil: now.add(const Duration(days: 30)),
        organizations: [
          (
            id: 'old',
            name: 'Lapsed Co',
            role: Role.owner,
            seats: 3,
            paidUntil: now.subtract(const Duration(days: 10)),
          ),
          (
            id: 'org',
            name: 'Reyes Builders',
            role: Role.estimator,
            seats: 5,
            paidUntil: now.add(const Duration(days: 90)),
          ),
        ],
      );
      expect(e.plan, Plan.enterprise);
      expect(e.organization!.name, 'Reyes Builders');
      expect(e.toJson()['organization'], containsPair('role', 'estimator'));
    });
  });

  group('config', () {
    test('is read from the environment', () {
      final c = Config.fromEnvironment({
        'DATABASE_URL': 'postgres://bq:s%40cret@db:5433/bq?sslmode=require',
        'GOOGLE_CLIENT_IDS': 'a.apps.googleusercontent.com, b',
        'ADMIN_EMAILS': 'Owner@Example.com',
        'SMTP_HOST': 'smtp.gmail.com',
        'SMTP_USERNAME': 'sales@example.com',
        'TRIAL_DAYS': '7',
      });
      expect(c.database.host, 'db');
      expect(c.database.port, 5433);
      expect(c.database.password, 's@cret');
      expect(c.database.ssl, isTrue);
      expect(c.googleClientIds, ['a.apps.googleusercontent.com', 'b']);
      expect(c.isAdmin('owner@example.com'), isTrue);
      expect(c.smtp!.port, 587);
      expect(c.mailFrom, 'sales@example.com');
      expect(c.trialDays, 7);
      expect(c.freeProjects, 2);
    });

    test('needs a database', () {
      expect(() => Config.fromEnvironment({}), throwsStateError);
    });
  });

  test('a rate limiter refuses attempts over its limit in the window', () {
    var now = DateTime(2026);
    final limiter = RateLimiter(
      3,
      const Duration(minutes: 1),
      clock: () => now,
    );
    expect(
      [for (var i = 0; i < 4; i++) limiter.allow('a')],
      [true, true, true, false],
    );
    expect(limiter.allow('b'), isTrue);
    now = now.add(const Duration(minutes: 2));
    expect(limiter.allow('a'), isTrue);
  });
}
