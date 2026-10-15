import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/login_screen.dart';
import 'features/calculator/calculator_screen.dart';
import 'features/category/category_screen.dart';
import 'features/help/help_screen.dart';
import 'features/history/history_screen.dart';
import 'features/not_found_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/settings/settings_screen.dart';
import 'features/projects/project_screen.dart';
import 'features/projects/projects_screen.dart';
import 'features/settings/price_book_screen.dart';
import 'features/home/home_screen.dart';
import 'materials/catalog.dart';
import 'materials/material_spec.dart';
import 'state/google_account_controller.dart';

/// Locations the original app used, so old bookmarks still land somewhere
/// sensible.
const _legacyRedirects = {
  '/mainpage': '/',
  '/instructions': '/settings/help',
  '/help': '/settings/help',
  '/sheetform': '/settings',
  '/sheet': '/settings',
  '/history': '/history',
  '/summary': '/project',
  '/strucPages': '/category/structural',
  '/struc': '/category/structural',
  '/archPages': '/category/architectural',
  '/arch': '/category/architectural',
  '/elecPages': '/category/electrical',
  '/elec': '/category/electrical',
  '/plumbPages': '/category/plumbing',
  '/plumb': '/category/plumbing',
  '/CHBpages': '/material/chb',
  '/chb': '/material/chb',
  '/plywoodPages': '/material/plywood',
  '/plywood': '/material/plywood',
  '/insulationPages': '/material/insulation',
  '/insulation': '/material/insulation',
  '/paintPages': '/material/paint',
  '/paint': '/material/paint',
  '/tilesPages': '/material/tiles',
  '/tiles': '/material/tiles',
  '/roofPages': '/material/roof',
  '/roof': '/material/roof',
  '/carpetPages': '/material/carpet',
  '/carpet': '/material/carpet',
  '/wallpaperPages': '/material/wallpaper',
  '/wallpaper': '/material/wallpaper',
  '/bulbPages': '/material/bulb',
  '/bulb': '/material/bulb',
  '/switchPages': '/material/switch',
  '/switch': '/material/switch',
  '/cbPages': '/material/junction_box',
  '/cb': '/material/junction_box',
  '/socketPages': '/material/outlet',
  '/socket': '/material/outlet',
  '/wiresPages': '/material/wires',
  '/wires': '/material/wires',
  '/boxPages': '/material/utility_box',
  '/box': '/material/utility_box',
  '/pvcPages': '/material/pvc',
  '/pvc': '/material/pvc',
  '/sinkPages': '/material/sink',
  '/sink': '/material/sink',
  '/toiletPages': '/material/toilet',
  '/toilet': '/material/toilet',
  '/faucetPages': '/material/faucet',
  '/faucet': '/material/faucet',
  '/showerPages': '/material/shower',
  '/shower': '/material/shower',
};

/// Route paths, so screens never build location strings by hand.
abstract final class Routes {
  static const home = '/';
  static const history = '/history';
  static const project = '/project';
  static const projects = '/project/all';
  static const settings = '/settings';
  static const help = '/settings/help';
  static const prices = '/settings/prices';
  static const login = '/login';

  static String projectById(String id) => '/project/$id';

  static String category(MaterialCategory c) => '/category/${c.name}';

  /// A calculator. With [fromEstimate], the form starts from that saved
  /// estimate; with [inProject] too, it edits that project's item.
  static String material(
    MaterialSpec m, {
    String? fromEstimate,
    String? inProject,
  }) {
    final query = {
      'estimate': ?fromEstimate,
      if (fromEstimate != null) 'project': ?inProject,
    };
    return Uri(
      path: '/category/${m.category.name}/${m.id}',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// Where a link really leads: old bookmarks and short material links
/// resolve to today's paths.
String _resolve(Uri uri) {
  final path = uri.path;
  final target = _legacyRedirects[path] ?? path;
  if (target.startsWith('/material/')) {
    final spec = materialById(target.substring('/material/'.length));
    return spec == null ? target : Routes.material(spec);
  }
  return target == path ? uri.toString() : target;
}

/// Only paths inside the app, so a crafted link cannot send users away.
String _safeReturn(String? from) =>
    from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.startsWith(Routes.login)
    ? from
    : Routes.home;

/// The app's routes. With [account], the login screen comes first until
/// the user signs in with Google or chooses to continue without it, then
/// they land where they were going.
GoRouter createRouter({
  String initialLocation = Routes.home,
  GoogleAccountController? account,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: account,
  redirect: (context, state) {
    // Resolve in one step: chained redirects are not re-run.
    final current = state.uri.toString();
    if (state.uri.path == Routes.login) {
      return account == null || account.needsSignIn
          ? null
          : _safeReturn(state.uri.queryParameters['from']);
    }
    final target = _resolve(state.uri);
    if (account != null && account.needsSignIn) {
      return target == Routes.home
          ? Routes.login
          : Uri(
              path: Routes.login,
              queryParameters: {'from': target},
            ).toString();
    }
    return target == current ? null : target;
  },
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'category/:category',
                  builder: (context, state) {
                    final c = MaterialCategory.byId(
                      state.pathParameters['category']!,
                    );
                    return c == null
                        ? const NotFoundScreen()
                        : CategoryScreen(category: c);
                  },
                  routes: [
                    GoRoute(
                      path: ':material',
                      builder: (context, state) {
                        final spec = materialById(
                          state.pathParameters['material']!,
                        );
                        if (spec == null ||
                            spec.category.name !=
                                state.pathParameters['category']) {
                          return const NotFoundScreen();
                        }
                        return CalculatorScreen(
                          key: ValueKey(state.uri.toString()),
                          spec: spec,
                          fromEstimateId: state.uri.queryParameters['estimate'],
                          editProjectId: state.uri.queryParameters['project'],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.history,
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.project,
              builder: (context, state) => const ProjectScreen(),
              routes: [
                GoRoute(
                  path: 'all',
                  builder: (context, state) => const ProjectsScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      ProjectScreen(projectId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'help',
                  builder: (context, state) => const HelpScreen(),
                ),
                GoRoute(
                  path: 'prices',
                  builder: (context, state) => const PriceBookScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
