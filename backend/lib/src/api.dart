import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'entitlements.dart';
import 'errors.dart';
import 'google.dart';
import 'mail.dart';
import 'rate_limit.dart';
import 'store.dart';

const apiVersion = '1.0.0';

/// The HTTP API. Every route answers JSON; errors come back as
/// `{"error": {"code": …, "message": …}}` with a matching status.
class Api {
  Api({required this.store, required this.google, required this.mailer})
    : config = store.config;

  final Store store;
  final GoogleVerifier google;
  final Mailer mailer;
  final Config config;

  final _signIns = RateLimiter(30, const Duration(minutes: 15));
  final _redeems = RateLimiter(10, const Duration(minutes: 15));
  final _inquiries = RateLimiter(5, const Duration(hours: 1));

  /// The whole API with its middleware.
  Handler get handler => const Pipeline()
      .addMiddleware(_errors)
      .addMiddleware(_cors)
      .addHandler(_router.call);

  Router get _router {
    final r = Router(notFoundHandler: (_) => throw ApiError.notFound());
    r.get('/health', (Request _) => _json({'ok': true, 'version': apiVersion}));
    r.get('/v1/plans', (Request _) => _json(_plans()));

    // Accounts
    r.post('/v1/auth/google', _signIn);
    r.post('/v1/auth/logout', (Request q) async {
      final token = _bearer(q);
      if (token != null) await store.deleteSession(token);
      return _json({'ok': true});
    });
    r.get('/v1/me', (Request q) async => _json(await _me(await _user(q))));
    r.delete('/v1/me', (Request q) async {
      await store.deleteAccount(await _user(q));
      return _json({'ok': true});
    });

    // Plans
    r.post('/v1/trial', (Request q) async {
      final user = await _user(q);
      await store.startTrial(user);
      return _json(await _me(user));
    });
    r.post('/v1/codes/redeem', (Request q) async {
      final user = await _user(q);
      if (!_redeems.allow(user.id) || !_redeems.allow('ip:${_ip(q)}')) {
        throw ApiError(
          429,
          'too_many_attempts',
          'Too many tries. Wait 15 minutes and check the code again.',
        );
      }
      final body = await _body(q);
      await store.redeemCode(user, _string(body, 'code'));
      return _json(await _me(user));
    });

    // Projects
    r.get('/v1/projects', (Request q) async {
      final list = await store.listProjects(await _user(q));
      return _json({
        'projects': [
          for (final p in list)
            {
              'id': p.id,
              'name': p.name,
              'version': p.version,
              'updatedAt': p.updatedAt.toUtc().toIso8601String(),
              'orgId': p.orgId,
              'ownerEmail': p.ownerEmail,
              'readOnly': p.readOnly,
            },
        ],
      });
    });
    r.get('/v1/projects/<id>', (Request q, String id) async {
      return _json(await store.getProject(await _user(q), id));
    });
    r.put('/v1/projects/<id>', (Request q, String id) async {
      final user = await _user(q);
      final body = await _body(q, maxBytes: 4 << 20);
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiError.badRequest('Send the project as "data".');
      }
      final saved = await store.saveProject(
        user,
        id,
        data,
        baseVersion: body['baseVersion'] is int
            ? body['baseVersion'] as int
            : null,
        orgId: body['orgId'] is String ? body['orgId'] as String : null,
      );
      return _json({
        'id': id,
        'version': saved.version,
        'updatedAt': saved.updatedAt.toUtc().toIso8601String(),
      });
    });
    r.delete('/v1/projects/<id>', (Request q, String id) async {
      await store.deleteProject(await _user(q), id);
      return _json({'ok': true});
    });

    // An account's own documents, such as its price book.
    r.get('/v1/documents/<key>', (Request q, String key) async {
      final user = await _user(q);
      final doc = await store.getDocument('user:${user.id}', key);
      if (doc == null) throw ApiError.notFound('Not saved yet.');
      return _json(doc);
    });
    r.put('/v1/documents/<key>', (Request q, String key) async {
      final user = await _user(q);
      final body = await _body(q, maxBytes: 1 << 20);
      final at = await store.putDocument(
        'user:${user.id}',
        key,
        body['data'],
        user.id,
      );
      return _json({'updatedAt': at.toUtc().toIso8601String()});
    });

