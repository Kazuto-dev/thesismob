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

  /// The account's projects, as `{data, version}`, and its documents.
  final projects = <String, Map<String, dynamic>>{};
  final documents = <String, Map<String, dynamic>>{};
  var _saves = 0;
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
      case ('GET', '/v1/projects'):
        return _json({
          'projects': [
            for (final MapEntry(:key, :value) in projects.entries)
              {'id': key, 'version': value['version'], 'readOnly': false},
          ],
        });
      case ('GET', final p) when p.startsWith('/v1/projects/'):
        final id = p.substring('/v1/projects/'.length);
        final project = projects[id];
        if (project == null) {
          return _error(404, 'not_found', 'No such project.');
        }
        return _json({'id': id, ...project});
      case ('PUT', final p) when p.startsWith('/v1/projects/'):
        final id = p.substring('/v1/projects/'.length);
        final existing = projects[id];
        if (existing == null) {
          if (plan == 'free' && projects.length >= 2) {
            return _error(402, 'plan_limit', 'The free plan keeps 2 projects.');
          }
        } else if (body['baseVersion'] != null &&
            body['baseVersion'] != existing['version']) {
          return _error(409, 'conflict', 'Changed on another device.');
        }
        final version = (existing?['version'] as int? ?? 0) + 1;
        // Saved as the database gives it back: keys in another order.
        projects[id] = {'data': _reorder(body['data']), 'version': version};
        return _json({'id': id, 'version': version});
      case ('DELETE', final p) when p.startsWith('/v1/projects/'):
        if (projects.remove(p.substring('/v1/projects/'.length)) == null) {
          return _error(404, 'not_found', 'No such project.');
        }
        return _json({'ok': true});
      case ('GET', final p) when p.startsWith('/v1/documents/'):
        final doc = documents[p.substring('/v1/documents/'.length)];
        if (doc == null) return _error(404, 'not_found', 'Not saved yet.');
        return _json(doc);
      case ('PUT', final p) when p.startsWith('/v1/documents/'):
        final at = 'save-${++_saves}';
        documents[p.substring('/v1/documents/'.length)] = {
          'data': _reorder(body['data']),
          'updatedAt': at,
        };
        return _json({'updatedAt': at});
      case ('GET', final p) when p == '/v1/orgs/${organization?['id']}':
        return _json({
          ...?organization,
          'members': [
            {
              'userId': 'u1',
              'email': 'maria@example.com',
              'name': 'Maria Santos',
              'role': organization!['role'],
            },
          ],
          'invitations': [
            {'email': 'jose@example.com', 'role': 'estimator'},
          ],
        });
    }
    return _error(404, 'not_found', 'Not found.');
  });
}

/// [json] with every object's keys reversed, as a database may return
/// them, and whole numbers written without a decimal point.
Object? _reorder(Object? json) => switch (json) {
  Map() => {for (final k in json.keys.toList().reversed) k: _reorder(json[k])},
  List() => [for (final v in json) _reorder(v)],
  double() when json == json.truncateToDouble() => json.toInt(),
  _ => json,
};
