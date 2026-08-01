import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final accent = product.isOutOfStock
        ? theme.colorScheme.error
        : product.isLowStock
            ? AppColors.warning
            : theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.25),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      product.isOutOfStock
                          ? Icons.block
                          : Icons.shopping_bag_outlined,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  if (product.isOutOfStock)
                    Icon(Icons.block, size: 16, color: theme.colorScheme.error),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                product.sku,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyUtils.format(product.price),
                    style: AppTextStyles.money(accent),
                  ),
                  if (product.isLowStock)
                    Text(
                      '${product.stock} ${l10n.inStock}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
