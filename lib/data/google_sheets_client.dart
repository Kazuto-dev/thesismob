import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'google_auth.dart';

/// One tab of a spreadsheet: its rows and how to format them.
typedef SheetTab = ({
  String title,
  List<List<Object?>> rows,

  /// Index of the row holding the column headings, which stays frozen.
  int headerRow,

  /// Columns shown as pesos (#,##0.00) and as quantities (#,##0.###).
  List<int> moneyColumns,
  List<int> quantityColumns,

  /// Rows in bold, such as trade headings and totals.
  List<int> boldRows,
});

/// What went wrong talking to Google.
enum GoogleSheetsFailure {
  /// The access token expired or was revoked.
  unauthorized,

  /// The Sheets API is not enabled for the app's Google Cloud project.
  apiDisabled,

  /// No access to that spreadsheet, e.g. it belongs to another account.
  forbidden,

  /// The spreadsheet was deleted.
  notFound,

  /// Too many requests; try again shortly.
  rateLimited,

  /// No connection.
  offline,

  failed,
}

class GoogleSheetsException implements Exception {
  const GoogleSheetsException(this.failure, [this.detail]);

  final GoogleSheetsFailure failure;
  final String? detail;

  @override
  String toString() => 'GoogleSheetsException($failure, $detail)';
}

/// A spreadsheet the app created in the user's Drive.
typedef SpreadsheetRef = ({String id, String url});

/// Spreadsheet URL for an id.
String spreadsheetUrl(String id) =>
    'https://docs.google.com/spreadsheets/d/$id/edit';

/// A backup file the app keeps in the user's Drive.
typedef DriveFile = ({String id, DateTime? modified});

/// Calls Google's user info, Sheets and Drive APIs with the user's access
/// token. The app only ever touches files it created.
class GoogleSheetsClient {
  GoogleSheetsClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static final _sheets = Uri.parse('https://sheets.googleapis.com/v4/');
  static final _userInfo = Uri.parse(
    'https://www.googleapis.com/oauth2/v3/userinfo',
  );
  static final _drive = Uri.parse('https://www.googleapis.com/drive/v3/');
  static final _upload = Uri.parse(
    'https://www.googleapis.com/upload/drive/v3/',
  );

  /// The backup file's name in the user's Drive.
  static const backupName = 'BuildQuantify backup.json';

