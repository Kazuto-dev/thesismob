import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Outcome of a Google Sheets export attempt.
enum SheetsExportStatus {
  success,
  notConfigured,
  missingSheetInfo,
  invalidInput,
  permissionDenied,
  notFound,
  network,
  server,
}

class SheetsExportResult {
  const SheetsExportResult(this.status, this.message);

  final SheetsExportStatus status;
  final String message;

  bool get isSuccess => status == SheetsExportStatus.success;
}

/// Appends rows to a Google Sheet through the server-side proxy in
/// `functions/sheets-proxy`.
///
/// The browser never holds Google credentials: the proxy runs as the service
/// account and only accepts "append these rows to this sheet" requests.
/// The proxy URL is supplied at build time:
///
///     flutter build web --dart-define=SHEETS_PROXY_URL=https://...
class SheetsExportService {
  SheetsExportService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      endpoint = endpoint ?? const String.fromEnvironment('SHEETS_PROXY_URL');

  /// Column headers written to an empty sheet. Unchanged from the original
  /// app so existing sheets keep lining up.
  static const header = ['Materials', 'Area(sqm)', 'Quantity', 'Cost(₱)'];

  /// The account users share their spreadsheet with. It is an identifier, not
  /// a secret.
  static const serviceAccountEmail = String.fromEnvironment(
    'SHEETS_SERVICE_ACCOUNT',
    defaultValue: 'flutter-test@qualified-tea-408701.iam.gserviceaccount.com',
  );

  static final _spreadsheetIdPattern = RegExp(r'^[A-Za-z0-9_-]{20,128}$');
  static final _spreadsheetUrlPattern = RegExp(
    r'/spreadsheets/d/([A-Za-z0-9_-]+)',
  );

  final http.Client _client;
  final String endpoint;

  bool get isConfigured => endpoint.isNotEmpty;

  /// Accepts either a bare spreadsheet ID or a full Google Sheets URL and
  /// returns the ID, or null when the input is neither.
  static String? normalizeSpreadsheetId(String input) {
    final trimmed = input.trim();
    final fromUrl = _spreadsheetUrlPattern.firstMatch(trimmed)?.group(1);
    final candidate = fromUrl ?? trimmed;
    return _spreadsheetIdPattern.hasMatch(candidate) ? candidate : null;
  }

  Future<SheetsExportResult> appendRows({
    required String spreadsheetId,
    required String sheetName,
    required List<List<Object?>> rows,
  }) async {
    if (!isConfigured) {
      return const SheetsExportResult(
        SheetsExportStatus.notConfigured,
        "Google Sheets export isn't set up for this build of the app.",
      );
    }
    final id = normalizeSpreadsheetId(spreadsheetId);
    if (id == null || sheetName.trim().isEmpty) {
      return const SheetsExportResult(
        SheetsExportStatus.missingSheetInfo,
        'Add your spreadsheet ID and sheet name in the Sheet tab first.',
      );
    }
    if (rows.isEmpty) {
      return const SheetsExportResult(
        SheetsExportStatus.invalidInput,
        'There is nothing to export yet.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'spreadsheetId': id,
              'sheetName': sheetName.trim(),
              'header': header,
              'rows': rows,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      return const SheetsExportResult(
        SheetsExportStatus.network,
        'The export service took too long to answer. Try again.',
      );
    } catch (_) {
      return const SheetsExportResult(
        SheetsExportStatus.network,
        "Couldn't reach the export service. Check your connection.",
      );
    }

    switch (response.statusCode) {
      case 200:
        final count = rows.length;
        return SheetsExportResult(
          SheetsExportStatus.success,
          count == 1
              ? 'Added 1 row to "$sheetName".'
              : 'Added $count rows to "$sheetName".',
        );
      case 400:
        return SheetsExportResult(
          SheetsExportStatus.invalidInput,
          _serverMessage(response) ?? 'The export request was rejected.',
        );
      case 403:
        return const SheetsExportResult(
          SheetsExportStatus.permissionDenied,
          'The app can\'t edit that spreadsheet. Share it with '
          '$serviceAccountEmail as an Editor.',
        );
      case 404:
        return SheetsExportResult(
          SheetsExportStatus.notFound,
          _serverMessage(response) ??
              'Spreadsheet or sheet "$sheetName" was not found.',
        );
      default:
        return const SheetsExportResult(
          SheetsExportStatus.server,
          'Google Sheets export failed. Try again later.',
        );
    }
  }

  String? _serverMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String)
        return body['error'] as String;
    } catch (_) {}
    return null;
  }
}
