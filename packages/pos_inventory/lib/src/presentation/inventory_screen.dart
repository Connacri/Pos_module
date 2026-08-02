import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'inventory_controller.dart';
import 'inventory_pdf_service.dart';
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
          onPressed: _scanBarcode,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'Exporter en PDF',
          onSelected: (value) {
            switch (value) {
              case 'all':
                _exportPdf(filtered: false);
              case 'filtered':
                _exportPdf(filtered: true);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'all',
              child: Text('Exporter tout l\'inventaire'),
            ),
            PopupMenuItem(
              value: 'filtered',
              child: Text('Exporter la liste affichée'),
            ),
          ],
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
            _InventorySummary(controller: controller),
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
                          onTap: () => _openDetail(context, product),
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

  Future<void> _scanBarcode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(title: 'Scanner un code-barres'),
      ),
    );
    if (scanned == null) return;
    if (!mounted) return;
    setState(() {
      _query = scanned;
      _filter = InventoryFilter.all;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Code scanné : $scanned')));
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

  void _openDetail(BuildContext context, Product product) {
    final controller = context.read<InventoryController>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          categoryName: controller.categories
              .where((c) => c.id == product.categoryId)
              .map((c) => c.name)
              .firstOrNull,
        ),
      ),
    );
  }

  Future<void> _openProductForm(
    BuildContext context, [
    Product? product,
  ]) async {
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
        uploader: controller.uploader,
        onSave: (draft) =>
            controller.saveProduct(draft, isNew: product == null),
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

  Future<void> _exportPdf({required bool filtered}) async {
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final products = filtered
        ? _filterProducts(controller.products)
        : controller.products;
    final categoryNames = {for (final c in controller.categories) c.id: c.name};
    final title = filtered
        ? 'Inventaire - liste affichée'
        : 'Inventaire complet';
    final bytes = await InventoryPdfService.generate(
      products: products,
      categoryNames: categoryNames,
      title: title,
    );
    final date = DateTime.now().toIso8601String().split('T').first;
    final path = await FilePickerService.savePdfFile(
      fileName: 'inventaire_$date.pdf',
      bytes: bytes,
    );
    if (path != null && messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text('PDF enregistré : $path')));
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStockAdjust,
    required this.onShowBarcode,
  });

  final Product product;
  final String? categoryName;
  final VoidCallback onTap;
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
      onTap: onTap,
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
                onPressed: product.stock <= 0 ? null : () => onStockAdjust(-1),
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
              const PopupMenuItem(
                value: 'barcode',
                child: ListTile(
                  leading: Icon(Icons.qr_code_2),
                  contentPadding: EdgeInsets.zero,
                  title: Text('Code-barres'),
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

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.controller});

  final InventoryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = controller.products;
    final totalProducts = products.length;
    final stockValue = products.fold<double>(
      0,
      (s, p) => s + p.stock * (p.costPrice > 0 ? p.costPrice : p.price),
    );
    final outOfStock = products.where((p) => p.isOutOfStock).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Produits',
              value: '$totalProducts',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCell(
              label: 'Valeur stock',
              value: CurrencyUtils.format(stockValue),
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCell(
              label: 'Ruptures',
              value: '$outOfStock',
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
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
