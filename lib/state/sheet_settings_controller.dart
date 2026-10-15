import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/estimate.dart';
import '../data/sheet_settings.dart';
import '../data/sheets_export_service.dart';

/// Holds the user's Google Sheets destination and exports estimates to it.
class SheetSettingsController extends ChangeNotifier {
  SheetSettingsController(this._repository, this._exporter)
    : _settings = _repository.load();

  final SheetSettingsRepository _repository;
  final SheetsExportService _exporter;
  SheetSettings? _settings;
  bool _exporting = false;

  SheetSettings? get settings => _settings;

  bool get isExportAvailable => _exporter.isConfigured;

  bool get isExporting => _exporting;

  String get serviceAccountEmail => SheetsExportService.serviceAccountEmail;

  /// Saves the destination. [spreadsheet] may be an ID or a full sheet URL.
  /// Returns an error message, or null on success.
  String? save({required String spreadsheet, required String sheetName}) {
    final id = SheetsExportService.normalizeSpreadsheetId(spreadsheet);
    if (id == null) return 'That does not look like a spreadsheet ID or link.';
    if (sheetName.trim().isEmpty) return 'Enter the name of the sheet tab.';
    _settings = SheetSettings(spreadsheetId: id, sheetName: sheetName.trim());
    unawaited(_repository.save(_settings!));
    notifyListeners();
    return null;
  }

  void clear() {
    _settings = null;
    unawaited(_repository.clear());
    notifyListeners();
  }

  /// Appends [estimates] to the configured sheet.
  Future<SheetsExportResult> export(List<Estimate> estimates) async {
    final settings = _settings;
    if (!_exporter.isConfigured) {
      return _exporter.appendRows(
        spreadsheetId: '',
        sheetName: '',
        rows: const [],
      );
    }
    if (settings == null) {
      return const SheetsExportResult(
        SheetsExportStatus.missingSheetInfo,
        'Add your spreadsheet in Settings first.',
      );
    }
    _exporting = true;
    notifyListeners();
    try {
      final rows = [for (final e in estimates) ...e.toSheetRows()];
      // The proxy takes at most 200 rows a request.
      var result = await _exporter.appendRows(
        spreadsheetId: settings.spreadsheetId,
        sheetName: settings.sheetName,
        rows: rows.take(SheetsExportService.maxRows).toList(),
      );
      for (
        var start = SheetsExportService.maxRows;
        start < rows.length && result.status == SheetsExportStatus.success;
        start += SheetsExportService.maxRows
      ) {
        result = await _exporter.appendRows(
          spreadsheetId: settings.spreadsheetId,
          sheetName: settings.sheetName,
          rows: rows.skip(start).take(SheetsExportService.maxRows).toList(),
        );
      }
      if (result.status == SheetsExportStatus.success &&
          rows.length > SheetsExportService.maxRows) {
        return SheetsExportResult(
          SheetsExportStatus.success,
          'Added ${rows.length} rows to "${settings.sheetName}".',
        );
      }
      return result;
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }
}
