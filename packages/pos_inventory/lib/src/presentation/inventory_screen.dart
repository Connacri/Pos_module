import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'inventory_controller.dart';
import 'widgets/product_form.dart';

enum InventoryFilter { all, lowStock, outOfStock }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryFilter _filter = InventoryFilter.all;
  String _query = '';

  List<Product> _filterProducts(List<Product> products) {
    var list = List<Product>.from(products);
    if (_query.trim().isNotEmpty) {
      list = list.where((p) => p.matchesQuery(_query)).toList();
    }
    switch (_filter) {
      case InventoryFilter.lowStock:
        list = list.where((p) => p.isLowStock && !p.isOutOfStock).toList();
        break;
      case InventoryFilter.outOfStock:
        list = list.where((p) => p.isOutOfStock).toList();
        break;
      case InventoryFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<InventoryController>();
    final products = _filterProducts(controller.products);

    return AppScaffold(
      title: l10n.inventory,
      showBack: widget.showBackButton,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: l10n.barcode,
          onPressed: () => _scanBarcode(context),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(context),
        child: const Icon(Icons.add),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<InventoryFilter>(
                segments: [
                  ButtonSegment(
                    value: InventoryFilter.all,
                    label: Text(l10n.products),
                  ),
                  ButtonSegment(
                    value: InventoryFilter.lowStock,
                    label: Text(l10n.lowStock),
                  ),
                  ButtonSegment(
                    value: InventoryFilter.outOfStock,
                    label: Text(l10n.outOfStock),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) =>
                    setState(() => _filter = selection.first),
              ),
            ),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Aucun produit',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductCard(
                              product: product,
                              categoryName: controller.categories
                                  .where((c) => c.id == product.categoryId)
                                  .map((c) => c.name)
                                  .firstOrNull,
                              onEdit: () => _openProductForm(context, product),
                              onDelete: () => _confirmDelete(context, product),
                              onStockAdjust: (delta) =>
                                  controller.adjustStock(product.id, delta),
                              onShowBarcode: () =>
                                  _showBarcodeDialog(context, product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(title: 'Scanner un code-barres'),
      ),
    );
    if (scanned == null || !mounted) return;
    setState(() {
      _query = scanned;
      _filter = InventoryFilter.all;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code scanné : $scanned')),
    );
  }

  void _showBarcodeDialog(BuildContext context, Product product) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BarcodeView(data: product.barcode ?? product.sku),
            const SizedBox(height: 12),
            Text(
              product.barcode ?? product.sku,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductForm(BuildContext context, [Product? product]) async {
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductForm(
        product: product,
        categories: controller.categories,
        onSave: (draft) => controller.saveProduct(draft, isNew: product == null),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? l10n.success)),
      );
    } else if (controller.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.error!)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<InventoryController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete} ${product.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await controller.deleteProduct(product.id);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? l10n.success)),
      );
    } else if (controller.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.error!)));
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onStockAdjust,
    required this.onShowBarcode,
  });

  final Product product;
  final String? categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<double> onStockAdjust;
  final VoidCallback onShowBarcode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final accent = product.isOutOfStock
        ? theme.colorScheme.error
        : product.isLowStock
            ? AppColors.warning
            : theme.colorScheme.primary;

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
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              product.isOutOfStock ? Icons.block : Icons.shopping_bag_outlined,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${product.sku}'
                  '${categoryName != null ? ' • $categoryName' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CurrencyUtils.format(product.price),
                      style: AppTextStyles.money(accent),
                    ),
                    const SizedBox(width: 12),
                    _StockBadge(product: product),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: l10n.removeFromCart,
                onPressed: product.stock <= 0
                    ? null
                    : () => onStockAdjust(-1),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.add,
                onPressed: () => onStockAdjust(1),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
                case 'barcode':
                  onShowBarcode();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'barcode',
                child: ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Code-barres'),
                  dense: true,
                ),
              ),
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = product.isOutOfStock
        ? theme.colorScheme.error
        : product.isLowStock
            ? AppColors.warning
            : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${product.stock.round()}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
