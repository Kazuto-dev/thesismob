import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/account.dart';
import '../../state/account_controller.dart';
import '../../state/google_account_controller.dart';

String _date(DateTime d) => DateFormat('MMM d, y', 'en_US').format(d.toLocal());

String _money(int usd, int php) =>
    '\$$usd (₱${NumberFormat('#,##0').format(php)})';

/// The user's plan: what they have, a free trial, a code from an email,
/// the plans compared and a way to ask about Enterprise. Shown only when
/// the app was built with a server address.
class PlanSection extends StatelessWidget {
  const PlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountController>();
    if (!account.isConfigured) return const SizedBox.shrink();
    final google = context.watch<GoogleAccountController>();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final status = account.status;
    final plan = account.plan;
    final offer = account.offer;
    final now = account.now();

    final String detail;
    if (status == null) {
      detail = context.tr(
        'Sign in to start a {days}-day free trial of Business or to enter a '
        'code from your email.',
        {'days': offer.trialDays},
      );
    } else if (plan == AppPlan.enterprise) {
      detail = context.tr('Through {org} as {role}, until {date}.', {
        'org': status.organization ?? '',
        'role': context.tr(status.orgRole ?? 'member'),
        'date': _date(status.paidUntil!),
      });
    } else if (plan == AppPlan.business && status.onTrial) {
      detail = context.tr('Free trial: {n} days left.', {
        'n': status.trialDaysLeft(now),
      });
    } else if (plan == AppPlan.business) {
      detail = now.isAfter(status.paidUntil!)
          ? context.tr(
              'Ended {date}. It keeps working a few more days: enter your '
              'renewal code.',
              {'date': _date(status.paidUntil!)},
            )
          : context.tr('Paid until {date}.', {
              'date': _date(status.paidUntil!),
            });
    } else if (status.trialAvailable) {
      detail = context.tr(
        '{n} projects in the cloud. Try Business free for {days} days.',
        {'n': offer.freeProjects, 'days': offer.trialDays},
      );
    } else {
      detail = context.tr(
        '{n} projects in the cloud. Enter a code to use Business.',
        {'n': offer.freeProjects},
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconTile(
                  icon: Icons.workspace_premium_outlined,
                  size: 40,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr('Plan'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text(context.tr(plan.label), style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.xs),
            Text(detail, style: muted),
            if (status != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                context.tr('Signed in as {email}', {'email': status.email}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Space.lg),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                if (status == null)
                  FilledButton.icon(
                    onPressed:
                        account.isBusy ||
                            !google.isConfigured ||
                            !offer.signInEnabled
                        ? null
                        : () => _signIn(context),
                    icon: const Icon(Icons.login),
                    label: Text(context.tr('Sign in to your account')),
                  ),
                if (status != null &&
                    plan == AppPlan.free &&
                    status.trialAvailable)
                  FilledButton.icon(
                    onPressed: account.isBusy ? null : () => _trial(context),
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: Text(
                      context.tr('Start {days}-day free trial', {
                        'days': offer.trialDays,
                      }),
                    ),
                  ),
                if (status != null)
                  FilledButton.tonalIcon(
                    onPressed: account.isBusy ? null : () => _code(context),
                    icon: const Icon(Icons.key_outlined),
                    label: Text(context.tr('Enter a code')),
                  ),
                OutlinedButton(
                  onPressed: () => _compare(context, offer),
                  child: Text(context.tr('Compare plans')),
                ),
                TextButton(
                  onPressed: () => askAboutEnterprise(context),
                  child: Text(context.tr('Ask about Enterprise')),
                ),
                if (status != null)
                  TextButton(
                    onPressed: () =>
                        context.read<AccountController>().signOut(),
                    child: Text(context.tr('Sign out of your account')),
                  ),
              ],
            ),
            if (status == null && !google.isConfigured) ...[
              const SizedBox(height: Space.sm),
              Text(
                context.tr("Google sign-in isn't set up in this version."),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final account = context.read<AccountController>();
    final result = await context.read<GoogleAccountController>().withToken((
      token,
    ) async {
      final error = await account.signInWithGoogle(token);
      return (
        ok: error == null,
        message: error ?? 'Signed in to your account.',
        sheet: null,
      );
    });
    if (context.mounted) showMessage(context, context.tr(result.message));
  }

  Future<void> _trial(BuildContext context) async {
    final error = await context.read<AccountController>().startTrial();
    if (context.mounted) {
      showMessage(
        context,
        error ?? context.tr('Your Business trial has started.'),
      );
    }
  }

  Future<void> _code(BuildContext context) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeDialog(),
    );
    if (message != null && context.mounted) showMessage(context, message);
  }

  void _compare(BuildContext context, PlanOffer offer) => showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      Widget plan(String name, String price, List<String> points) => Padding(
        padding: const EdgeInsets.only(bottom: Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(name), style: theme.textTheme.titleMedium),
            Text(
              price,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Space.xs),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $p'),
              ),
          ],
        ),
      );
      return AlertDialog(
        title: Text(context.tr('Plans')),
        scrollable: true,
        content: SizedBox(
          width: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              plan(AppPlan.free.label, context.tr('Free'), [
                context.tr('All 51 calculators, in English or Filipino'),
                context.tr('Up to {n} projects', {'n': offer.freeProjects}),
                context.tr('Bill of quantities PDF and shopping list'),
                context.tr('Room schedule, house checklist and quick budget'),
                context.tr(
                  'Bill of quantities for bidders and quote comparison',
                ),
              ]),
              plan(
                AppPlan.business.label,
                context.tr('{price} a month', {
                  'price': _money(offer.businessUsd, offer.businessPhp),
                }),
                [
                  context.tr('Unlimited projects'),
                  context.tr(
                    'Contractor and DPWH pricing: crews, daily rates, general '
                    'requirements, markups and VAT',
                  ),
                  context.tr(
                    'Quotations, schedule, cash flow, progress billing and '
                    'actual costs',
                  ),
                  context.tr(
                    'Excel, CSV and Google Sheets exports, and revisions',
                  ),
                  context.tr('Your company name on every document'),
                  context.tr('Try it free for {days} days', {
                    'days': offer.trialDays,
                  }),
                ],
              ),
              plan(AppPlan.enterprise.label, context.tr('Contact us'), [
                context.tr('Business for your whole team, with seats'),
                context.tr('Shared projects and one company price book'),
                context.tr('Roles for owners, admins, estimators and viewers'),
                context.tr('Onboarding, training and priority support'),
              ]),
              Text(
                context.tr(
                  'Pay by bank transfer or GCash and we email you a code. '
                  'Enter it here to switch your plan on.',
                ),
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
            child: Text(context.tr('Close')),
          ),
        ],
      );
    },
  );
}

