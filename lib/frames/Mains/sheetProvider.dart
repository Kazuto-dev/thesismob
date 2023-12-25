// ignore_for_file: file_names, unused_import

import 'package:flutter/material.dart';
import 'sheetInfo.dart';

class SheetInfoProvider with ChangeNotifier {
  SheetInfo? _sheetInfo;

  SheetInfo? get sheetInfo => _sheetInfo;

  get sheetIdController => null;

  get sheetNameController => null;

  void setSheetInfo(String sheetId, String sheetName) {
    _sheetInfo = SheetInfo(sheetId, sheetName);
    notifyListeners();
  }
}
