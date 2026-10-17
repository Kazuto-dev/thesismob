import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/estimate.dart';
import '../data/price_quote.dart';
import '../data/project.dart';
import '../data/project_repository.dart';
import '../materials/items.dart';
import 'account_controller.dart';
import 'estimates_controller.dart';
import 'price_book_controller.dart';
import 'profile_controller.dart';
import 'projects_controller.dart';

/// Where the user's data stands with their account.
enum SyncState {
  /// No server in this build, or not signed in: saved on this device only.
  off,

  /// Talking to the server.
  syncing,

  /// Everything is saved to the account.
  saved,

  /// The server could not be reached; changes wait on this device.
  offline,

  /// The server refused something; see [CloudSync.message].
  failed,
}

/// Keeps the signed-in account's projects, prices, history and business
/// profile in the database on the server (see docs/backend.md). The copy
/// in this browser is a cache, so the app opens straight away and works
/// offline; changes go up a few seconds after they are made.
///
/// The first time an account signs in on a device, what the device
/// already holds is added to the account, so nothing made before signing
/// in is lost. When another account signs in, the previous account's copy
/// is cleared from the device first; it stays on the server.
///
/// Each project is sent on its own, with the version it was last loaded
/// at, so edits on two devices never overwrite each other: when both
/// changed, this device's edit is kept as a copy.
class CloudSync extends ChangeNotifier {
  CloudSync({
    required this._prefs,
    required this._api,
    required this._account,
    required this._projects,
    required this._prices,
    required this._history,
    required this._profile,
    this.delay = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    _docs = [
      _Doc(
        'price_book',
        isEmpty: (json) => (json['prices'] as Map? ?? const {}).isEmpty,
        encode: () => {
          'prices': _prices.custom,
          'quotes': {
            for (final MapEntry(:key, :value) in _prices.quotes.entries)
              key: value.toJson(),
          },
          'region': _prices.region.name,
        },
        apply: _applyPrices,
        merge: _mergePrices,
      ),
      _Doc(
        'history',
        isEmpty: (json) => (json['items'] as List? ?? const []).isEmpty,
        encode: () => {
          'items': [for (final e in _history.history) e.toJson()],
        },
        apply: (json) => _history.restoreHistory(_estimates(json['items'])),
        merge: _mergeHistory,
      ),
      _Doc(
        'profile',
        isEmpty: (json) => json.isEmpty,
        encode: () => _profile.profile.toJson(),
        apply: (json) => _profile.update(BusinessProfile.fromJson(json)),
        // This device's profile, unless it has none.
        merge: (local, server) => local.isEmpty ? server : local,
      ),
    ];
    _load();
    _account
      ..addListener(_accountChanged)
      ..beforeSignOut.add(flush);
    for (final c in _sources) {
      c.addListener(_changed);
    }
    _accountChanged();
  }

  static const key = 'cloud_sync_v1';

  /// How long after the last change it is sent.
  final Duration delay;

  final SharedPreferences _prefs;
  final ApiClient _api;
  final AccountController _account;
  final ProjectsController _projects;
  final PriceBookController _prices;
  final EstimatesController _history;
  final ProfileController _profile;
  final DateTime Function() _now;
  late final List<_Doc> _docs;

  List<ChangeNotifier> get _sources => [_projects, _prices, _history, _profile];

  // What the server holds, as last seen: the account it belongs to, each
  // project's version and contents, each document's save time and
  // contents. A local copy that no longer matches has changed since.
  String? _owner;
  final _known = <String, ({int version, int hash})>{};
  final _knownDocs = <String, ({String? at, int hash})>{};

  /// Projects the plan does not let this account keep or change.
  final _localOnly = <String>{};
  final _readOnly = <String>{};

  SyncState _state = SyncState.off;
  String? _message;
  DateTime? _savedAt;
  String? _signedInAs;
  Future<void>? _running;
  bool _pending = false;
  bool _pullPending = false;
  bool _applying = false;
  bool _disposed = false;
  Timer? _timer;

  SyncState get state => _state;

  /// Why the last save failed, for the user.
  String? get message => _message;

  /// When everything was last saved to the account.
  DateTime? get savedAt => _savedAt;

  bool get isOn => _signedInAs != null;

  /// Projects kept on this device only, because the account's plan holds
  /// no more of them or does not let this account change them.
  int get deviceOnlyProjects => _projects.projects
      .where(
        (p) =>
            _localOnly.contains(p.id) ||
            _readOnly.contains(p.id) && _isDirty(p),
      )
      .length;

  void _load() {
    final raw = _prefs.getString(key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _owner = json['owner'] as String?;
      for (final MapEntry(:key, :value)
          in (json['projects'] as Map? ?? const {}).entries) {
        _known[key as String] = (
          version: (value as Map)['v'] as int,
          hash: value['h'] as int,
        );
      }
      for (final MapEntry(:key, :value)
          in (json['documents'] as Map? ?? const {}).entries) {
        _knownDocs[key as String] = (
          at: (value as Map)['at'] as String?,
          hash: value['h'] as int,
        );
      }
      _localOnly.addAll([...?(json['localOnly'] as List?)?.cast<String>()]);
      _readOnly.addAll([...?(json['readOnly'] as List?)?.cast<String>()]);
      _savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    } on Object catch (e) {
      // Start afresh: the next sync compares everything again.
      debugPrint('Ignoring unreadable sync state: $e');
      _owner = null;
      _known.clear();
      _knownDocs.clear();
    }
  }

  void _save() => unawaited(
    _prefs.setString(
      key,
      jsonEncode({
        'owner': _owner,
        'projects': {
          for (final MapEntry(:key, :value) in _known.entries)
            key: {'v': value.version, 'h': value.hash},
        },
        'documents': {
          for (final MapEntry(:key, :value) in _knownDocs.entries)
            key: {'at': value.at, 'h': value.hash},
        },
        'localOnly': [..._localOnly],
        'readOnly': [..._readOnly],
        if (_savedAt != null) 'savedAt': _savedAt!.toIso8601String(),
      }),
    ),
  );

  void _accountChanged() {
    final status = _account.isSignedIn ? _account.status : null;
    // A new plan may hold more projects: try the ones it refused again.
    final signedIn = status == null
        ? null
        : '${status.userId}/${_account.plan.name}';
    if (signedIn == _signedInAs) return;
    final sameUser =
        _signedInAs != null &&
        signedIn != null &&
        _signedInAs!.split('/').first == status!.userId;
    _signedInAs = signedIn;
    if (signedIn == null) {
      _timer?.cancel();
      _state = SyncState.off;
      _message = null;
      _notify();
      return;
    }
    if (sameUser) _localOnly.clear();
    unawaited(syncNow());
  }

  void _changed() {
    if (_applying || !isOn || _disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_run(pull: false)));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Brings this device up to date with the account and sends what
  /// changed here.
  Future<void> syncNow() => _run(pull: true);

  /// Sends what changed here straight away, e.g. before signing out.
  Future<void> flush() async {
    _timer?.cancel();
    await _run(pull: false);
  }

  /// Runs a sync, or joins the one running, which then goes round again;
  /// either way it completes once everything asked for so far is done.
  Future<void> _run({required bool pull}) {
    _pending = true;
    _pullPending |= pull;
    return _running ??= _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    while (_pending && !_disposed) {
      final pull = _pullPending;
      _pending = false;
      _pullPending = false;
      await _sync(pull: pull);
    }
  }

  Future<void> _sync({required bool pull}) async {
    final token = _account.token;
    final user = _account.status?.userId;
    if (!_api.isConfigured || token == null || user == null || _disposed) {
      return;
    }
    _timer?.cancel();
    _state = SyncState.syncing;
    _notify();
    try {
      if (_owner != user) {
        // Another account's copy: it is on the server, so start clean.
        if (_owner != null) _clearDevice();
        _owner = user;
        _known.clear();
        _knownDocs.clear();
        _localOnly.clear();
        _readOnly.clear();
        pull = true;
      }
      if (pull) await _pullProjects(token);
      await _pushProjects(token);
      for (final doc in _docs) {
        await _syncDoc(token, doc, pull: pull);
      }
      _state = SyncState.saved;
      _message = null;
      _savedAt = _now();
    } on ApiException catch (e) {
      if (e.status == 401) {
        _state = SyncState.off;
      } else if (e.isOffline) {
        _state = SyncState.offline;
        // Try again in a while; any change tries sooner.
        _timer = Timer(const Duration(minutes: 1), () => unawaited(syncNow()));
      } else {
        _state = SyncState.failed;
        _message = e.message;
      }
    } finally {
      _save();
      _notify();
    }
  }

  void _clearDevice() => _apply(() {
    _projects.replaceAll(const []);
    _history.restoreHistory(const []);
    _prices.restore(const {}, quotes: const {});
    _profile.update(const BusinessProfile());
  });

  void _apply(void Function() change) {
    _applying = true;
    try {
      change();
    } finally {
      _applying = false;
    }
  }

  bool _isDirty(Project p) => _known[p.id]?.hash != _hash(p.toJson());

  // Projects

  Future<void> _pullProjects(String token) async {
    final answer = await _api.get('/v1/projects', token: token);
    final listed = <String>{};
    for (final s in answer['projects'] as List? ?? const []) {
      if (s is! Map) continue;
      final id = s['id'] as String;
      final version = s['version'] as int;
      listed.add(id);
      if (s['readOnly'] == true) {
        _readOnly.add(id);
      } else {
        _readOnly.remove(id);
      }
      final known = _known[id];
      if (known != null && known.version == version) continue;
      final local = _projects.byId(id);
      if (known != null && local == null) continue; // Deleted here.
      final full = await _api.get('/v1/projects/$id', token: token);
      final Project server;
      try {
        server = Project.fromJson(full['data'] as Map<String, dynamic>);
      } on Object catch (e) {
        debugPrint('Skipping an unreadable project from the account: $e');
        continue;
      }
      final serverVersion = full['version'] as int? ?? version;
      final serverHash = _hash(server.toJson());
      if (local == null) {
        _known[id] = (version: serverVersion, hash: serverHash);
        _apply(() => _projects.putFromCloud(server));
      } else if (known == null) {
        // On both before they were ever compared: keep the newer one.
        _known[id] = (version: serverVersion, hash: serverHash);
        if (!local.updatedAt.isAfter(server.updatedAt)) {
          _apply(() => _projects.putFromCloud(server));
        }
      } else if (!_isDirty(local)) {
        _known[id] = (version: serverVersion, hash: serverHash);
        _apply(() => _projects.putFromCloud(server));
      } else {
        // Changed here and on another device.
        _keepBoth(local, server, serverVersion);
      }
    }
    // Deleted on another device, or no longer shared with this account.
    for (final id in _known.keys.toList()) {
      if (listed.contains(id)) continue;
      final local = _projects.byId(id);
      if (local != null && !_isDirty(local)) {
        _apply(() => _projects.removeFromCloud(id));
      }
      _known.remove(id);
    }
    // The empty project every device starts with, once the account has
    // projects of its own.
    if (listed.isNotEmpty) {
      for (final p in _projects.projects) {
        if (!_known.containsKey(p.id) && _isBlank(p)) {
          _apply(() => _projects.removeFromCloud(p.id));
        }
      }
    }
  }

  /// Takes the account's [server] version of a project and keeps this
  /// device's edits of it as a copy, sent as a new project.
  void _keepBoth(Project local, Project server, int version) {
    _known[server.id] = (version: version, hash: _hash(server.toJson()));
    final copy = Project.fromJson({
      ...local.toJson(),
      'id': Estimate.newId(_now()),
      'name': '${local.name} (this device)',
    });
    _apply(() {
      _projects.putFromCloud(server);
      _projects.putFromCloud(copy);
    });
  }

  Future<void> _pushProjects(String token) async {
    for (final p in _projects.projects) {
      final known = _known[p.id];
      final hash = _hash(p.toJson());
      if (known?.hash == hash || _localOnly.contains(p.id)) continue;
      if (_readOnly.contains(p.id)) continue;
      if (known == null && _isBlank(p)) continue;
      try {
        final saved = await _api.put(
          '/v1/projects/${Uri.encodeComponent(p.id)}',
          token: token,
          body: {'data': p.toJson(), 'baseVersion': ?known?.version},
        );
        _known[p.id] = (version: saved['version'] as int, hash: hash);
      } on ApiException catch (e) {
        switch (e.code) {
          case 'conflict':
            final full = await _api.get('/v1/projects/${p.id}', token: token);
            _keepBoth(
              p,
              Project.fromJson(full['data'] as Map<String, dynamic>),
              full['version'] as int,
            );
            _pending = true; // Send the copy.
          case 'plan_limit' || 'forbidden' || 'id_taken' || 'too_large':
            _localOnly.add(p.id);
          default:
            rethrow;
        }
      }
    }
    final here = {for (final p in _projects.projects) p.id};
    for (final id in _known.keys.toList()) {
      if (here.contains(id)) continue;
      try {
        await _api.delete(
          '/v1/projects/${Uri.encodeComponent(id)}',
          token: token,
        );
      } on ApiException catch (e) {
        // Gone already, or not this account's to delete: it comes back
        // on the next sync if it is still shared.
        if (e.status != 404 && e.status != 403) rethrow;
      }
      _known.remove(id);
    }
    _localOnly.removeWhere((id) => !here.contains(id));
  }

  static bool _isBlank(Project p) {
    Map<String, dynamic> content(Project p) => p.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    return _canonical(content(p)) ==
        _canonical(content(Project.create(ProjectRepository.defaultName)));
  }

  // Prices, history and the business profile

  Future<void> _syncDoc(String token, _Doc doc, {required bool pull}) async {
    final known = _knownDocs[doc.key];
    if (pull) {
      Map<String, dynamic>? server;
      String? at;
      try {
        final answer = await _api.get('/v1/documents/${doc.key}', token: token);
        server = answer['data'] is Map<String, dynamic>
            ? answer['data'] as Map<String, dynamic>
            : null;
        at = answer['updatedAt'] as String?;
      } on ApiException catch (e) {
        if (e.status != 404) rethrow;
      }
      if (server != null && (known == null || at != known.at)) {
        final local = doc.encode();
        final dirty = known == null
            ? !doc.isEmpty(local)
            : _hash(local) != known.hash;
        final next = dirty ? doc.merge(local, server) : server;
        _apply(() => doc.apply(next));
        // A merge differs from the server's and so goes up below.
        _knownDocs[doc.key] = (
          at: at,
          hash: dirty ? _hash(server) : _hash(doc.encode()),
        );
      }
    }
    final local = doc.encode();
    final hash = _hash(local);
    final current = _knownDocs[doc.key];
    if (current?.hash == hash) return;
    if (current == null && doc.isEmpty(local)) return;
    final saved = await _api.put(
      '/v1/documents/${doc.key}',
      token: token,
      body: {'data': local},
    );
    _knownDocs[doc.key] = (at: saved['updatedAt'] as String?, hash: hash);
  }

  void _applyPrices(Map<String, dynamic> json) {
    _prices.restore(
      _priceMap(json['prices']),
      quotes: _quoteMap(json['quotes']),
    );
    if (json['region'] is String) {
      _prices.region = PriceRegion.byName(json['region'] as String);
    }
  }

  /// Both sides' prices, this device's where both have one.
  static Map<String, dynamic> _mergePrices(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) => {
    'prices': {
      ...?(server['prices'] as Map?)?.cast<String, Object?>(),
      ...?(local['prices'] as Map?)?.cast<String, Object?>(),
    },
    'quotes': {
      ...?(server['quotes'] as Map?)?.cast<String, Object?>(),
      ...?(local['quotes'] as Map?)?.cast<String, Object?>(),
    },
    'region': local['region'] ?? server['region'],
  };

  /// Both sides' history, newest first.
  static Map<String, dynamic> _mergeHistory(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final byId = {
      for (final e in _estimates(server['items'])) e.id: e,
      for (final e in _estimates(local['items'])) e.id: e,
    };
    final items = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return {
      'items': [
        for (final e in items.take(EstimatesController.historyLimit))
          e.toJson(),
      ],
    };
  }

  static List<Estimate> _estimates(Object? json) {
    final result = <Estimate>[];
    for (final item in json is List ? json : const []) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(Estimate.fromJson(item));
      } on FormatException {
        // Skip a damaged entry and keep the rest.
      }
    }
    return result..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Map<String, double> _priceMap(Object? json) => {
    if (json is Map)
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String && value is num && value >= 0) key: value.toDouble(),
  };

  static Map<String, PriceQuote> _quoteMap(Object? json) => {
    if (json is Map)
      for (final MapEntry(:key, :value) in json.entries)
        if (PriceQuote.fromJson(value) case final q? when key is String) key: q,
  };

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _account
      ..removeListener(_accountChanged)
      ..beforeSignOut.remove(flush);
    for (final c in _sources) {
      c.removeListener(_changed);
    }
    super.dispose();
  }
}

