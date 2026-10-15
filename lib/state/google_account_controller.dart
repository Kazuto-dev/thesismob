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

/// The user's Google account, and saving projects to Google Sheets in it.
///
/// Only the account's name and email are remembered between visits. The
/// access token stays in memory, so after a reload the first save asks
/// Google again, usually with one click.
class GoogleAccountController extends ChangeNotifier {
  GoogleAccountController(this._prefs, this._auth, this._sheets)
    : _account = _load(_prefs) {
    _auth.warmUp();
  }

  static const key = 'google_account_v1';

  final SharedPreferences _prefs;
  final GoogleAuth _auth;
  final GoogleSheetsClient _sheets;
  GoogleAccount? _account;
  bool _busy = false;

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

  /// True while talking to Google.
  bool get isBusy => _busy;

  /// Asks the user to choose a Google account and allow access. Call it
  /// straight from a button press.
  Future<GoogleResult> signIn() => _run((token) async {
    await _identify(token, force: true);
    return (ok: true, message: 'Signed in as ${_account!.email}.', sheet: null);
  });

  Future<void> signOut() async {
    _account = null;
    unawaited(_prefs.remove(key));
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
  Future<GoogleResult> saveProject(Project project) => _run((token) async {
    await _identify(token);
    final tabs = projectSheetTabs(project);
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
    Future<GoogleResult> Function(String token) action,
  ) async {
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
      return await action(token);
    } on GoogleAuthException catch (e) {
      return (ok: false, message: _authMessage(e.failure), sheet: null);
    } on GoogleSheetsException catch (e) {
      if (e.failure == GoogleSheetsFailure.unauthorized && token != null) {
        await _auth.forget(token);
      }
      return (ok: false, message: _sheetsMessage(e.failure), sheet: null);
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