    // Companies (Enterprise)
    r.get('/v1/orgs', (Request q) async {
      final user = await _user(q);
      return _json({
        'organizations': [
          for (final o in await store.organizationsOf(user.id)) _org(o),
        ],
      });
    });
    r.get('/v1/orgs/<id>', (Request q, String id) async {
      return _json(await store.organization(await _user(q), id));
    });
    r.patch('/v1/orgs/<id>', (Request q, String id) async {
      final user = await _user(q);
      await store.renameOrganization(user, id, _string(await _body(q), 'name'));
      return _json(await store.organization(user, id));
    });
    r.post('/v1/orgs/<id>/members', (Request q, String id) async {
      final user = await _user(q);
      final body = await _body(q);
      final email = _string(body, 'email');
      final role = Role.byName(body['role'] as String?) ?? Role.estimator;
      final invited = await store.addMember(user, id, email, role);
      final org = await store.organization(user, id);
      await trySend(mailer, (
        to: email,
        subject: '${_who(user)} added you to ${org['name']} on BuildQuantify',
        text: _invitationText(user, org['name'] as String, email, invited),
        replyTo: user.email,
      ));
      return _json(org);
    });
    r.patch('/v1/orgs/<id>/members/<member>', (
      Request q,
      String id,
      String member,
    ) async {
      final user = await _user(q);
      final role = Role.byName((await _body(q))['role'] as String?);
      if (role == null) throw ApiError.badRequest('Choose a role.');
      await store.setRole(user, id, member, role);
      return _json(await store.organization(user, id));
    });
    r.delete('/v1/orgs/<id>/members/<member>', (
      Request q,
      String id,
      String member,
    ) async {
      final user = await _user(q);
      await store.removeMember(user, id, member);
      return member == user.id
          ? _json({'ok': true})
          : _json(await store.organization(user, id));
    });
    r.delete('/v1/orgs/<id>/invitations/<email>', (
      Request q,
      String id,
      String email,
    ) async {
      final user = await _user(q);
      await store.removeInvitation(user, id, Uri.decodeComponent(email));
      return _json(await store.organization(user, id));
    });
    r.get('/v1/orgs/<id>/documents/<key>', (
      Request q,
      String id,
      String key,
    ) async {
      await store.requireMember(await _user(q), id);
      final doc = await store.getDocument('org:$id', key);
      if (doc == null) throw ApiError.notFound('Not saved yet.');
      return _json(doc);
    });
    r.put('/v1/orgs/<id>/documents/<key>', (
      Request q,
      String id,
      String key,
    ) async {
      final user = await _user(q);
      await store.requireManager(user, id);
      final body = await _body(q, maxBytes: 1 << 20);
      final at = await store.putDocument('org:$id', key, body['data'], user.id);
      return _json({'updatedAt': at.toUtc().toIso8601String()});
    });

    // "Contact us" for Enterprise; no account needed.
    r.post('/v1/inquiries', (Request q) async {
      if (!_inquiries.allow(_ip(q))) {
        throw ApiError(
          429,
          'too_many_attempts',
          'We have your message. Please wait before sending another.',
        );
      }
      final body = await _body(q);
      final id = await store.addInquiry(
        name: _string(body, 'name'),
        email: _string(body, 'email'),
        company: body['company'] is String ? body['company'] as String : '',
        phone: body['phone'] is String ? body['phone'] as String : '',
        seats: body['seats'] is int ? body['seats'] as int : null,
        message: body['message'] is String ? body['message'] as String : '',
      );
      if (config.salesEmail.isNotEmpty) {
        await trySend(mailer, (
          to: config.salesEmail,
          subject:
              'Enterprise inquiry from '
              '${(body['company'] as String?)?.isNotEmpty == true ? body['company'] : body['name']}',
          text: [
            'Name: ${body['name']}',
            'Email: ${body['email']}',
            'Company: ${body['company'] ?? ''}',
            'Phone: ${body['phone'] ?? ''}',
            'Seats: ${body['seats'] ?? ''}',
            '',
            '${body['message'] ?? ''}',
          ].join('\n'),
          replyTo: body['email'] as String,
        ));
      }
      return _json({'id': id}, status: 201);
    });

