import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/estimate_repository.dart';
import 'data/sheet_settings.dart';
import 'data/sheets_export_service.dart';
import 'router.dart';
import 'state/estimates_controller.dart';
import 'state/sheet_settings_controller.dart';

class BuildQuantifyApp extends StatefulWidget {
  const BuildQuantifyApp({
    super.key,
    required this.prefs,
    this.exporter,
    this.initialLocation = Routes.home,
  });

  final SharedPreferences prefs;

  /// Overridable for tests; defaults to the proxy from the build config.
  final SheetsExportService? exporter;
  final String initialLocation;

  @override
  State<BuildQuantifyApp> createState() => _BuildQuantifyAppState();
}

class _BuildQuantifyAppState extends State<BuildQuantifyApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EstimatesController(EstimateRepository(widget.prefs)),
        ),
        ChangeNotifierProvider(
          create: (_) => SheetSettingsController(
            SheetSettingsRepository(widget.prefs),
            widget.exporter ?? SheetsExportService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'BuildQuantify',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
      ),
    );
  }
}
