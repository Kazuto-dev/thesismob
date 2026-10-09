import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/poppins/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Poppins font'], license);
  });
  // Saved estimates load once here, so screens never show a fake splash.
  final prefs = await SharedPreferences.getInstance();
  runApp(BuildQuantifyApp(prefs: prefs));
}