  static DriveFile _file(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) {
      throw const GoogleSheetsException(GoogleSheetsFailure.failed);
    }
    final modified = json['modifiedTime'];
    return (
      id: id,
      modified: modified is String ? DateTime.tryParse(modified) : null,
    );
  }

  /// The newest backup the app saved in the user's Drive, if any. With the
  /// `drive.file` scope, Drive only lists files this app created.
  Future<DriveFile?> findBackup(String token) async {
    final json = await _send(
      'GET',
      _drive
          .resolve('files')
          .replace(
            queryParameters: {
              'q': "name = '$backupName' and trashed = false",
              'spaces': 'drive',
              'orderBy': 'modifiedTime desc',
              'pageSize': '1',
              'fields': 'files(id,modifiedTime)',
            },
          ),
      token,
    );
    final files = json['files'];
    if (files is! List || files.isEmpty || files.first is! Map) return null;
    return _file(Map<String, dynamic>.from(files.first as Map));
  }

  /// Saves [content] as the backup file, replacing the one with [id] or
  /// creating a new one.
  Future<DriveFile> saveBackup(
    String token,
    String content, {
    String? id,
  }) async {
    if (id != null) {
      return _file(
        await _send(
          'PATCH',
          _upload
              .resolve('files/$id')
              .replace(
                queryParameters: {
                  'uploadType': 'media',
                  'fields': 'id,modifiedTime',
                },
              ),
          token,
          raw: (content: content, type: 'application/json; charset=UTF-8'),
        ),
      );
    }
    const boundary = 'buildquantify-backup-boundary';
    final body =
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode({'name': backupName, 'mimeType': 'application/json'})}'
        '\r\n--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$content\r\n--$boundary--';
    return _file(
      await _send(
        'POST',
        _upload
            .resolve('files')
            .replace(
              queryParameters: {
                'uploadType': 'multipart',
                'fields': 'id,modifiedTime',
              },
            ),
        token,
        raw: (content: body, type: 'multipart/related; boundary=$boundary'),
      ),
    );
  }

  /// The contents of the backup file [id].
  Future<String> readBackup(String token, String id) async {
    final response = await _request(
      'GET',
      _drive.resolve('files/$id').replace(queryParameters: {'alt': 'media'}),
      token,
    );
    return utf8.decode(response.bodyBytes);
  }

  /// Who the token belongs to.
  Future<GoogleAccount> userInfo(String token) async {
    final json = await _send('GET', _userInfo, token);
    try {
      return GoogleAccount.fromJson(json);
    } on FormatException {
      throw const GoogleSheetsException(GoogleSheetsFailure.failed);
    }
  }

  /// Creates a spreadsheet called [title] holding [tabs].
  Future<SpreadsheetRef> create(
    String token,
    String title,
    List<SheetTab> tabs,
  ) async {
    final json = await _send(
      'POST',
      _sheets.resolve('spreadsheets'),
      token,
      body: {
        'properties': {'title': title},
        'sheets': [
          for (final t in tabs)
            {
              'properties': {'title': t.title},
            },
        ],
      },
    );
    final id = json['spreadsheetId'];
    if (id is! String) {
      throw const GoogleSheetsException(GoogleSheetsFailure.failed);
    }
    await _fill(token, id, tabs, _sheetIds(json), clear: false);
    final url = json['spreadsheetUrl'];
    return (id: id, url: url is String ? url : spreadsheetUrl(id));
  }

  /// Replaces the contents of [tabs] in an existing spreadsheet, adding
  /// any tab the user deleted. Other tabs are left alone.
  Future<SpreadsheetRef> update(
    String token,
    String id,
    List<SheetTab> tabs,
  ) async {
    final json = await _send(
      'GET',
      _sheets.resolve(
        'spreadsheets/$id?fields=spreadsheetUrl,sheets.properties(sheetId,title)',
      ),
      token,
    );
    final ids = _sheetIds(json);
    final missing = [
      for (final t in tabs)
        if (!ids.containsKey(t.title)) t.title,
    ];
    if (missing.isNotEmpty) {
      final added = await _batchUpdate(token, id, [
        for (final title in missing)
          {
            'addSheet': {
              'properties': {'title': title},
            },
          },
      ]);
      for (final reply in added['replies'] as List? ?? const []) {
        final props = (reply as Map)['addSheet']?['properties'];
        if (props is Map && props['title'] is String) {
          ids[props['title'] as String] = props['sheetId'] as int;
        }
      }
    }
    await _fill(token, id, tabs, ids, clear: true);
    final url = json['spreadsheetUrl'];
    return (id: id, url: url is String ? url : spreadsheetUrl(id));
  }

  Map<String, int> _sheetIds(Map<String, dynamic> spreadsheet) => {
    for (final s in spreadsheet['sheets'] as List? ?? const [])
      if (s is Map &&
          s['properties'] is Map &&
          (s['properties'] as Map)['title'] is String)
        (s['properties'] as Map)['title'] as String:
            ((s['properties'] as Map)['sheetId'] as num?)?.toInt() ?? 0,
  };

  Future<void> _fill(
    String token,
    String id,
    List<SheetTab> tabs,
    Map<String, int> sheetIds, {
    required bool clear,
  }) async {
    String range(String title) => "'${title.replaceAll("'", "''")}'";
    if (clear) {
      await _send(
        'POST',
        _sheets.resolve('spreadsheets/$id/values:batchClear'),
        token,
        body: {
          'ranges': [for (final t in tabs) range(t.title)],
        },
      );
    }
    await _send(
      'POST',
      _sheets.resolve('spreadsheets/$id/values:batchUpdate'),
      token,
      body: {
        'valueInputOption': 'RAW',
        'data': [
          for (final t in tabs)
            {
              'range': '${range(t.title)}!A1',
              'values': [
                for (final row in t.rows) [for (final v in row) v ?? ''],
              ],
            },
        ],
      },
    );
    await _batchUpdate(token, id, [
      for (final t in tabs)
        if (sheetIds[t.title] case final sheet?) ..._format(sheet, t),
    ]);
  }

  /// Formatting for one tab: bold headings, number formats, frozen header
  /// and column widths that fit the contents.
  List<Map<String, dynamic>> _format(int sheet, SheetTab t) {
    final columns = t.rows.fold<int>(0, (n, r) => r.length > n ? r.length : n);
    final end = t.rows.length;
    Map<String, dynamic> cells(
      int startRow,
      int endRow,
      Map<String, dynamic> format,
      String fields, {
      int? column,
    }) => {
      'repeatCell': {
        'range': {
          'sheetId': sheet,
          'startRowIndex': startRow,
          'endRowIndex': endRow,
          if (column != null) ...{
            'startColumnIndex': column,
            'endColumnIndex': column + 1,
          },
        },
        'cell': {'userEnteredFormat': format},
        'fields': 'userEnteredFormat($fields)',
      },
    };
    const bold = {
      'textFormat': {'bold': true},
    };
    return [
      {
        'updateCells': {
          'range': {'sheetId': sheet},
          'fields': 'userEnteredFormat',
        },
      },
      {
        'updateSheetProperties': {
          'properties': {
            'sheetId': sheet,
            'gridProperties': {'frozenRowCount': t.headerRow + 1},
          },
          'fields': 'gridProperties.frozenRowCount',
        },
      },
      cells(0, 1, {
        'textFormat': {'bold': true, 'fontSize': 14},
      }, 'textFormat'),
      cells(t.headerRow, t.headerRow + 1, {
        'textFormat': {'bold': true},
        'backgroundColor': {'red': 0.945, 'green': 0.933, 'blue': 0.914},
      }, 'textFormat,backgroundColor'),
      for (final c in t.moneyColumns)
        cells(
          t.headerRow + 1,
          end,
          {
            'numberFormat': {'type': 'NUMBER', 'pattern': '#,##0.00'},
          },
          'numberFormat',
          column: c,
        ),
      for (final c in t.quantityColumns)
        cells(
          t.headerRow + 1,
          end,
          {
            'numberFormat': {'type': 'NUMBER', 'pattern': '#,##0.###'},
          },
          'numberFormat',
          column: c,
        ),
      for (final r in t.boldRows) cells(r, r + 1, bold, 'textFormat'),
      {
        'autoResizeDimensions': {
          'dimensions': {
            'sheetId': sheet,
            'dimension': 'COLUMNS',
            'startIndex': 0,
            'endIndex': columns,
          },
        },
      },
    ];
  }

  Future<Map<String, dynamic>> _batchUpdate(
    String token,
    String id,
    List<Map<String, dynamic>> requests,
  ) => requests.isEmpty
      ? Future.value(const {})
      : _send(
          'POST',
          _sheets.resolve('spreadsheets/$id:batchUpdate'),
          token,
          body: {'requests': requests},
        );

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri,
    String token, {
    Object? body,
    ({String content, String type})? raw,
  }) async {
    final response = await _request(method, uri, token, body: body, raw: raw);
    if (response.body.isEmpty) return const {};
    final json = jsonDecode(response.body);
    return json is Map<String, dynamic> ? json : const {};
  }

  /// Sends a request with [body] as JSON, or [raw] as is, and returns the
  /// response when it succeeded.
  Future<http.Response> _request(
    String method,
    Uri uri,
    String token, {
    Object? body,
    ({String content, String type})? raw,
  }) async {
    final request = http.Request(method, uri)
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    } else if (raw != null) {
      request
        ..headers['Content-Type'] = raw.type
        ..body = raw.content;
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 30)),
      );
    } on TimeoutException {
      throw const GoogleSheetsException(GoogleSheetsFailure.offline);
    } catch (e) {
      throw GoogleSheetsException(GoogleSheetsFailure.offline, '$e');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    final detail = response.body;
    throw GoogleSheetsException(switch (response.statusCode) {
      401 => GoogleSheetsFailure.unauthorized,
      403
          when detail.contains('SERVICE_DISABLED') ||
              detail.contains('has not been used') =>
        GoogleSheetsFailure.apiDisabled,
      403 => GoogleSheetsFailure.forbidden,
      404 => GoogleSheetsFailure.notFound,
      429 => GoogleSheetsFailure.rateLimited,
      _ => GoogleSheetsFailure.failed,
    }, detail);
  }
}
