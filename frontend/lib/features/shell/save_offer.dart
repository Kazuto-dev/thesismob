import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../state/account_controller.dart';
import '../../state/google_account_controller.dart';
import '../settings/plan_section.dart';

/// Asks, above every screen, to turn on saving to the account when the
/// user is signed in with Google but not to their BuildQuantify account,
/// as after signing in with an earlier version. One tap signs in; Google
/// may need the tap to open its window.
class SaveOffer extends StatefulWidget {
  const SaveOffer({super.key, required this.child});

  final Widget child;

  @override
  State<SaveOffer> createState() => _SaveOfferState();
}

class _SaveOfferState extends State<SaveOffer> {
  bool _later = false;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountController>();
    final google = context.watch<GoogleAccountController>();
    final show =
        !_later &&
        account.isConfigured &&
        account.offer.signInEnabled &&
        google.isConfigured &&
        google.isSignedIn &&
        !account.isSignedIn;
    if (!show) return widget.child;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Material(
          color: scheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.sm,
                Space.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Turn on saving to your account, so your projects '
                        'and prices are kept safe on every device.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _later = true),
                    child: Text(context.tr('Not now')),
                  ),
                  FilledButton(
                    onPressed: account.isBusy || google.isBusy
                        ? null
                        : () => signInToAccount(context),
                    child: Text(context.tr('Turn on')),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
