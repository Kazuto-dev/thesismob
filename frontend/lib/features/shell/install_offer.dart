import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_install.dart';
import '../../state/install_controller.dart';

/// Offers to install BuildQuantify on the phone's home screen by itself,
/// once the app has been open a moment: on iPhone with the steps from the
/// Share menu, on Android with Chrome's own install dialog as soon as
/// Chrome allows it (or the menu steps if it has not after half a minute).
class InstallOffer extends StatefulWidget {
  const InstallOffer({super.key, required this.child});

  final Widget child;

  @override
  State<InstallOffer> createState() => _InstallOfferState();
}

class _InstallOfferState extends State<InstallOffer> {
  static const _settle = Duration(seconds: 4);
  static const _waitForChrome = Duration(seconds: 30);

  late final InstallController _install = context.read<InstallController>();
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!_install.shouldOffer) return;
    final waitForChrome =
        _install.platform == InstallPlatform.android &&
        !_install.canInstall &&
        !_install.inAppBrowser;
    _timer = Timer(waitForChrome ? _waitForChrome : _settle, _show);
    _install.addListener(_changed);
  }

  /// Chrome is ready to install: offer it soon, with one-tap install.
  void _changed() {
    if (_install.canInstall && !_shown) {
      _timer?.cancel();
      _timer = Timer(_settle, _show);
    }
  }

  void _show() {
    _install.removeListener(_changed);
    if (!mounted || _shown || !_install.shouldOffer) return;
    _shown = true;
    unawaited(showInstallSheet(context));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _install.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The install sheet: Chrome's install button where it can, otherwise the
/// steps for this phone. Closing it without installing puts the offer off
/// for a week.
Future<void> showInstallSheet(BuildContext context) async {
  final install = context.read<InstallController>();
  final installed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: install,
      child: const _InstallSheet(),
    ),
  );
  if (!context.mounted) return;
  if (installed == true) {
    showMessage(
      context,
      context.tr('BuildQuantify is installed. Open it from your home screen.'),
    );
  } else {
    install.dismiss();
  }
}

class _InstallSheet extends StatelessWidget {
  const _InstallSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final install = context.watch<InstallController>();
    final oneTap =
        install.platform == InstallPlatform.android &&
        install.canInstall &&
        !install.inAppBrowser;
    final steps = install.inAppBrowser
        ? const [
            (
              Icons.more_horiz,
              'Open the menu of the app you are in, at the top or bottom '
                  'of the screen.',
            ),
            (
              Icons.open_in_browser,
              'Choose Open in browser, Open in Chrome or Open in Safari.',
            ),
            (Icons.install_mobile, 'Install BuildQuantify from there.'),
          ]
        : install.platform == InstallPlatform.ios
        ? const [
            (
              Icons.ios_share,
              'Tap Share in Safari\'s toolbar. In Chrome, Share is at the '
                  'top right.',
            ),
            (
              Icons.add_box_outlined,
              'Scroll down and choose Add to Home Screen.',
            ),
            (
              Icons.check_circle_outline,
              'Tap Add. BuildQuantify is then on your home screen.',
            ),
          ]
        : oneTap
        ? const <(IconData, String)>[]
        : const [
            (Icons.more_vert, 'Tap the menu at the top right of Chrome.'),
            (
              Icons.install_mobile,
              'Choose Install app, or Add to Home screen.',
            ),
          ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const BrandMark(size: 48),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr('Install BuildQuantify'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(
              context.tr(
                install.inAppBrowser
                    ? 'This page is open inside another app, such as '
                          'Facebook or Messenger, which cannot install apps.'
                    : 'Add it to your home screen. It opens full screen like '
                          'an app and works without a connection, no browser '
                          'needed.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final (i, (icon, text)) in steps.indexed) ...[
              SizedBox(height: i == 0 ? Space.lg : Space.md),
              Row(
                children: [
                  IconTile(icon: icon, size: 40),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      '${i + 1}. ${context.tr(text)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.xl),
            if (oneTap)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr('Not now')),
                  ),
                  const SizedBox(width: Space.sm),
                  FilledButton.icon(
                    onPressed: () async {
                      final installed = await install.install();
                      if (context.mounted) {
                        Navigator.of(context).pop(installed);
                      }
                    },
                    icon: const Icon(Icons.install_mobile),
                    label: Text(context.tr('Install')),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.tr('Got it')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
