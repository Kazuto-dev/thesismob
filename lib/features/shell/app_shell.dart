import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Estimate', Icons.calculate_outlined, Icons.calculate),
  _Destination('History', Icons.history, Icons.history),
  _Destination('Summary', Icons.receipt_long_outlined, Icons.receipt_long),
  _Destination('Settings', Icons.settings_outlined, Icons.settings),
];

/// Top-level layout: a bottom navigation bar on phones, a labelled rail on
/// tablets and an extended rail with the project total on desktops. Each
/// tab keeps its own navigation state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = context.select<EstimatesController, int>(
      (c) => c.summary.length,
    );

    Widget icon(_Destination d, IconData data) => d.label == 'Summary'
        ? Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: Icon(data),
          )
        : Icon(data);

    if (size == WindowSize.compact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: icon(d, d.icon),
                  selectedIcon: icon(d, d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = size == WindowSize.expanded;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            extended: extended,
            labelType: extended ? null : NavigationRailLabelType.all,
            minExtendedWidth: 248,
            groupAlignment: -1,
            trailingAtBottom: true,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(
                extended ? Space.lg : 0,
                Space.lg,
                extended ? Space.lg : 0,
                Space.xl,
              ),
              child: extended
                  ? const BrandLockup(size: 36)
                  : const BrandMark(size: 40),
            ),
            trailing: extended
                ? const Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: SizedBox(width: 216, child: _ProjectTotal()),
                  )
                : null,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: icon(d, d.icon),
                  selectedIcon: icon(d, d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

/// The running summary total at the foot of the desktop rail.
class _ProjectTotal extends StatelessWidget {
  const _ProjectTotal();

  @override
  Widget build(BuildContext context) {
    final (count, total) = context.select<EstimatesController, (int, double)>(
      (c) => (c.summary.length, c.summaryTotal),
    );
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Project total ${formatMoney(total)}, $count items. Open summary',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () => context.go(Routes.summary),
          child: InkPanel(
            padding: const EdgeInsets.all(Space.lg),
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppPalette.of(context).onInkMuted,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  formatMoney(total),
                  style: tabular(
                    theme.textTheme.titleLarge?.copyWith(
                      color: AppPalette.of(context).inkAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  count == 1 ? '1 item' : '$count items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.of(context).onInkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
