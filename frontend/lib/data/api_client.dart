import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A failure reported by the BuildQuantify server, or no connection.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);

  /// The HTTP status; 0 when the server could not be reached.
  final int status;

  /// The server's stable error code, such as `code_used` or `plan_limit`.
  final String code;

  /// A sentence for the user.
  final String message;

  bool get isOffline => status == 0;

  @override
  String toString() => 'ApiException($status $code: $message)';
}

/// Talks to the BuildQuantify server (see docs/backend.md). Its address
/// is set when the app is built, with `--dart-define=API_URL=…`: a full
/// address such as `https://api.example.com`, or a path such as `/api`
/// on the address the app itself is served from, as nginx does. Without
/// one, accounts and plans are off and the app works on its own.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl = _trim(baseUrl ?? const String.fromEnvironment('API_URL')),
      _client = client ?? http.Client();

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  final String baseUrl;
  final http.Client _client;

  bool get isConfigured => baseUrl.isNotEmpty;

  /// The full address of [path]: a relative [baseUrl] is taken from the
  /// page the app was loaded from.
  Uri uri(String path) => baseUrl.startsWith('/')
      ? Uri.base.resolve('$baseUrl$path')
      : Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> get(String path, {String? token}) =>
      _send('GET', path, token: token);

  Future<Map<String, dynamic>> post(
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) => _send('POST', path, token: token, body: body);

  Future<Map<String, dynamic>> put(
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) => _send('PUT', path, token: token, body: body);

  Future<Map<String, dynamic>> delete(String path, {String? token}) =>
      _send('DELETE', path, token: token);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    if (!isConfigured) {
      throw ApiException(0, 'not_configured', 'Accounts are not set up yet.');
    }
    final request = http.Request(method, uri(path));
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } on Object {
      throw ApiException(
        0,
        'offline',
        "Couldn't reach BuildQuantify. Check your connection and try again.",
      );
    }
    Object? decoded;
    try {
      decoded = response.body.isEmpty ? const {} : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException(response.statusCode, 'bad_response', _unexpected);
    }
    final error = decoded is Map && decoded['error'] is Map
        ? decoded['error'] as Map
        : const {};
    throw ApiException(
      response.statusCode,
      error['code'] is String ? error['code'] as String : 'error',
      error['message'] is String ? error['message'] as String : _unexpected,
    );
  }

  static const _unexpected = 'Something went wrong. Try again in a moment.';
}
