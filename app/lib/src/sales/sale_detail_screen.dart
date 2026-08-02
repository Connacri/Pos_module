import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../returns/return_controller.dart';
import '../returns/return_form_screen.dart';

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  void _openReturn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReturnSaleScreen(sale: sale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ReturnController>();

    return AppScaffold(
      title: 'Vente #${sale.saleNumber}',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _SaleStatusChip(status: sale.status),
              const Spacer(),
              Text(
                sale.createdAt != null
                    ? AppDateUtils.formatDateTime(sale.createdAt!)
                    : '-',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Client',
                  value: controller.customerName(sale.customerId) ?? 'Client inconnu',
                ),
                const Divider(height: 16),
                _InfoRow(
                  icon: Icons.payment_outlined,
                  label: 'Paiement',
                  value: sale.paymentMethod.label,
                ),
                const Divider(height: 16),
                _InfoRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Articles',
                  value: '${sale.itemCount} article(s)',
                ),
                if (sale.cashierId != null) ...[
                  const Divider(height: 16),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Caissier',
                    value: '#${sale.cashierId}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Articles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in sale.items) _SaleLine(item: item),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Totals(sale: sale),
          const SizedBox(height: 24),
          if (sale.status == SaleStatus.completed)
            AppButton(
              label: 'Faire un retour',
              icon: Icons.replay_outlined,
              expanded: true,
              onPressed: () => _openReturn(context),
            )
          else
            Center(
              child: Text(
                sale.status == SaleStatus.returned
                    ? 'Cette vente a été entièrement retournée.'
                    : 'Cette vente n\'est pas retournable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SaleLine extends StatelessWidget {
  const _SaleLine({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.productName, style: theme.textTheme.bodyMedium),
              ),
              Text(
                CurrencyUtils.format(item.lineTotal),
                style: AppTextStyles.money(theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${CurrencyUtils.format(item.unitPrice)} x ${item.quantity}'
            '${item.taxRate > 0 ? ' • TVA ${(item.taxRate * 100).toStringAsFixed(0)}%' : ''}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          _TotalRow(label: 'Sous-total', value: sale.subtotal),
          if (sale.taxTotal > 0)
            _TotalRow(label: 'Taxe', value: sale.taxTotal),
          if (sale.discountTotal > 0)
            _TotalRow(label: 'Remise', value: -sale.discountTotal),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                Text(
                  CurrencyUtils.format(sale.total),
                  style: AppTextStyles.money(theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            CurrencyUtils.format(value),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SaleStatusChip extends StatelessWidget {
  const _SaleStatusChip({required this.status});

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
