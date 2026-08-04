import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'billing_controller.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, this.showBackButton = false, this.onOpenSale});

  final bool showBackButton;
  final void Function(Sale sale)? onOpenSale;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_onTabChanged);
  String _query = '';
  String _sortKey = 'date';
  bool _ascending = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

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

  List<Invoice> _sortInvoices(BillingController controller) {
    return sortByKey(
      _filter(controller.invoices),
      _sortKey,
      _ascending,
      (i) => switch (_sortKey) {
        'number' => i.invoiceNumber,
        'customer' => controller.customerName(i.customerId) ?? '',
        'amount' => i.total,
        _ => i.createdAt,
      },
    );
  }

  List<Sale> _sortSales(BillingController controller) {
    return sortByKey(
      controller.sales,
      _sortKey,
      _ascending,
      (s) => switch (_sortKey) {
        'number' => s.saleNumber,
        'customer' => controller.customerName(s.customerId) ?? '',
        'amount' => s.total,
        _ => s.createdAt,
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return SortableListHeader(
      columns: [
        const SortableListColumn(label: 'N°', key: 'number', flex: 2),
        const SortableListColumn(label: 'Client', key: 'customer', flex: 3),
        const SortableListColumn(label: 'Date', key: 'date', flex: 2),
        SortableListColumn(
          label: l10n.total,
          key: 'amount',
          flex: 2,
          align: TextAlign.end,
        ),
      ],
      sortKey: _sortKey,
      ascending: _ascending,
      onSort: (key, ascending) => setState(() {
        _sortKey = key;
        _ascending = ascending;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<BillingController>();

    return AppScaffold(
      title: l10n.billing,
      showBack: widget.showBackButton,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _openCreateSheet(context),
              heroTag: 'fab_billing',
              child: const Icon(Icons.note_add_outlined),
            )
          : null,
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(l10n.invoices, maxLines: 1, softWrap: false),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.point_of_sale_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(l10n.sales, maxLines: 1, softWrap: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(controller, l10n),
                _buildSalesTab(controller, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(
    BillingController controller,
    AppLocalizations l10n,
  ) {
    return AppResponsiveBody(
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
          if (controller.invoices.isNotEmpty) _buildHeader(l10n),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filter(controller.invoices).isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aucune facture',
                  )
                : Builder(
                    builder: (context) {
                      final invoices = _sortInvoices(controller);
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: invoices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return _InvoiceCard(
                            invoice: invoice,
                            customerName: controller.customerName(
                              invoice.customerId,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(
                                    invoice: invoice,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(
    BillingController controller,
    AppLocalizations l10n,
  ) {
    final sales = controller.sales;
    return AppResponsiveBody(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (sales.isNotEmpty) _buildHeader(l10n),
          Expanded(
            child: sales.isEmpty
                ? const EmptyState(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Aucune vente',
                  )
                : Builder(
                    builder: (context) {
                      final sorted = _sortSales(controller);
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final sale = sorted[index];
                          return _SaleCard(
                            sale: sale,
                            customerName: controller.customerName(
                              sale.customerId,
                            ),
                            onTap: widget.onOpenSale == null
                                ? null
                                : () => widget.onOpenSale!(sale),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
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
                      ? AppDateUtils.formatDateTime(invoice.createdAt!)
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

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.customerName, this.onTap});

  final Sale sale;
  final String? customerName;
  final VoidCallback? onTap;

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
                  theme.colorScheme.tertiary.withValues(alpha: 0.25),
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              switch (sale.status) {
                SaleStatus.cancelled => Icons.cancel_outlined,
                SaleStatus.returned => Icons.replay_outlined,
                _ => Icons.point_of_sale_outlined,
              },
              color: switch (sale.status) {
                SaleStatus.cancelled => theme.colorScheme.error,
                _ => theme.colorScheme.primary,
              },
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
                    _SaleStatusChip(status: sale.status),
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
                sale.paymentMethod.label,
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
