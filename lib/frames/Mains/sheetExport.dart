import 'package:flutter/material.dart';
import 'package:thesismob/data/sheets_export_service.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';

final _service = SheetsExportService();

/// Sends one calculator result to the user's sheet through the export proxy
/// and reports the outcome in a snackbar.
Future<void> exportRowToSheet(
  BuildContext context,
  SheetInfo? sheetInfo,
  List<Object?> row,
) async {
  final result = await _service.appendRows(
    spreadsheetId: sheetInfo?.sheetId ?? '',
    sheetName: sheetInfo?.sheetName ?? '',
    rows: [row],
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(result.message)));
}