/// The form for asking sales about Enterprise, then a thank-you once
/// it is sent.
Future<void> askAboutEnterprise(BuildContext context) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => const _ContactDialog(),
  );
  if (sent == true && context.mounted) {
    showMessage(
      context,
      context.tr('Thank you. We will reply by email within a working day.'),
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final account = context.read<AccountController>();
    final error = await account.redeem(_code.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(
      context.tr('Your plan is now {plan}.', {
        'plan': context.tr(account.plan.label),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AccountController>().isBusy;
    return AlertDialog(
      title: Text(context.tr('Enter your code')),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: InputDecoration(
            labelText: context.tr('Activation code'),
            hintText: 'BQ-XXXX-XXXX-XXXX-XXXX',
            helperText: context.tr('From the email we sent you'),
            errorText: _error,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: Text(context.tr('Use code')),
        ),
      ],
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog();

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final _name = TextEditingController(
    text: context.read<AccountController>().status?.name,
  );
  late final _email = TextEditingController(
    text: context.read<AccountController>().status?.email,
  );
  final _company = TextEditingController();
  final _seats = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _company, _seats, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final error = await context.read<AccountController>().sendInquiry(
      name: _name.text.trim(),
      email: _email.text.trim(),
      company: _company.text.trim(),
      seats: int.tryParse(_seats.text.trim()),
      message: _message.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AccountController>().isBusy;
    InputDecoration label(String text) =>
        InputDecoration(labelText: context.tr(text));
    return AlertDialog(
      title: Text(context.tr('Ask about Enterprise')),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: label('Your name'),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: label('Email'),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: label('Company'),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _seats,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: label('How many people will use it?'),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              decoration: label('What do you need?'),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: busy ? null : _send,
          child: Text(context.tr('Send')),
        ),
      ],
    );
  }
}
