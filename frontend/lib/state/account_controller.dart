import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/account.dart';
import '../data/api_client.dart';

/// The user's BuildQuantify account and plan, from the server. The
/// session and the last answer are kept on the device, so the plan holds
/// offline and the app opens straight away.
class AccountController extends ChangeNotifier {
  AccountController(this._prefs, this._api, {DateTime Function()? clock})
    : _now = clock ?? (() => DateTime.now().toUtc()) {
    _token = _prefs.getString(tokenKey);
    _status = _read(meKey, AccountStatus.fromJson);
    _offer = _read(offerKey, PlanOffer.fromJson) ?? const PlanOffer();
  }

  static const tokenKey = 'account_token_v1';
  static const meKey = 'account_me_v1';
  static const offerKey = 'account_offer_v1';

  final SharedPreferences _prefs;
  final ApiClient _api;
  final DateTime Function() _now;

  String? _token;
  AccountStatus? _status;
  PlanOffer _offer = const PlanOffer();
  bool _busy = false;

  T? _read<T>(String key, T Function(Map<String, dynamic>) parse) {
    final text = _prefs.getString(key);
    if (text == null) return null;
    try {
      return parse(jsonDecode(text) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Whether this build of the app has a server to talk to.
  bool get isConfigured => _api.isConfigured;

  bool get isSignedIn => _token != null && _status != null;

  AccountStatus? get status => _status;

  PlanOffer get offer => _offer;

  bool get isBusy => _busy;

  /// The plan in force now: the free plan when signed out.
  AppPlan get plan => _status?.planAt(_now()) ?? AppPlan.free;

  DateTime now() => _now();

  /// Asks the server for the prices and, when signed in, the account's
  /// plan. Failures keep what was saved; a session the server no longer
  /// knows is dropped.
  Future<void> refresh() async {
    if (!isConfigured) return;
    try {
      final offer = await _api.get('/v1/plans');
      _offer = PlanOffer.fromJson(offer);
      unawaited(_prefs.setString(offerKey, jsonEncode(offer)));
      notifyListeners();
    } on ApiException {
      // Offline: keep the saved prices.
    }
    final token = _token;
    if (token == null) return;
    try {
      _store(await _api.get('/v1/me', token: token));
    } on ApiException catch (e) {
      if (e.status == 401) _clear();
    }
  }

  void _store(Map<String, dynamic> me) {
    _status = AccountStatus.fromJson(me);
    unawaited(_prefs.setString(meKey, jsonEncode(me)));
    notifyListeners();
  }

  void _clear() {
    _token = null;
    _status = null;
    unawaited(_prefs.remove(tokenKey));
    unawaited(_prefs.remove(meKey));
    notifyListeners();
  }

  /// Runs [action], returning null when it worked or a message for the
  /// user when it did not.
  Future<String?> _guard(Future<void> Function() action) async {
    if (_busy) return 'Still working on it…';
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on ApiException catch (e) {
      if (e.status == 401) _clear();
      return e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Signs in to the account with a Google access token from the app's
  /// Google sign-in.
  Future<String?> signInWithGoogle(String accessToken) => _guard(() async {
    final answer = await _api.post(
      '/v1/auth/google',
      body: {'accessToken': accessToken},
    );
    _token = answer['token'] as String;
    unawaited(_prefs.setString(tokenKey, _token!));
    _store(answer);
  });

  /// Starts the one free trial of Business.
  Future<String?> startTrial() => _guard(() async {
    _store(await _api.post('/v1/trial', token: _token));
  });

  /// Applies an activation code from an email.
  Future<String?> redeem(String code) => _guard(() async {
    _store(
      await _api.post(
        '/v1/codes/redeem',
        token: _token,
        body: {'code': code.trim()},
      ),
    );
  });

  /// The company the Enterprise plan comes from, with its members and
  /// invitations, as `GET /v1/orgs/{id}` answers.
  Future<Map<String, dynamic>> company() async {
    final id = (_status?.raw['plan'] as Map?)?['organization']?['id'];
    if (id == null) throw ApiException(404, 'not_found', 'No company.');
    return _api.get('/v1/orgs/$id', token: _token);
  }

  /// Sends an Enterprise inquiry; no account needed.
  Future<String?> sendInquiry({
    required String name,
    required String email,
    String company = '',
    String phone = '',
    int? seats,
    String message = '',
  }) => _guard(() async {
    await _api.post(
      '/v1/inquiries',
      body: {
        'name': name,
        'email': email,
        'company': company,
        'phone': phone,
        'seats': ?seats,
        'message': message,
      },
    );
  });

  /// Signs out of the account on this device.
  Future<void> signOut() async {
    final token = _token;
    _clear();
    if (token == null) return;
    try {
      await _api.post('/v1/auth/logout', token: token);
    } on ApiException {
      // Signed out here regardless; the session ends on its own.
    }
  }
}
