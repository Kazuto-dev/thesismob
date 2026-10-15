import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in for Google's user info and Sheets APIs that keeps
/// spreadsheets in memory and records every request.
class FakeGoogleApi {
  final requests = <http.Request>[];

  /// Spreadsheet id → its tab titles.
  final spreadsheets = <String, List<String>>{};

  /// When set, the next request fails with this status and [failBody].
  int? failNext;
  String failBody = '{}';

  late final client = MockClient(_handle);

  /// Bodies of the requests whose path ends with [suffix].
  List<Map<String, dynamic>> bodies(String suffix) => [
    for (final r in requests)
      if (r.url.path.endsWith(suffix) && r.body.isNotEmpty)
        jsonDecode(r.body) as Map<String, dynamic>,
  ];

  /// Paths of the requests, with their method, in order.
  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.url.path}',
  ];

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Map<String, dynamic> _sheet(String id) => {
    'spreadsheetId': id,
    'spreadsheetUrl': 'https://docs.google.com/spreadsheets/d/$id/edit',
    'sheets': [
      for (final (i, title) in spreadsheets[id]!.indexed)
        {
          'properties': {'sheetId': i, 'title': title},
        },
    ],
  };

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (request.headers['Authorization']?.startsWith('Bearer ') != true) {
      return _json({}, 401);
    }
    if (failNext case final status?) {
      failNext = null;
      return http.Response(failBody, status);
    }
    if (request.url.host == 'www.googleapis.com') {
      return _json({
        'sub': '1',
        'email': 'maria@example.com',
        'name': 'Maria Santos',
        'picture': 'https://example.com/maria.png',
      });
    }
    final path = request.url.path;
    if (request.method == 'POST' && path == '/v4/spreadsheets') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = 'sheet${spreadsheets.length + 1}';
      spreadsheets[id] = [
        for (final s in body['sheets'] as List)
          (s as Map)['properties']['title'] as String,
      ];
      return _json(_sheet(id));
    }
    final match = RegExp(r'^/v4/spreadsheets/([^/:]+)(.*)$').firstMatch(path);
    if (match == null) return _json({}, 400);
    final id = match[1]!;
    final rest = match[2]!;
    if (!spreadsheets.containsKey(id)) return _json({}, 404);
    if (request.method == 'GET') return _json(_sheet(id));
    if (rest == ':batchUpdate') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final replies = <Map<String, dynamic>>[];
      for (final r in body['requests'] as List) {
        final add = (r as Map)['addSheet'];
        if (add != null) {
          final title = add['properties']['title'] as String;
          spreadsheets[id]!.add(title);
          replies.add({
            'addSheet': {
              'properties': {
                'sheetId': spreadsheets[id]!.length - 1,
                'title': title,
              },
            },
          });
        } else {
          replies.add({});
        }
      }
      return _json({'spreadsheetId': id, 'replies': replies});
    }
    return _json({'spreadsheetId': id});
  }
}
