import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'sale_detail_screen.dart';

/// Liste des ventes, utilisée par le dashboard (ventes du jour, ventes
/// globales, panier moyen, ...). Chaque vente ouvre le détail.
class SalesListScreen extends StatelessWidget {
  const SalesListScreen({
    super.key,
    required this.title,
    required this.sales,
    this.customerName,
  });

  final String title;
  final List<Sale> sales;
  final String? Function(int? customerId)? customerName;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Sale>.from(sales)
      ..sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return AppScaffold(
      title: title,
      showBack: true,
      body: sorted.isEmpty
          ? const EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'Aucune vente',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = sorted[index];
                return _SaleRow(
                  sale: sale,
                  customerName: customerName?.call(sale.customerId),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SaleDetailScreen(sale: sale),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.sale,
    required this.customerName,
    required this.onTap,
  });

  final Sale sale;
  final String? customerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.25),
                  theme.colorScheme.tertiary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.point_of_sale_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${sale.saleNumber}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    _StatusChip(status: sale.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customerName ?? 'Client inconnu',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  sale.createdAt != null
                      ? AppDateUtils.formatDateTime(sale.createdAt!)
                      : '-',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.format(sale.total),
                style: AppTextStyles.money(theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                '${sale.itemCount} art.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SaleStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      SaleStatus.pending => theme.colorScheme.outline,
      SaleStatus.completed => Colors.green,
      SaleStatus.cancelled => theme.colorScheme.error,
      SaleStatus.returned => theme.colorScheme.tertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
