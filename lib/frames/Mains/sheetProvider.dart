import 'package:flutter/foundation.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SheetInfoProvider with ChangeNotifier {
  SheetInfo? _sheetInfo;

  SheetInfo? get sheetInfo => _sheetInfo;

  SheetInfoProvider() {
    // Load sheet info from shared preferences during initialization
    loadSheetInfo();
  }

  void setSheetInfo(String sheetId, String sheetName) {
    _sheetInfo = SheetInfo(sheetId, sheetName);
    saveSheetInfo();
    notifyListeners();
  }

  Future<void> saveSheetInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedSheetInfo = jsonEncode(_sheetInfo!.toJson());
    prefs.setString('sheetInfo', encodedSheetInfo);
  }

  Future<void> loadSheetInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedSheetInfo = prefs.getString('sheetInfo');

    if (savedSheetInfo != null) {
      final decodedSheetInfo = jsonDecode(savedSheetInfo);
      _sheetInfo = SheetInfo.fromJson(decodedSheetInfo);
      notifyListeners();
    }
  }
}
