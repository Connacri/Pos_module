import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'billing_controller.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _query = '';

  List<Invoice> _filter(List<Invoice> invoices) {
    if (_query.trim().isEmpty) return invoices;
    final q = _query.trim().toLowerCase();
    return invoices
        .where(
          (i) =>
              i.invoiceNumber.toLowerCase().contains(q) ||
              (i.customerId != null && i.customerId.toString().contains(q)) ||
              i.status.label.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<BillingController>();

    return AppScaffold(
      title: l10n.billing,
      showBack: widget.showBackButton,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        child: const Icon(Icons.note_add_outlined),
      ),
      body: AppResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AppTextField(
                label: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            _SummaryCards(controller: controller),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filter(controller.invoices).isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucune facture',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filter(controller.invoices).length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final invoice = _filter(controller.invoices)[index];
                        return _InvoiceCard(
                          invoice: invoice,
                          customerName: controller.customerName(
                            invoice.customerId,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailScreen(invoice: invoice),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    final controller = context.read<BillingController>();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => InvoiceForm(
        sales: controller.sales,
        customers: controller.customers,
        onCreate: (saleId) => controller.createFromSale(saleId),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.controller});

  final BillingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: l10n.total,
              value: CurrencyUtils.format(
                controller.invoices.fold(0, (s, i) => s + i.total),
              ),
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'En attente',
              value: CurrencyUtils.format(controller.totalOutstanding),
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'Retards',
              value: '${controller.overdueCount}',
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.money(color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.customerName,
    required this.onTap,
  });

  final Invoice invoice;
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
              invoice.isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.receipt_long_outlined,
              color: invoice.isOverdue
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
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
                        '#${invoice.invoiceNumber}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    StatusChip(status: invoice.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customerName ?? 'Client inconnu',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.createdAt != null
                      ? AppDateUtils.formatDate(invoice.createdAt!)
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
                CurrencyUtils.format(invoice.total),
                style: AppTextStyles.money(theme.colorScheme.primary),
              ),
              if (invoice.isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'En retard',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      InvoiceStatus.draft => theme.colorScheme.outline,
      InvoiceStatus.issued => theme.colorScheme.primary,
      InvoiceStatus.paid => Colors.green,
      InvoiceStatus.overdue => theme.colorScheme.error,
      InvoiceStatus.cancelled => theme.colorScheme.outline,
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
