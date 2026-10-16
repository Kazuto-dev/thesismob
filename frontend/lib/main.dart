import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'materials/catalog.dart';
import 'materials/material_spec.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/jakarta/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans font'], license);
  });
  // Saved estimates load once here, so screens never show a fake splash.
  final prefs = await SharedPreferences.getInstance();
  runApp(BuildQuantifyApp(prefs: prefs));
  if (kIsWeb) _warmUpAssets();
}

/// Loads every icon once in the background, so the offline cache has them
/// all before the user opens a calculator without a connection.
void _warmUpAssets() {
  Future<void>.delayed(const Duration(seconds: 3), () async {
    final paths = {
      for (final m in allMaterials) ?m.image,
      for (final c in MaterialCategory.values)
        'assets/images/categories/${c.name}.png',
      'assets/images/brand/house.png',
      'assets/images/brand/google_g.png',
    };
    for (final path in paths) {
      try {
        await rootBundle.load(path);
      } catch (_) {
        // Offline already, or the asset is missing: nothing to warm up.
      }
    }
  });
}
