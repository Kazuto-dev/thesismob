import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/google_auth.dart';
import '../data/google_sheets_client.dart';
import '../data/project.dart';
import '../export/project_sheets.dart';

/// The outcome of a Google action, with a message for the user.
typedef GoogleResult = ({bool ok, String message, SpreadsheetRef? sheet});

/// A backup read from Google Drive: its contents, or why there are none.
typedef DriveBackup = ({GoogleResult result, String? content});

/// The user's Google account, and saving projects to Google Sheets in it.
///
/// Only the account's name and email are remembered between visits. The
/// access token stays in memory, so after a reload the first save asks
/// Google again, usually with one click.
class GoogleAccountController extends ChangeNotifier {
  GoogleAccountController(
    this._prefs,
    this._auth,
    this._sheets, {
    DateTime Function()? clock,
  }) : _account = _load(_prefs),
       _skipped = _prefs.getBool(skippedKey) ?? false,
       _now = clock ?? DateTime.now {
    _auth.warmUp();
    _loadBackup();
  }

  static const key = 'google_account_v1';

  /// Set when the user chose to continue without signing in.
  static const skippedKey = 'google_sign_in_skipped_v1';

  /// The Drive backup file, when it was last saved, and whether to keep it
  /// up to date automatically.
  static const backupKey = 'drive_backup_v1';

  /// How long a token is reused for automatic backups. Google's tokens
  /// last an hour.
  static const tokenLife = Duration(minutes: 50);

  final SharedPreferences _prefs;
  final GoogleAuth _auth;
  final GoogleSheetsClient _sheets;
  GoogleAccount? _account;
  bool _skipped;
  bool _busy = false;
  final DateTime Function() _now;

  /// The latest access token, kept in memory for automatic backups.
  String? _token;
  DateTime? _tokenAt;

  String? _backupId;
  DateTime? _backedUpAt;
  bool _autoBackup = false;
  bool _backingUp = false;

  void _loadBackup() {
    final raw = _prefs.getString(backupKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _backupId = json['id'] as String?;
      _backedUpAt = DateTime.tryParse(json['at'] as String? ?? '');
      _autoBackup = json['auto'] == true;
    } on Object {
      // Start afresh; the next backup finds the file again.
    }
  }

  void _saveBackupState() => unawaited(
    _prefs.setString(
      backupKey,
      jsonEncode({
        'id': ?_backupId,
        if (_backedUpAt != null) 'at': _backedUpAt!.toIso8601String(),
        'auto': _autoBackup,
      }),
    ),
  );

  /// When the projects were last backed up to Google Drive.
  DateTime? get lastBackup => _backedUpAt;

  /// Whether changes are backed up to Drive by themselves while the user
  /// is signed in.
  bool get autoBackup => _autoBackup;

  void setAutoBackup(bool on) {
    if (on == _autoBackup) return;
    _autoBackup = on;
    _saveBackupState();
    notifyListeners();
  }

  /// Saves [content] to the backup file in the user's Drive, creating it
  /// the first time. Call it straight from a button press.
  Future<GoogleResult> backUp(String content) => _run((token) async {
    await _identify(token);
    await _writeBackup(token, content);
    return (ok: true, message: 'Backed up to your Google Drive.', sheet: null);
  }, drive: true);

  /// Reads the backup file from the user's Drive. Call it straight from a
  /// button press.
  Future<DriveBackup> fetchBackup() async {
    String? content;
    final result = await _run((token) async {
      await _identify(token);
      final file = await _sheets.findBackup(token);
      if (file == null) {
        return (
          ok: false,
          message: 'There is no BuildQuantify backup in this Google Drive yet.',
          sheet: null,
        );
      }
      content = await _sheets.readBackup(token, file.id);
      _backupId = file.id;
      _saveBackupState();
      return (ok: true, message: 'Found your backup.', sheet: null);
    }, drive: true);
    return (result: result, content: content);
  }

  /// Backs up [content] without asking the user, when automatic backups
  /// are on and a recent sign-in left a token to use. Does nothing
  /// otherwise; a failure waits for the next change or a manual backup.
  Future<void> autoBackUp(String content) async {
    final token = _token;
    final at = _tokenAt;
    if (!_autoBackup || !isSignedIn || _busy || _backingUp) return;
    if (token == null || at == null || _now().difference(at) > tokenLife) {
      return;
    }
    _backingUp = true;
    try {
      await _writeBackup(token, content);
      notifyListeners();
    } on GoogleSheetsException catch (e) {
      if (e.failure == GoogleSheetsFailure.unauthorized) _token = null;
    } finally {
      _backingUp = false;
    }
  }

  Future<void> _writeBackup(String token, String content) async {
    var id = _backupId ?? (await _sheets.findBackup(token))?.id;
    DriveFile file;
    try {
      file = await _sheets.saveBackup(token, content, id: id);
    } on GoogleSheetsException catch (e) {
      // Deleted from Drive since: make a new one.
      if (id == null || e.failure != GoogleSheetsFailure.notFound) rethrow;
      id = null;
      file = await _sheets.saveBackup(token, content);
    }
    _backupId = file.id;
    _backedUpAt = file.modified ?? _now();
    _saveBackupState();
  }