    // Admin
    r.post('/v1/admin/codes', (Request q) async {
      final admin = await _admin(q);
      final body = await _body(q);
      final plan = Plan.values.asNameMap()[body['plan']];
      if (plan == null || plan == Plan.free) {
        throw ApiError.badRequest('Choose business or enterprise.');
      }
      final issued = await store.issueCode(
        plan: plan,
        months: body['months'] is int ? body['months'] as int : 1,
        seats: body['seats'] is int ? body['seats'] as int : 1,
        email: body['email'] as String?,
        note: body['note'] is String ? body['note'] as String : '',
        createdBy: admin.email,
      );
      var emailed = false;
      if (body['send'] == true && issued.email != null) {
        emailed = await trySend(mailer, codeEmail(issued, config));
      }
      return _json({
        'id': issued.id,
        'code': issued.code,
        'plan': issued.plan.name,
        'months': issued.months,
        'seats': issued.seats,
        'email': issued.email,
        'redeemBy': issued.redeemBy.toUtc().toIso8601String(),
        'emailed': emailed,
      }, status: 201);
    });
    r.get('/v1/admin/codes', (Request q) async {
      await _admin(q);
      return _json({
        'codes': await store.listCodes(
          status: q.url.queryParameters['status'] ?? 'all',
        ),
      });
    });
    r.post('/v1/admin/codes/<id>/revoke', (Request q, String id) async {
      final admin = await _admin(q);
      await store.revokeCode(id, admin.email);
      return _json({'ok': true});
    });
    r.get('/v1/admin/users', (Request q) async {
      await _admin(q);
      return _json({
        'users': await store.listUsers(query: q.url.queryParameters['q'] ?? ''),
      });
    });
    r.post('/v1/admin/users/<id>/extend', (Request q, String id) async {
      final admin = await _admin(q);
      final user = await store.userById(id);
      if (user == null) throw ApiError.notFound('No such account.');
      final months = (await _body(q))['months'];
      if (months is! int) throw ApiError.badRequest('Send "months".');
      final e = await store.extendBusiness(user, months, admin.email);
      return _json(e.toJson());
    });
    r.patch('/v1/admin/orgs/<id>', (Request q, String id) async {
      final admin = await _admin(q);
      final body = await _body(q);
      await store.updateOrganization(
        id,
        seats: body['seats'] is int ? body['seats'] as int : null,
        addMonths: body['addMonths'] is int ? body['addMonths'] as int : null,
        actor: admin.email,
      );
      return _json({'ok': true});
    });
    r.get('/v1/admin/inquiries', (Request q) async {
      await _admin(q);
      return _json({
        'inquiries': await store.listInquiries(
          open: q.url.queryParameters['all'] != 'true',
        ),
      });
    });
    r.post('/v1/admin/inquiries/<id>/handled', (Request q, String id) async {
      await _admin(q);
      await store.markInquiryHandled(id);
      return _json({'ok': true});
    });
    r.get('/v1/admin/stats', (Request q) async {
      await _admin(q);
      return _json(await store.stats());
    });
    r.get('/v1/admin/audit', (Request q) async {
      await _admin(q);
      return _json({'entries': await store.auditLog()});
    });
    return r;
  }

  Map<String, Object?> _plans() => {
    'trialDays': config.trialDays,
    'freeProjects': config.freeProjects,
    'salesEmail': config.salesEmail,
    'signInEnabled': config.googleClientIds.isNotEmpty,
    'plans': [
      {
        'id': 'free',
        'name': 'Homeowners Edition',
        'priceUsd': 0,
        'pricePhp': 0,
      },
      {
        'id': 'business',
        'name': 'Business Edition',
        'priceUsd': config.businessPriceUsd,
        'pricePhp': config.businessPricePhp,
        'per': 'month',
      },
      {'id': 'enterprise', 'name': 'Enterprise Edition', 'contactUs': true},
    ],
  };

  Future<Response> _signIn(Request q) async {
    if (config.googleClientIds.isEmpty) {
      throw ApiError(
        503,
        'sign_in_off',
        'Sign-in is not set up on this server yet.',
      );
    }
    if (!_signIns.allow(_ip(q))) {
      throw ApiError(
        429,
        'too_many_attempts',
        'Too many sign-ins. Wait a bit.',
      );
    }
    final body = await _body(q);
    final GoogleIdentity identity;
    try {
      identity = await google.verify(
        idToken: body['idToken'] as String?,
        accessToken: body['accessToken'] as String?,
      );
    } on GoogleAuthException catch (e) {
      throw ApiError(401, 'google_rejected', e.message);
    }
    if (!config.googleClientIds.contains(identity.audience)) {
      throw ApiError(
        401,
        'google_rejected',
        'That Google sign-in was not made for BuildQuantify.',
      );
    }
    if (!identity.emailVerified) {
      throw ApiError(401, 'google_rejected', 'Verify your Google email first.');
    }
    final user = await store.signInWithGoogle(identity);
    final session = await store.createSession(
      user.id,
      userAgent: q.headers['user-agent'] ?? '',
    );
    return _json({
      'token': session.token,
      'expiresAt': session.expiresAt.toUtc().toIso8601String(),
      ...await _me(user),
    });
  }

  Future<Map<String, Object?>> _me(User user) async => {
    'user': {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'isAdmin': config.isAdmin(user.email),
    },
    'plan': (await store.entitlementOf(user.id)).toJson(),
    'organizations': [
      for (final o in await store.organizationsOf(user.id)) _org(o),
    ],
  };

  Map<String, Object?> _org(OrgAccess o) => {
    'id': o.id,
    'name': o.name,
    'role': o.role.name,
    'seats': o.seats,
    'paidUntil': o.paidUntil?.toUtc().toIso8601String(),
  };

  String? _bearer(Request q) {
    final header = q.headers['authorization'] ?? '';
    return header.startsWith('Bearer ') ? header.substring(7).trim() : null;
  }

  Future<User> _user(Request q) async {
    final token = _bearer(q);
    if (token == null || token.isEmpty) throw ApiError.unauthorized();
    final user = await store.userForToken(token);
    if (user == null) {
      throw ApiError.unauthorized('Your session has ended. Sign in again.');
    }
    return user;
  }

  Future<User> _admin(Request q) async {
    final user = await _user(q);
    if (!config.isAdmin(user.email)) throw ApiError.forbidden();
    return user;
  }

  /// The client's address: the first hop Caddy reports, or the socket's.
  String _ip(Request q) {
    final forwarded = q.headers['x-forwarded-for'];
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
    final info = q.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : 'local';
  }

  Middleware get _errors =>
      (inner) => (request) async {
        try {
          return await inner(request);
        } on ApiError catch (e) {
          return _json(e.toJson(), status: e.status);
        } on FormatException catch (e) {
          return _json(
            ApiError.badRequest(
              'That request could not be read: ${e.message}',
            ).toJson(),
            status: 400,
          );
        } on Object catch (e, stack) {
          stderr.writeln(
            '[error] ${request.method} ${request.url}: $e\n$stack',
          );
          return _json(
            ApiError(
              500,
              'server_error',
              'Something went wrong on our side.',
            ).toJson(),
            status: 500,
          );
        }
      };

  Middleware get _cors =>
      (inner) => (request) async {
        final origin = request.headers['origin'];
        final allowed =
            origin != null &&
            (config.allowedOrigins.contains('*') ||
                config.allowedOrigins.contains(origin));
        final headers = {
          if (allowed) 'access-control-allow-origin': origin,
          'vary': 'Origin',
        };
        if (request.method == 'OPTIONS') {
          return Response(
            204,
            headers: {
              ...headers,
              if (allowed) ...{
                'access-control-allow-methods':
                    'GET, POST, PUT, PATCH, DELETE, OPTIONS',
                'access-control-allow-headers': 'authorization, content-type',
                'access-control-max-age': '86400',
              },
            },
          );
        }
        final response = await inner(request);
        return response.change(headers: headers);
      };
}

