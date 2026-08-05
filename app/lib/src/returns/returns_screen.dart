import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'return_controller.dart';
import 'return_form_screen.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key, this.showBackButton = false, this.bare = false});

  final bool showBackButton;

  /// Mode « onglet » : cache la barre d'app pour être intégré dans un écran
  /// parent (ex : onglet Retour de la facturation).
  final bool bare;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  Future<void> _startReturn() async {
    final controller = context.read<ReturnController>();
    final sale = await showModalBottomSheet<Sale>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SelectSaleSheet(controller: controller),
    );
    if (sale == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReturnSaleScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ReturnController>();

    return AppScaffold(
      title: 'Retours',
      showBack: widget.showBackButton,
      showAppBar: !widget.bare,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startReturn,
        heroTag: 'fab_returns',
        icon: const Icon(Icons.replay_outlined),
        label: const Text('Nouveau retour'),
      ),
      body: AppResponsiveBody(
        padding: EdgeInsets.zero,
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.returns.isEmpty
            ? const EmptyState(
                icon: Icons.replay_outlined,
                title: 'Aucun retour',
                subtitle: 'Créez un retour depuis une vente encaissée.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${controller.returns.length} retour(s) enregistré(s)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.returns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final record = controller.returns[index];
                        return _ReturnCard(
                          record: record,
                          customerName: controller.customerName(
                            record.customerId,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SelectSaleSheet extends StatelessWidget {
  const _SelectSaleSheet({required this.controller});

  final ReturnController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sales = controller.returnableSales;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choisir la vente', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Sélectionnez une vente encaissée à retourner.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (sales.isEmpty)
              Text(
                'Aucune vente encaissée à retourner.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sales.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return AppCard(
                      onTap: () => Navigator.of(context).pop(sale),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.point_of_sale_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${sale.saleNumber}',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.customerName(sale.customerId) ??
                                      'Client inconnu',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyUtils.format(sale.total),
                            style: AppTextStyles.money(theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.record, required this.customerName});

  final ReturnRecord record;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
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
                  theme.colorScheme.error.withValues(alpha: 0.25),
                  theme.colorScheme.tertiary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.replay_outlined,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.saleNumber != null
                      ? 'Retour de #${record.saleNumber}'
                      : 'Retour de la vente #${record.saleId}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.itemCount} article(s)',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  record.createdAt != null
                      ? AppDateUtils.formatDateTime(record.createdAt!)
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
                '- ${CurrencyUtils.format(record.refundTotal)}',
                style: AppTextStyles.money(theme.colorScheme.error),
              ),
              if (customerName != null)
                Text(
                  customerName!,
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