  static GoogleAccount? _load(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return GoogleAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Whether this build can sign in with Google.
  bool get isConfigured => _auth.isConfigured;

  GoogleAccount? get account => _account;

  bool get isSignedIn => _account != null;

  /// Whether to show the login screen: Google sign-in is available, and
  /// the user has neither signed in nor chosen to continue without it.
  bool get needsSignIn => isConfigured && !isSignedIn && !_skipped;

  /// Uses the app without a Google account; the login screen stops
  /// appearing until the user signs out of an account.
  void skipSignIn() {
    if (_skipped) return;
    _skipped = true;
    unawaited(_prefs.setBool(skippedKey, true));
    notifyListeners();
  }

  /// True while talking to Google.
  bool get isBusy => _busy;

  /// Asks the user to choose a Google account and allow access. Call it
  /// straight from a button press. [alsoWith] gets the access token, such
  /// as to sign in to the BuildQuantify account too; its failure does not
  /// undo the Google sign-in.
  Future<GoogleResult> signIn({
    Future<void> Function(String token)? alsoWith,
  }) => _run((token) async {
    await _identify(token, force: true);
    await alsoWith?.call(token);
    return (ok: true, message: 'Signed in as ${_account!.email}.', sheet: null);
  });

  /// Signs in with Google and passes the access token to [use], such as
  /// to sign in to the BuildQuantify account. Call it straight from a
  /// button press.
  Future<GoogleResult> withToken(
    Future<GoogleResult> Function(String token) use,
  ) => _run((token) async {
    await _identify(token);
    return use(token);
  });

  Future<void> signOut() async {
    _account = null;
    _skipped = false;
    _token = null;
    // The backup belongs to that account.
    _backupId = null;
    _backedUpAt = null;
    unawaited(_prefs.remove(backupKey));
    _autoBackup = false;
    unawaited(_prefs.remove(key));
    unawaited(_prefs.remove(skippedKey));
    notifyListeners();
    try {
      await _auth.signOut();
    } on Object {
      // Signed out here regardless; Google forgets the token within an hour.
    }
  }

  /// Saves [project] to its spreadsheet in the user's Drive, creating one
  /// the first time or when the old one is gone. Call it straight from a
  /// button press. On success, [GoogleResult.sheet] is the spreadsheet to
  /// remember for the project.
  Future<GoogleResult> saveProject(
    Project project, {
    Map<String, String> suppliers = const {},
  }) => _run((token) async {
    await _identify(token);
    final tabs = projectSheetTabs(project, suppliers: suppliers);
    SpreadsheetRef? sheet;
    if (project.sheetId case final id?) {
      try {
        sheet = await _sheets.update(token, id, tabs);
      } on GoogleSheetsException catch (e) {
        // Deleted, or made by another account: start a new one.
        if (e.failure != GoogleSheetsFailure.notFound &&
            e.failure != GoogleSheetsFailure.forbidden) {
          rethrow;
        }
      }
    }
    sheet ??= await _sheets.create(token, projectSheetTitle(project), tabs);
    return (
      ok: true,
      message: 'Saved "${projectSheetTitle(project)}" to your Google Drive.',
      sheet: sheet,
    );
  });

  Future<void> _identify(String token, {bool force = false}) async {
    if (_account != null && !force) return;
    final account = await _sheets.userInfo(token);
    _account = account;
    unawaited(_prefs.setString(key, jsonEncode(account.toJson())));
    notifyListeners();
  }

  Future<GoogleResult> _run(
    Future<GoogleResult> Function(String token) action, {
    bool drive = false,
  }) async {
    if (_busy) {
      return (ok: false, message: 'Still working on it…', sheet: null);
    }
    _busy = true;
    notifyListeners();
    String? token;
    try {
      // First, before anything else is awaited, so the browser allows
      // Google's window to open.
      token = await _auth.authorize();
      _token = token;
      _tokenAt = _now();
      return await action(token);
    } on GoogleAuthException catch (e) {
      return (ok: false, message: _authMessage(e.failure), sheet: null);
    } on GoogleSheetsException catch (e) {
      if (e.failure == GoogleSheetsFailure.unauthorized && token != null) {
        _token = null;
        await _auth.forget(token);
      }
      return (
        ok: false,
        message: drive && e.failure == GoogleSheetsFailure.apiDisabled
            ? "The Google Drive API isn't enabled for this app yet."
            : drive && e.failure == GoogleSheetsFailure.failed
            ? "Couldn't reach your Google Drive backup. Try again."
            : _sheetsMessage(e.failure),
        sheet: null,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  static String _authMessage(GoogleAuthFailure f) => switch (f) {
    GoogleAuthFailure.notConfigured =>
      "Google sign-in isn't set up for this build of the app.",
    GoogleAuthFailure.cancelled => 'Google sign-in was cancelled.',
    GoogleAuthFailure.unavailable =>
      "Couldn't reach Google. Check your connection and try again.",
    GoogleAuthFailure.failed => 'Google sign-in failed. Try again.',
  };

  static String _sheetsMessage(GoogleSheetsFailure f) => switch (f) {
    GoogleSheetsFailure.unauthorized =>
      'Your Google sign-in expired. Try again to sign in.',
    GoogleSheetsFailure.apiDisabled =>
      "The Google Sheets API isn't enabled for this app yet.",
    GoogleSheetsFailure.forbidden =>
      "Google didn't allow the app to change that spreadsheet.",
    GoogleSheetsFailure.notFound => "Couldn't find the spreadsheet.",
    GoogleSheetsFailure.rateLimited =>
      'Google is busy. Wait a minute and try again.',
    GoogleSheetsFailure.offline =>
      "Couldn't reach Google. Check your connection and try again.",
    GoogleSheetsFailure.failed => "Couldn't save to Google Sheets. Try again.",
  };
}
