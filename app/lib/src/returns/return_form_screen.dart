import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'return_controller.dart';

class ReturnSaleScreen extends StatefulWidget {
  const ReturnSaleScreen({super.key, required this.sale});

  final Sale sale;

  @override
  State<ReturnSaleScreen> createState() => _ReturnSaleScreenState();
}

class _ReturnSaleScreenState extends State<ReturnSaleScreen> {
  final Map<int, double> _quantities = {};
  List<ReturnItem> _items = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context
        .read<ReturnController>()
        .returnableItemsFor(widget.sale.id);
    if (!mounted) return;
    result.fold(
      (items) {
        setState(() {
          _items = items;
          _loading = false;
        });
      },
      (failure) {
        setState(() {
          _error = failure.message;
          _loading = false;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final selected = _items
        .where((i) => (_quantities[i.productId] ?? 0) > 0)
        .map(
          (i) => ReturnItem(
            productId: i.productId,
            description: i.description,
            unitPrice: i.unitPrice,
            quantity: _quantities[i.productId]!,
            taxRate: i.taxRate,
          ),
        )
        .toList();

    final controller = context.read<ReturnController>();
    final ok = await controller.createReturn(
      saleId: widget.sale.id,
      items: selected,
      reason: _reason.trim().isEmpty ? null : _reason.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Retour enregistré, stock restauré')),
      );
      Navigator.of(context).pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Erreur lors du retour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Retour de #${widget.sale.saleNumber}',
      showBack: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? EmptyState(
              icon: Icons.info_outline,
              title: 'Retour impossible',
              subtitle: _error,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Quantités à retourner',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final item in _items) ...[
                        _ReturnItemTile(
                          item: item,
                          quantity: _quantities[item.productId] ?? 0,
                          onChanged: (value) => setState(
                            () => _quantities[item.productId] = value,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      AppTextField(
                        label: 'Motif (optionnel)',
                        hint: 'Ex : produit défectueux, erreur de commande...',
                        prefixIcon: const Icon(Icons.note_outlined),
                        maxLines: 2,
                        onChanged: (value) => setState(() => _reason = value),
                      ),
                      const SizedBox(height: 16),
                      _RefundSummary(
                        subtotal: _selectedRefund,
                        count: _selectedCount,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppButton(
                      label: 'Valider le retour',
                      icon: Icons.check_circle_outline,
                      expanded: true,
                      loading: _submitting,
                      onPressed: (_hasSelection && !_submitting)
                          ? _submit
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  double get _selectedRefund => _items.fold(
    0,
    (sum, item) => sum + (item.unitPrice * (_quantities[item.productId] ?? 0)),
  );

  int get _selectedCount => _items.fold(
    0,
    (sum, item) => sum + (_quantities[item.productId] ?? 0).round(),
  );

  bool get _hasSelection => _selectedCount > 0;
}

class _ReturnItemTile extends StatelessWidget {
  const _ReturnItemTile({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final ReturnItem item;
  final double quantity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxQty = item.quantity;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyUtils.format(item.unitPrice)} / unité',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QtyStepper(
            value: quantity,
            max: maxQty,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > 0
              ? () => onChanged((value - 1).clamp(0, max))
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + 1).clamp(0, max))
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _RefundSummary extends StatelessWidget {
  const _RefundSummary({required this.subtotal, required this.count});

  final double subtotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remboursement', style: theme.textTheme.titleSmall),
              Text(
                '$count article(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            CurrencyUtils.format(subtotal),
            style: AppTextStyles.money(theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}