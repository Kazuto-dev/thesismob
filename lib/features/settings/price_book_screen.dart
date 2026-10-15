import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/items.dart';
import '../../state/price_book_controller.dart';
import '../common/price_dialog.dart';

/// Every material the calculators can price, with the suggested price and
/// the user's own where they set one.
class PriceBookScreen extends StatefulWidget {
  const PriceBookScreen({super.key});

  @override
  State<PriceBookScreen> createState() => _PriceBookScreenState();
}

class _PriceBookScreenState extends State<PriceBookScreen> {
  final _search = TextEditingController();
  bool _onlyMine = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(Item item) async {
    final book = context.read<PriceBookController>();
    final suggested = book.defaultPriceOf(item.key);
    final price = await showPriceDialog(
      context,
      title: item.name,
      unit: item.unit,
      initial: book.priceOf(item.key),
      suggested: suggested > 0
          ? 'Suggested ${formatMoney(suggested)} (${book.region.label})'
          : null,
    );
    if (price != null) book.setPrice(item.key, price);
  }

  Future<void> _resetAll() async {
    final book = context.read<PriceBookController>();
    final saved = book.custom;
    book.resetAll();
    showMessage(
      context,
      'Your prices were cleared.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => book.restore(saved),
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
    final groups = <ItemGroup, List<Item>>{};
    for (final i in items) {
      groups.putIfAbsent(i.group, () => []).add(i);
    }

    return PageTitle(
      title: 'Price book',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Price book'),
          actions: [
            if (book.custom.isNotEmpty)
              TextButton(
                onPressed: _resetAll,
                child: const Text('Clear my prices'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: Space.sm,
            bottom: bottomClearance(context),
          ),
          child: ContentWidth(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Calculators fill in these prices and use them for the '
                  'materials each job also needs. Set your supplier\'s price '
                  'to use it everywhere.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<PriceRegion>(
                          initialValue: book.region,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Where is the project?',
                            helperText:
                                'Suggested prices are raised for regions '
                                'where materials cost more',
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
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search materials',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: Text('My prices (${book.custom.length})'),
                    selected: _onlyMine,
                    onSelected: (v) => setState(() => _onlyMine = v),
                  ),
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
                    in groups.entries) ...[
                  SectionHeader(
                    group.label,
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      Space.xl,
                      0,
                      Space.sm,
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, item) in members.indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: Space.lg),
                          _PriceRow(
                            item: item,
                            price: book.priceOf(item.key),
                            custom: book.isCustom(item.key),
                            onTap: () => _edit(item),
                            onReset: () => book.reset(item.key),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
  });

  final Item item;
  final double price;
  final bool custom;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final tag = custom
        ? ('Your price', palette.success)
        : item.estimate
        ? ('Estimate, check locally', scheme.onSurfaceVariant)
        : null;
    return Semantics(
      button: true,
      hint: 'Change price',
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
                  tooltip: 'Use the suggested price',
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