/// One of the account's documents on the server, read from and written to
/// the controller that holds it.
class _Doc {
  _Doc(
    this.key, {
    required this.isEmpty,
    required this.encode,
    required this.apply,
    required this.merge,
  });

  final String key;
  final bool Function(Map<String, dynamic>) isEmpty;
  final Map<String, dynamic> Function() encode;
  final void Function(Map<String, dynamic>) apply;

  /// What to keep when this device and the server both changed.
  final Map<String, dynamic> Function(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  )
  merge;
}

/// A fingerprint of [json] that does not depend on the order of keys or
/// on whether a whole number was written as 2 or 2.0, since the database
/// changes both.
int _hash(Object? json) {
  var hash = 0x811c9dc5;
  for (final unit in _canonical(json).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

String _canonical(Object? json) {
  final out = StringBuffer();
  void write(Object? v) {
    switch (v) {
      case Map():
        final keys = [for (final k in v.keys) '$k']..sort();
        out.write('{');
        for (final (i, k) in keys.indexed) {
          if (i > 0) out.write(',');
          out
            ..write(jsonEncode(k))
            ..write(':');
          write(v[k]);
        }
        out.write('}');
      case List():
        out.write('[');
        for (final (i, item) in v.indexed) {
          if (i > 0) out.write(',');
          write(item);
        }
        out.write(']');
      case num() when v.isFinite && v == v.truncateToDouble():
        out.write(v.toInt());
      default:
        out.write(jsonEncode(v));
    }
  }

  write(json);
  return out.toString();
}
