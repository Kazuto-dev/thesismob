import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/i18n.dart';
import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/app_install.dart';
import 'data/estimate_repository.dart';
import 'data/google_auth.dart';
import 'data/google_sheets_client.dart';
import 'router.dart';
import 'data/project_repository.dart';
import 'export/project_documents.dart';
import 'state/account_controller.dart';
import 'state/appearance_controller.dart';
import 'state/cloud_sync.dart';
import 'state/estimates_controller.dart';
import 'state/install_controller.dart';
import 'state/price_book_controller.dart';
import 'state/profile_controller.dart';
import 'state/projects_controller.dart';
import 'state/tips_controller.dart';
import 'state/google_account_controller.dart';

class BuildQuantifyApp extends StatefulWidget {
  const BuildQuantifyApp({
    super.key,
    required this.prefs,
    this.googleAuth,
    this.sheetsClient,
    this.apiClient,
    this.appInstaller,
    this.initialLocation = Routes.home,
  });

  final SharedPreferences prefs;

  /// Overridable for tests; default to Google sign-in with the client ID
  /// from the build config, and Google's APIs.
  final GoogleAuth? googleAuth;
  final GoogleSheetsClient? sheetsClient;

  /// The BuildQuantify server; by default the one set at build time.
  final ApiClient? apiClient;

  /// Installing on the home screen; by default what the browser offers.
  final AppInstaller? appInstaller;
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
  late final _profile = ProfileController(widget.prefs);
  late final _api = widget.apiClient ?? ApiClient();
  late final _account = AccountController(widget.prefs, _api);

  /// Keeps the signed-in account's data in the server's database.
  late final _sync = CloudSync(
    prefs: widget.prefs,
    api: _api,
    account: _account,
    projects: _projects,
    prices: _prices,
    history: _estimates,
    profile: _profile,
  );
  late bool _wasSignedInToGoogle = _google.isSignedIn;
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
    _google.addListener(_googleChanged);
    _sync; // Starts syncing when an account is signed in.
    unawaited(_account.refresh());
  }

  /// Signing out of Google signs out of the account it signed in to. The
  /// account's data stays on the server.
  void _googleChanged() {
    final signedIn = _google.isSignedIn;
    if (_wasSignedInToGoogle && !signedIn && _account.isSignedIn) {
      unawaited(_account.signOut());
    }
    _wasSignedInToGoogle = signedIn;
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
            quotes: _prices.quotes,
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
    _google.removeListener(_googleChanged);
    _sync.dispose();
    _router.dispose();
    _google.dispose();
    _estimates.dispose();
    _projects.dispose();
    _prices.dispose();
    _account.dispose();
    _profile.dispose();
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
        ChangeNotifierProvider.value(value: _profile),
        ChangeNotifierProvider.value(value: _google),
        ChangeNotifierProvider.value(value: _account),
        ChangeNotifierProvider.value(value: _sync),
        ChangeNotifierProvider(
          create: (_) => InstallController(
            widget.prefs,
            widget.appInstaller ?? createAppInstaller(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'BuildQuantify',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: context.watch<AppearanceController>().mode,
          routerConfig: _router,
          builder: (context, child) => AppLanguageScope(
            language: context.watch<AppearanceController>().language,
            child: child!,
          ),
        ),
      ),
    );
  }
}
