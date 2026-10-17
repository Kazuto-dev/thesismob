import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/account.dart';
import '../../router.dart';
import '../../state/account_controller.dart';
import '../settings/plan_section.dart';

/// Whether [account]'s plan includes what [needed] sells. A build without
/// a server has no plans, so nothing in it is locked.
bool planIncludes(AccountController account, AppPlan needed) =>
    !account.isConfigured || account.plan.index >= needed.index;

/// Whether a feature of [needed] is locked for the user, for building the
/// lock icon. Rebuilds when the plan changes.
bool watchPlanLocked(BuildContext context, AppPlan needed) =>
    context.select<AccountController, bool>((a) => !planIncludes(a, needed));

/// Lets a tap on a feature of [needed] go ahead, or says which plan it is
/// part of and returns false.
bool unlockOrAsk(BuildContext context, AppPlan needed, String feature) {
  if (planIncludes(context.read<AccountController>(), needed)) return true;
  showPlanRequired(context, needed, feature);
  return false;
}

/// The lock shown on a feature of [plan] that the user's plan lacks.
class PlanLockIcon extends StatelessWidget {
  const PlanLockIcon(this.plan, {super.key, this.size = 18});

  final AppPlan plan;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.lock_outline,
    size: size,
    semanticLabel: context.tr('Needs {plan}', {'plan': plan.label}),
  );
}

/// A segment's [text] with a small lock after it, for segments too narrow
/// for an icon of their own.
class LockedLabel extends StatelessWidget {
  const LockedLabel(this.text, this.plan, {super.key});

  final String text;
  final AppPlan plan;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(text, softWrap: false, overflow: TextOverflow.fade)),
      const SizedBox(width: 4),
      PlanLockIcon(plan, size: 14),
    ],
  );
}

/// [child] with a small lock at its top right corner, for segments with
/// no room beside their label.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, required this.plan, required this.child});

  final AppPlan plan;
  final Widget child;

  @override
  Widget build(BuildContext context) => Badge(
    backgroundColor: Colors.transparent,
    textColor: IconTheme.of(context).color,
    padding: EdgeInsets.zero,
    offset: const Offset(8, -6),
    label: PlanLockIcon(plan, size: 12),
    child: child,
  );
}

/// Narrower padding for a row of segments that holds a [LockedLabel].
final lockedSegmentStyle = SegmentedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
);

/// Says that [feature] is part of [needed], with the way to get it: the
/// free trial or the Plan card for Business, the sales form for Enterprise.
Future<void> showPlanRequired(
  BuildContext context,
  AppPlan needed,
  String feature,
) async {
  final account = context.read<AccountController>();
  final status = account.status;
  final trial =
      needed == AppPlan.business &&
      status != null &&
      account.plan == AppPlan.free &&
      status.trialAvailable;
  final action = await showDialog<_Upgrade>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: Text(
          context.tr('{feature} is for {plan}', {
            'feature': context.tr(feature),
            'plan': needed.label,
          }),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                needed == AppPlan.enterprise
                    ? context.tr(
                        'Enterprise gives your whole team Business, with '
                        'shared projects, one company price book and roles.',
                      )
                    : context.tr(
                        'Business adds contractor and DPWH pricing, the '
                        'contract, Excel and Google Sheets exports and '
                        'revisions.',
                      ),
              ),
              const SizedBox(height: Space.md),
              Text(
                context.tr('Your plan: {plan}', {'plan': account.plan.label}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('Not now')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(switch (needed) {
              AppPlan.enterprise => _Upgrade.inquire,
              _ when trial => _Upgrade.trial,
              _ => _Upgrade.plans,
            }),
            child: Text(switch (needed) {
              AppPlan.enterprise => context.tr('Ask about Enterprise'),
              _ when trial => context.tr('Start {days}-day free trial', {
                'days': account.offer.trialDays,
              }),
              _ => context.tr('See plans'),
            }),
          ),
        ],
      );
    },
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _Upgrade.trial:
      final error = await account.startTrial();
      if (context.mounted) {
        showMessage(
          context,
          error ?? context.tr('Your Business trial has started.'),
        );
      }
    case _Upgrade.inquire:
      await askAboutEnterprise(context);
    case _Upgrade.plans:
      context.go(Routes.settings);
  }
}

enum _Upgrade { trial, inquire, plans }
