import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'inventory_controller.dart';
import 'widgets/product_form.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.categoryName,
  });

  final Product product;
  final String? categoryName;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _page = 0;
  Product get _product => widget.product;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InventoryController>();
    // Pull the freshest copy of the product from the controller stream.
    final product = controller.products.firstWhere(
      (p) => p.id == _product.id,
      orElse: () => _product,
    );

    final photos = product.imageUrls;

    return AppScaffold(
      title: product.name,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _edit(context);
              case 'delete':
                _delete(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ],
      body: CustomScrollView(
        slivers: [
          if (photos.isNotEmpty)
            SliverToBoxAdapter(
              child: _PhotoCarousel(
                photos: photos,
                page: _page,
                onChange: (p) => setState(() => _page = p),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                AnimatedEntrance(
                  child: _HeaderInfo(
                    product: product,
                    categoryName: widget.categoryName,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: _PricePanel(product: product),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 200),
                  child: _StockPanel(controller: controller, product: product),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 280),
                  child: _DetailsPanel(product: product),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductForm(
        product: _product,
        categories: controller.categories,
        uploader: controller.uploader,
        onSave: (draft) => controller.saveProduct(draft, isNew: false),
      ),
    );
    if (!context.mounted) return;
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? l10n.success)),
      );
    } else if (controller.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.error!)));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${_product.name} ?'),
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
    if (confirmed != true || !context.mounted) return;
    final ok = await controller.deleteProduct(_product.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? l10n.success)),
      );
    } else if (controller.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.error!)));
    }
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({
    required this.photos,
    required this.page,
    required this.onChange,
  });

  final List<String> photos;
  final int page;
  final ValueChanged<int> onChange;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = ResponsiveLayout.isDesktop(context) ? 340.0 : 260.0;

    return SizedBox(
      height: height + 28,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: widget.photos.length,
                    onPageChanged: widget.onChange,
                    itemBuilder: (context, index) => Image.network(
                      widget.photos[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined, size: 64),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.page + 1} / ${widget.photos.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.photos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == widget.page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == widget.page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.product,
    required this.categoryName,
  });

  final Product product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(product.name, style: theme.textTheme.headlineSmall),
            ),
            _StatusBadge(product: product),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.sku,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (categoryName != null) ...[
              const SizedBox(width: 8),
              Text(
                '• $categoryName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = product.isOutOfStock
        ? ('Rupture', theme.colorScheme.error)
        : product.isLowStock
        ? ('Stock faible', AppColors.warning)
        : ('Disponible', theme.colorScheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = <(String, double, Color)>[
      ('Prix de vente', product.price, scheme.primary),
      ('Coût', product.costPrice, scheme.tertiary),
      ('Marge', product.margin, scheme.secondary),
      ('Taxe', product.taxRate, AppColors.info),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tarification', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Icon(Icons.currency_exchange, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              AnimatedNumber(
                value: product.price,
                style: AppTextStyles.titleLarge(scheme.primary),
                formatter: CurrencyUtils.format,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value, color) in items)
                _MetricChip(label: label, value: value, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyUtils.format(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockPanel extends StatelessWidget {
  const _StockPanel({required this.controller, required this.product});

  final InventoryController controller;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = product.isOutOfStock
        ? scheme.error
        : product.isLowStock
        ? AppColors.warning
        : scheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedNumber(
                  value: product.stock,
                  style: AppTextStyles.displaySmall(color),
                  formatter: (v) => v.round().toString(),
                ),
              ),
              IconButton.filledTonal(
                onPressed: product.stock <= 0
                    ? null
                    : () => controller.adjustStock(product.id, -1),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: color),
                onPressed: () => controller.adjustStock(product.id, 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Seuil d\'alerte : ${product.lowStockThreshold.round()}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Détails', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Code-barres',
            value: product.barcode?.isNotEmpty == true ? product.barcode! : '—',
          ),
          _InfoRow(
            label: 'Description',
            value: product.description?.isNotEmpty == true
                ? product.description!
                : 'Aucune description',
          ),
          const SizedBox(height: 4),
          if (product.createdAt != null)
            Text(
              'Créé le ${AppDateUtils.formatDate(product.createdAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}