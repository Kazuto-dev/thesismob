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
import 'state/appearance_controller.dart';
import 'state/estimates_controller.dart';
import 'state/price_book_controller.dart';
import 'state/projects_controller.dart';
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
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );
  final _light = buildTheme();
  final _dark = buildTheme(Brightness.dark);

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
          create: (_) => ProjectsController(ProjectRepository(widget.prefs)),
        ),
        ChangeNotifierProvider(
          create: (_) => PriceBookController(widget.prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => AppearanceController(widget.prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => GoogleAccountController(
            widget.prefs,
            widget.googleAuth ?? GoogleSignInAuth(),
            widget.sheetsClient ?? GoogleSheetsClient(),
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
        ),
      ),
    );
  }
}
