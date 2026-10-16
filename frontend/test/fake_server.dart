import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in for the BuildQuantify server with one account, answering
/// like the real one (see server/lib/src/api.dart).
class FakeServer {
  FakeServer({DateTime Function()? clock})
    : _now = clock ?? (() => DateTime.now().toUtc());

  final DateTime Function() _now;
  String plan = 'free';
  String source = 'free';
  bool trialAvailable = true;
  String? trialEndsAt;
  String? paidUntil;

  /// The company giving the Enterprise plan, as `{id, name, role, seats}`.
  Map<String, Object?>? organization;
  final inquiries = <Map<String, dynamic>>[];
  final calls = <String>[];

  /// Valid codes; each gives 31 days of Business.
  final codes = {'BQ-AAAA-BBBB-CCCC-DDDD'};

  Map<String, dynamic> get me => {
    'user': {
      'id': 'u1',
      'email': 'maria@example.com',
      'name': 'Maria Santos',
      'isAdmin': false,
    },
    'plan': {
      'plan': plan,
      'source': source,
      'trialEndsAt': trialEndsAt,
      'paidUntil': paidUntil,
      'inGrace': false,
      'trialAvailable': trialAvailable,
      'organization': organization,
      'projectLimit': plan == 'free' ? 2 : null,
    },
    'organizations': <Object>[],
  };

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _error(int status, String code, String message) => _json({
    'error': {'code': code, 'message': message},
  }, status);

  late final client = MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');
    final body = request.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final signedIn = request.headers['authorization'] == 'Bearer session-1';
    switch ((request.method, path)) {
      case ('GET', '/v1/plans'):
        return _json({
          'trialDays': 14,
          'freeProjects': 2,
          'salesEmail': 'sales@example.com',
          'signInEnabled': true,
          'plans': [
            {'id': 'free', 'priceUsd': 0, 'pricePhp': 0},
            {'id': 'business', 'priceUsd': 20, 'pricePhp': 1150},
            {'id': 'enterprise', 'contactUs': true},
          ],
        });
      case ('POST', '/v1/auth/google'):
        return _json({'token': 'session-1', ...me});
      case ('POST', '/v1/inquiries'):
        inquiries.add(body);
        return _json({'id': 'i1'}, 201);
    }
    if (!signedIn) return _error(401, 'unauthorized', 'Sign in first.');
    switch ((request.method, path)) {
      case ('GET', '/v1/me'):
        return _json(me);
      case ('POST', '/v1/trial'):
        if (!trialAvailable) {
          return _error(409, 'trial_used', 'The free trial has been used.');
        }
        plan = 'business';
        source = 'trial';
        trialAvailable = false;
        trialEndsAt = _now().add(const Duration(days: 14)).toIso8601String();
        return _json(me);
      case ('POST', '/v1/codes/redeem'):
        if (!codes.remove(body['code'])) {
          return _error(
            404,
            'code_not_found',
            'That code is not valid. Check it against the email we sent.',
          );
        }
        plan = 'business';
        source = 'paid';
        paidUntil = _now().add(const Duration(days: 31)).toIso8601String();
        return _json(me);
      case ('POST', '/v1/auth/logout'):
        return _json({'ok': true});
    }
    return _error(404, 'not_found', 'Not found.');
  });
}
