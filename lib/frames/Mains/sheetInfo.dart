// ignore_for_file: file_names, unused_import

import 'package:flutter/material.dart';

// sheet_info.dart
class SheetInfo {
  final String sheetId;
  final String sheetName;

  SheetInfo(this.sheetId, this.sheetName);

  Map<String, dynamic> toJson() {
    return {
      'sheetId': sheetId,
      'sheetName': sheetName,
    };
  }

  factory SheetInfo.fromJson(Map<String, dynamic> json) {
    return SheetInfo(
      json['sheetId'],
      json['sheetName'],
    );
  }
}
