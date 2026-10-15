import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/google_account_controller.dart';
import '../common/google_button.dart';

const _features = [
  (
    Icons.calculate_outlined,
    '40 calculators, from earthworks and rebar to wiring and plumbing',
  ),
  (
    Icons.sell_outlined,
    'Every material priced from a 2026 Philippine price book',
  ),
  (
    Icons.request_quote_outlined,
    'Projects with a bill of quantities, a budget, PDF and Google Sheets',
  ),
];

/// The first screen: sign in with Google to save projects to Google
/// Sheets, or carry on without an account. The router leaves this screen
/// on its own once either happens.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = WindowSize.of(context) == WindowSize.expanded;
    return PageTitle(
      title: context.tr('Sign in'),
      child: Scaffold(
        body: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    flex: 11,
                    child: InkPanel(
                      borderRadius: BorderRadius.zero,
                      padding: EdgeInsets.all(Space.xxxl),
                      child: _Intro(wide: true),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Space.xxl),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: const _SignIn(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkPanel(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(Radii.xl),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        gutterOf(context),
                        MediaQuery.paddingOf(context).top + Space.xl,
                        gutterOf(context),
                        Space.xxl,
                      ),
                      child: const _Intro(wide: false),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            gutterOf(context),
                            Space.xl,
                            gutterOf(context),
                            Space.xxl,
                          ),
                          child: const _SignIn(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The brand, a headline and what the app does, on the dark panel.
class _Intro extends StatelessWidget {
  const _Intro({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final brand = Row(
      children: [
        BrandMark(size: wide ? 44 : 36),
        const SizedBox(width: Space.md),
        Text(
          context.tr('BuildQuantify'),
          style: theme.textTheme.titleLarge?.copyWith(
            color: palette.onInk,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
    final headline = Semantics(
      header: true,
      child: Text(
        context.tr('Estimate every material.\nPrice every job.'),
        style:
            (wide
                    ? theme.textTheme.displaySmall
                    : theme.textTheme.headlineSmall)
                ?.copyWith(color: palette.onInk, fontWeight: FontWeight.w800),
      ),
    );
    final lede = Text(
      context.tr(
        'Quantities and costs for Philippine construction, from a single wall '
        'to a contractor\'s bid.',
      ),
      style: theme.textTheme.bodyLarge?.copyWith(color: palette.onInkMuted),
    );
    final features = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, text) in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.brand.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.sm),
                    child: Icon(icon, size: 20, color: palette.inkAccent),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    context.tr(text),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.onInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          brand,
          const SizedBox(height: Space.xl),
          headline,
          const SizedBox(height: Space.sm),
          lede,
          const SizedBox(height: Space.xl),
          features,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        brand,
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headline,
              const SizedBox(height: Space.lg),
              lede,
              const SizedBox(height: Space.xxl),
              features,
            ],
          ),
        ),
        const Spacer(),
        Text(
          context.tr(
            'Planning estimates. Confirm quantities and prices with your '
            'engineer and supplier before buying.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: palette.onInkMuted),
        ),
      ],
    );
  }
}

/// Sign in with Google, or continue without an account.
class _SignIn extends StatefulWidget {
  const _SignIn();

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  String? _error;

  Future<void> _signIn() async {
    setState(() => _error = null);
    // Called straight from the tap, so Google's window may open.
    final result = await context.read<GoogleAccountController>().signIn();
    if (mounted && !result.ok) setState(() => _error = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final google = context.watch<GoogleAccountController>();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.tr('Welcome'),
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          context.tr(
            'Sign in with Google to save your projects as spreadsheets in your '
            'own Google Drive.',
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.xl),
        GoogleSignInButton(busy: google.isBusy, onPressed: _signIn),
        if (_error != null) ...[
          const SizedBox(height: Space.md),
          Semantics(
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Text(context.tr('or'), style: muted),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: Space.lg),
        OutlinedButton(
          onPressed: google.isBusy
              ? null
              : () => context.read<GoogleAccountController>().skipSignIn(),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(context.tr('Continue without signing in')),
        ),
        const SizedBox(height: Space.xl),
        Text(
          context.tr(
            'BuildQuantify can only open the spreadsheets it creates. Your '
            'projects stay in this browser, and you can sign in later from '
            'Settings.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
