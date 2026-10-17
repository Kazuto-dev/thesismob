import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/price_quote.dart';
import '../../materials/items.dart';
import '../../state/price_book_controller.dart';
import '../common/price_dialog.dart';

/// The Prices tab: every material the calculators can price, with the
/// suggested price and the user's own where they set one.
class PriceBookScreen extends StatefulWidget {
  const PriceBookScreen({super.key});

  @override
  State<PriceBookScreen> createState() => _PriceBookScreenState();
}

class _PriceBookScreenState extends State<PriceBookScreen> {
  final _search = TextEditingController();
  bool _onlyMine = false;

  /// The kinds the user opened; every kind starts closed.
  final _open = <ItemGroup>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(Item item) async {
    final book = context.read<PriceBookController>();
    final suggested = book.defaultPriceOf(item.key);
    final quoted = await showQuoteDialog(
      context,
      title: item.name,
      unit: item.unit,
      initial: book.priceOf(item.key),
      suggested: suggested > 0
          ? 'Suggested ${formatMoney(suggested)} (${book.region.label})'
          : null,
      quote: book.quoteOf(item.key),
    );
    if (quoted == null) return;
    book.setPrice(
      item.key,
      quoted.price,
      supplier: quoted.supplier,
      quotedOn: quoted.date,
    );
  }

  Future<void> _resetAll() async {
    final book = context.read<PriceBookController>();
    final saved = book.custom;
    final quotes = book.quotes;
    book.resetAll();
    showMessage(
      context,
      context.tr('Your prices were cleared.'),
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () => book.restore(saved, quotes: quotes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final book = context.watch<PriceBookController>();
    final query = _search.text.trim().toLowerCase();
    final items = [
      for (final i in allItems)
        if ((query.isEmpty ||
                i.name.toLowerCase().contains(query) ||
                i.group.label.toLowerCase().contains(query)) &&
            (!_onlyMine || book.isCustom(i.key)) &&
            i.step > 0)
          i,
    ];
    final filtering = query.isNotEmpty || _onlyMine;
    final groups = <ItemGroup, List<Item>>{};
    for (final i in items) {
      groups.putIfAbsent(i.group, () => []).add(i);
    }

    return PageTitle(
      title: context.tr('Prices'),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: ContentWidth(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: context.tr('Prices'),
                    subtitle: context.tr(
                      'Calculators fill in these prices and use them for the '
                      'materials each job also needs. Set your supplier\'s price '
                      'to use it everywhere.',
                    ),
                    actions: [
                      if (book.custom.isNotEmpty)
                        TextButton(
                          onPressed: _resetAll,
                          child: Text(context.tr('Clear my prices')),
                        ),
                    ],
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<PriceRegion>(
                            initialValue: book.region,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.tr('Where is the project?'),
                              helperText: context.tr(
                                'Suggested prices are raised for regions '
                                'where materials cost more',
                              ),
                            ),
                            items: [
                              for (final r in PriceRegion.values)
                                DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r.factor == 1
                                        ? r.label
                                        : '${r.label} (+${formatNumber((r.factor - 1) * 100)}%)',
                                  ),
                                ),
                            ],
                            onChanged: (r) {
                              if (r != null) book.region = r;
                            },
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            '$priceListLabel. $priceListSources',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: context.tr('Search materials'),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('My prices (${book.custom.length})'),
                        selected: _onlyMine,
                        onSelected: (v) => setState(() => _onlyMine = v),
                      ),
                      const Spacer(),
                      if (!filtering && groups.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            if (_open.length == groups.length) {
                              _open.clear();
                            } else {
                              _open.addAll(groups.keys);
                            }
                          }),
                          child: Text(
                            context.tr(
                              _open.length == groups.length
                                  ? 'Close all'
                                  : 'Open all',
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                      child: Text(
                        _onlyMine
                            ? 'You have not set any prices yet.'
                            : 'No materials match "${_search.text}".',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  for (final MapEntry(key: group, value: members)
                      in groups.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.md),
                      child: _GroupCard(
                        group: group,
                        count: members.length,
                        mine: members.where((i) => book.isCustom(i.key)).length,
                        // A search or the My prices filter shows its
                        // matches without another tap.
                        open: filtering || _open.contains(group),
                        onToggle: filtering
                            ? null
                            : () => setState(() {
                                if (!_open.remove(group)) _open.add(group);
                              }),
                        children: [
                          for (final (i, item) in members.indexed) ...[
                            if (i > 0)
                              const Divider(height: 1, indent: Space.lg),
                            _PriceRow(
                              item: item,
                              price: book.priceOf(item.key),
                              custom: book.isCustom(item.key),
                              quote: book.quoteOf(item.key),
                              onTap: () => _edit(item),
                              onReset: () => book.reset(item.key),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One kind of material, as a card whose header opens and closes its list.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.count,
    required this.mine,
    required this.open,
    required this.onToggle,
    required this.children,
  });

  final ItemGroup group;
  final int count;

  /// How many of [count] carry the user's own price.
  final int mine;
  final bool open;

  /// Null while a search keeps every kind open.
  final VoidCallback? onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = [
      count == 1 ? context.tr('1 item') : context.tr('{n} items', {'n': count}),
      if (mine > 0) context.tr('{n} yours', {'n': mine}),
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.lg,
                  vertical: Space.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(group.label),
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggle != null)
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...[const Divider(height: 1), ...children],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.item,
    required this.price,
    required this.custom,
    required this.onTap,
    required this.onReset,
    this.quote,
  });

  final Item item;
  final double price;
  final bool custom;

  /// The supplier and quote date of the user's price.
  final PriceQuote? quote;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final quoted = quote == null || quote!.isEmpty ? '' : quoteLabel(quote!);
    final tag = custom
        ? ('Your price', palette.success)
        : item.estimate
        ? ('Estimate, check locally', scheme.onSurfaceVariant)
        : null;
    return Semantics(
      button: true,
      hint: context.tr('Change price'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            custom ? Space.xs : Space.lg,
            Space.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tag != null)
                      Text(
                        tag.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tag.$2,
                        ),
                      ),
                    if (custom && quoted.isNotEmpty)
                      Text(
                        quoted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              Text(
                price > 0 ? formatMoney(price) : 'Set price',
                style: price > 0
                    ? tabular(
                        theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
              ),
              Text(
                ' / ${item.unit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (custom)
                IconButton(
                  tooltip: context.tr('Use the suggested price'),
                  icon: const Icon(Icons.restart_alt, size: 20),
                  onPressed: onReset,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
