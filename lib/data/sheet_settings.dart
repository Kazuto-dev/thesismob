import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where estimates are exported: a spreadsheet and the tab inside it.
@immutable
class SheetSettings {
  const SheetSettings({required this.spreadsheetId, required this.sheetName});

  final String spreadsheetId;
  final String sheetName;
}

/// Stores [SheetSettings] under the key and JSON shape the original app used
/// (`sheetInfo` → `{sheetId, sheetName}`), so existing settings carry over.
class SheetSettingsRepository {
  SheetSettingsRepository(this._prefs);

  static const key = 'sheetInfo';

  final SharedPreferences _prefs;

  SheetSettings? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map &&
          json['sheetId'] is String &&
          json['sheetName'] is String) {
        return SheetSettings(
          spreadsheetId: json['sheetId'] as String,
          sheetName: json['sheetName'] as String,
        );
      }
    } on FormatException {
      // Fall through: unreadable settings are treated as not set.
    }
    return null;
  }

  Future<void> save(SheetSettings settings) => _prefs.setString(
    key,
    jsonEncode({
      'sheetId': settings.spreadsheetId,
      'sheetName': settings.sheetName,
    }),
  );

  Future<void> clear() => _prefs.remove(key);
}
