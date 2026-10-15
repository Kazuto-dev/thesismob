import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The Google account the user signed in with.
@immutable
class GoogleAccount {
  const GoogleAccount({required this.email, this.name = '', this.photoUrl});

  factory GoogleAccount.fromJson(Map<String, dynamic> json) {
    final email = json['email'];
    if (email is! String || email.isEmpty) {
      throw FormatException('GoogleAccount has no email', json);
    }
    return GoogleAccount(
      email: email,
      name: json['name'] is String ? json['name'] as String : '',
      photoUrl: json['picture'] is String ? json['picture'] as String : null,
    );
  }

  final String email;
  final String name;
  final String? photoUrl;

  /// The name to show, falling back to the email address.
  String get displayName => name.isEmpty ? email : name;

  Map<String, dynamic> toJson() => {
    'email': email,
    if (name.isNotEmpty) 'name': name,
    if (photoUrl != null) 'picture': photoUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is GoogleAccount &&
      other.email == email &&
      other.name == name &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(email, name, photoUrl);
}

/// Why Google sign-in did not give the app an access token.
enum GoogleAuthFailure {
  /// This build has no Google client ID.
  notConfigured,

  /// The user closed the Google window or declined.
  cancelled,

  /// Google could not be reached, e.g. offline.
  unavailable,

  /// Anything else Google reported.
  failed,
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.failure, [this.detail]);

  final GoogleAuthFailure failure;
  final String? detail;

  @override
  String toString() => 'GoogleAuthException($failure, $detail)';
}

/// Gets Google access tokens for the user. Replaced by a fake in tests.
abstract interface class GoogleAuth {
  /// Whether this build can sign in with Google at all.
  bool get isConfigured;

  /// Starts loading Google's sign-in code so the first sign-in is quick.
  void warmUp();

  /// Returns an access token for [GoogleAuth.scopes], asking the user to
  /// choose an account and allow access when needed. Call it straight from
  /// a button press, before any other `await`, so the browser lets Google
  /// open its window. Throws a [GoogleAuthException].
  Future<String> authorize();

  /// Forgets [token] after Google rejected it, so the next [authorize]
  /// asks again.
  Future<void> forget(String token);

  /// Signs out and revokes the app's access.
  Future<void> signOut();

  /// What the app asks for: who the user is, and the files it creates in
  /// their Drive. `drive.file` cannot see any other file, so Google does
  /// not require an app review for it.
  static const scopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/drive.file',
  ];
}

/// [GoogleAuth] through Google Identity Services (the `google_sign_in`
/// plugin). On the web it opens Google's account chooser in a pop-up and
/// keeps the token, which lasts about an hour, in memory only.
class GoogleSignInAuth implements GoogleAuth {
  GoogleSignInAuth({String? clientId})
    : clientId = clientId ?? const String.fromEnvironment('GOOGLE_CLIENT_ID');

  /// The OAuth client ID of type "Web application", supplied at build time
  /// with `--dart-define=GOOGLE_CLIENT_ID=...apps.googleusercontent.com`.
  final String clientId;

  Future<void>? _ready;

  @override
  bool get isConfigured => kIsWeb && clientId.isNotEmpty;

  Future<void> _initialize() =>
      _ready ??= GoogleSignIn.instance.initialize(clientId: clientId);

  @override
  void warmUp() {
    if (isConfigured) unawaited(_initialize().catchError((Object _) {}));
  }

  @override
  Future<String> authorize() async {
    if (!isConfigured) {
      throw const GoogleAuthException(GoogleAuthFailure.notConfigured);
    }
    try {
      await _initialize().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // Google's script never loaded; try loading it again next time.
      _ready = null;
      throw const GoogleAuthException(GoogleAuthFailure.unavailable);
    }
    try {
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizeScopes(GoogleAuth.scopes);
      return authorization.accessToken;
    } on GoogleSignInException catch (e) {
      throw GoogleAuthException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => GoogleAuthFailure.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          GoogleAuthFailure.notConfigured,
        GoogleSignInExceptionCode.uiUnavailable =>
          GoogleAuthFailure.unavailable,
        _ => GoogleAuthFailure.failed,
      }, e.description);
    }
  }

  @override
  Future<void> forget(String token) async {
    if (_ready == null) return;
    await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(
      accessToken: token,
    );
  }

  @override
  Future<void> signOut() async {
    if (_ready == null) return;
    await _ready;
    await GoogleSignIn.instance.disconnect();
  }
}
