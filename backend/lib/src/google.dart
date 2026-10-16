import 'dart:convert';

import 'package:http/http.dart' as http;

/// Who a Google sign-in belongs to.
typedef GoogleIdentity = ({
  String subject,
  String email,
  bool emailVerified,
  String name,

  /// The OAuth client the token was issued to.
  String audience,
});

/// Checks a token from Google Sign-In and says whose it is, or throws a
/// [GoogleAuthException].
abstract interface class GoogleVerifier {
  Future<GoogleIdentity> verify({String? idToken, String? accessToken});
}

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => 'GoogleAuthException: $message';
}

/// Asks Google's token info endpoint about the token. Google checks the
/// signature and expiry; the caller checks the audience. One request per
/// sign-in, not per API call, so the endpoint's limits are no concern.
class HttpGoogleVerifier implements GoogleVerifier {
  HttpGoogleVerifier({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _tokenInfo = Uri.parse(
    'https://oauth2.googleapis.com/tokeninfo',
  );
  static final _userInfo = Uri.parse(
    'https://openidconnect.googleapis.com/v1/userinfo',
  );

  @override
  Future<GoogleIdentity> verify({String? idToken, String? accessToken}) async {
    if ((idToken ?? '').isEmpty && (accessToken ?? '').isEmpty) {
      throw GoogleAuthException('No Google token was sent');
    }
    final query = (idToken ?? '').isNotEmpty
        ? {'id_token': idToken!}
        : {'access_token': accessToken!};
    final http.Response response;
    try {
      response = await _client
          .get(_tokenInfo.replace(queryParameters: query))
          .timeout(const Duration(seconds: 10));
    } on Exception catch (e) {
      throw GoogleAuthException('Google could not be reached: $e');
    }
    if (response.statusCode != 200) {
      throw GoogleAuthException('Google did not accept the token');
    }
    final info = jsonDecode(response.body) as Map<String, dynamic>;
    final email = info['email'];
    final subject = info['sub'];
    if (email is! String || subject is! String) {
      throw GoogleAuthException(
        'The token does not include the email; ask for the email scope',
      );
    }
    var name = info['name'] is String ? info['name'] as String : '';
    if (name.isEmpty && (accessToken ?? '').isNotEmpty) {
      name = await _nameFor(accessToken!);
    }
    return (
      subject: subject,
      email: email,
      emailVerified: '${info['email_verified']}' == 'true',
      name: name,
      // ID tokens name the client in `aud`; access tokens in `azp` and
      // `aud` both.
      audience: (info['azp'] ?? info['aud'] ?? '') as String,
    );
  }

  Future<String> _nameFor(String accessToken) async {
    try {
      final response = await _client
          .get(_userInfo, headers: {'authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return '';
      final info = jsonDecode(response.body);
      return info is Map && info['name'] is String
          ? info['name'] as String
          : '';
    } on Exception {
      return '';
    }
  }
}
