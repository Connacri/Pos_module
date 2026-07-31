import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'billing_controller.dart';
import 'billing_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<BillingController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('#${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: l10n.print,
            onPressed: () =>
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impression (à implémenter)')),
                ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'paid':
                  await controller.markAsPaid(invoice.id);
                case 'issued':
                  await controller.updateStatus(invoice.id, InvoiceStatus.issued);
                case 'delete':
                  final ok = await controller.deleteInvoice(invoice.id);
                  if (ok && context.mounted) Navigator.of(context).pop();
              }
              if (context.mounted) {
                final message =
                    controller.error ?? controller.successMessage ?? l10n.success;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'paid', child: Text('Marquer payée')),
              PopupMenuItem(value: 'issued', child: Text('Marquer émise')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatusChip(status: invoice.status),
              const Spacer(),
              Text(
                invoice.createdAt != null
                    ? AppDateUtils.formatDateTime(invoice.createdAt!)
                    : '',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CompanySection(invoice: invoice),
          const SizedBox(height: 16),
          if (invoice.customerId != null)
            _CustomerSection(
              name: controller.customerName(invoice.customerId) ?? '-',
            ),
          const SizedBox(height: 24),
          Text(l10n.products, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final item in invoice.items)
                  _InvoiceLine(item: item),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Totals(invoice: invoice),
          if (invoice.dueDate != null) ...[
            const SizedBox(height: 16),
            Text(
              'Échéance : ${AppDateUtils.formatDate(invoice.dueDate!)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: 'Marquer comme payée',
            icon: Icons.paid_outlined,
            expanded: true,
            onPressed: invoice.status == InvoiceStatus.paid
                ? null
                : () async {
                    final ok = await controller.markAsPaid(invoice.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.successMessage ?? l10n.success,
                          ),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _CompanySection extends StatelessWidget {
  const _CompanySection({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = [
      invoice.companyName,
      invoice.companyAddress,
      invoice.companyTaxId,
    ].whereType<String>();

    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Émetteur',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (final line in lines)
          Text(line, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: theme.textTheme.bodyMedium),
                Text(
                  '${CurrencyUtils.format(item.unitPrice)} x ${item.quantity}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.format(item.lineTotal),
            style: AppTextStyles.money(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _TotalRow(label: 'Sous-total', value: invoice.subtotal),
        _TotalRow(label: 'Taxe', value: invoice.taxTotal),
        if (invoice.discountTotal > 0)
          _TotalRow(label: 'Remise', value: -invoice.discountTotal),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleMedium),
              Text(
                CurrencyUtils.format(invoice.total),
                style: AppTextStyles.money(theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
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