Response _json(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
  },
);

/// The request's JSON object, refused above [maxBytes].
Future<Map<String, dynamic>> _body(Request q, {int maxBytes = 64 << 10}) async {
  final length = q.contentLength;
  if (length != null && length > maxBytes) {
    throw ApiError(413, 'too_large', 'That is too large to save.');
  }
  final bytes = <int>[];
  await for (final chunk in q.read()) {
    bytes.addAll(chunk);
    if (bytes.length > maxBytes) {
      throw ApiError(413, 'too_large', 'That is too large to save.');
    }
  }
  if (bytes.isEmpty) return {};
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, dynamic>) {
    throw ApiError.badRequest('Send a JSON object.');
  }
  return decoded;
}

String _string(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is! String || value.trim().isEmpty) {
    throw ApiError.badRequest('"$key" is missing.');
  }
  return value.trim();
}

String _who(User user) => user.name.isEmpty ? user.email : user.name;

String _invitationText(User by, String org, String email, bool invited) => [
  'Hello,',
  '',
  '${_who(by)} added you to $org on BuildQuantify, the estimating app for '
      'Philippine construction.',
  '',
  invited
      ? 'Open BuildQuantify and sign in with Google as $email to join.'
      : 'Next time you open BuildQuantify you will see $org\'s projects.',
  '',
  '— BuildQuantify',
].join('\n');

/// The email that carries a code to its customer.
Email codeEmail(IssuedCode issued, Config config) {
  final plan = issued.plan == Plan.enterprise ? 'Enterprise' : 'Business';
  final months = issued.months == 1 ? '1 month' : '${issued.months} months';
  final date = issued.redeemBy.toUtc().toIso8601String().substring(0, 10);
  return (
    to: issued.email!,
    subject: 'Your BuildQuantify $plan code',
    text: [
      'Hello,',
      '',
      'Thank you for choosing BuildQuantify $plan Edition. Your activation '
          'code is:',
      '',
      '    ${issued.code}',
      '',
      'To use it, open BuildQuantify, go to Settings, then Plan. Sign in with '
          'Google as ${issued.email} and enter the code. It adds $months of '
          '$plan'
          '${issued.plan == Plan.enterprise ? ' for ${issued.seats} people' : ''}'
          ' to your account. Please use it by $date.',
      if (config.appUrl.isNotEmpty) ...['', config.appUrl],
      '',
      'If you did not expect this email, reply to let us know.',
      '',
      '— BuildQuantify',
    ].join('\n'),
    replyTo: config.salesEmail.isEmpty ? null : config.salesEmail,
  );
}
