import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/estimate_repository.dart';
import 'data/google_auth.dart';
import 'data/google_sheets_client.dart';
import 'router.dart';
import 'data/project_repository.dart';
import 'export/project_documents.dart';
import 'state/appearance_controller.dart';
import 'state/estimates_controller.dart';
import 'state/price_book_controller.dart';
import 'state/projects_controller.dart';
import 'state/tips_controller.dart';
import 'state/google_account_controller.dart';

class BuildQuantifyApp extends StatefulWidget {
  const BuildQuantifyApp({
    super.key,
    required this.prefs,
    this.googleAuth,
    this.sheetsClient,
    this.initialLocation = Routes.home,
  });

  final SharedPreferences prefs;

  /// Overridable for tests; default to Google sign-in with the client ID
  /// from the build config, and Google's APIs.
  final GoogleAuth? googleAuth;
  final GoogleSheetsClient? sheetsClient;
  final String initialLocation;

  @override
  State<BuildQuantifyApp> createState() => _BuildQuantifyAppState();
}

class _BuildQuantifyAppState extends State<BuildQuantifyApp> {
  late final _google = GoogleAccountController(
    widget.prefs,
    widget.googleAuth ?? GoogleSignInAuth(),
    widget.sheetsClient ?? GoogleSheetsClient(),
  );
  late final _estimates = EstimatesController(EstimateRepository(widget.prefs));
  late final _projects = ProjectsController(ProjectRepository(widget.prefs));
  late final _prices = PriceBookController(widget.prefs);
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
    account: _google,
  );
  final _light = buildTheme();
  final _dark = buildTheme(Brightness.dark);
  Timer? _backupTimer;

  @override
  void initState() {
    super.initState();
    _projects.addListener(_scheduleBackup);
    _prices.addListener(_scheduleBackup);
  }

  /// Backs up to Google Drive a little after the user stops changing
  /// things, when automatic backups are on.
  void _scheduleBackup() {
    if (!_google.autoBackup) return;
    _backupTimer?.cancel();
    _backupTimer = Timer(const Duration(seconds: 20), () {
      unawaited(
        _google.autoBackUp(
          backupJson(
            projects: _projects.projects,
            prices: _prices.custom,
            history: _estimates.history,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _backupTimer?.cancel();
    _projects.removeListener(_scheduleBackup);
    _prices.removeListener(_scheduleBackup);
    _router.dispose();
    _google.dispose();
    _estimates.dispose();
    _projects.dispose();
    _prices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _estimates),
        ChangeNotifierProvider.value(value: _projects),
        ChangeNotifierProvider.value(value: _prices),
        ChangeNotifierProvider(
          create: (_) => AppearanceController(widget.prefs),
        ),
        ChangeNotifierProvider(create: (_) => TipsController(widget.prefs)),
        ChangeNotifierProvider.value(value: _google),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'BuildQuantify',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: context.watch<AppearanceController>().mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
