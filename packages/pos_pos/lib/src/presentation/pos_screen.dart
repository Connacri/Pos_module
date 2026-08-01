import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';

import 'pos_controller.dart';
import 'widgets/cart_panel.dart';
import 'widgets/product_tile.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.pos,
      showBack: showBackButton,
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          if (isMobile) {
            return const _MobilePosLayout();
          }
          return const _WidePosLayout();
        },
      ),
    );
  }
}

class _MobilePosLayout extends StatelessWidget {
  const _MobilePosLayout();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PosController>();
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: AppTextField(
            label: l10n.search,
            prefixIcon: const Icon(Icons.search),
            onChanged: controller.setQuery,
          ),
        ),
        Expanded(
          child: controller.filteredProducts.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun produit',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    return ProductTile(
                      product: product,
                      onTap: () => controller.addToCart(product),
                    );
                  },
                ),
        ),
        const CartSummaryBar(),
      ],
    );
  }
}

class _WidePosLayout extends StatelessWidget {
  const _WidePosLayout();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PosController>();
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: AppTextField(
                  label: l10n.search,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: controller.setQuery,
                ),
              ),
              Expanded(
                child: controller.filteredProducts.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aucun produit',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: controller.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = controller.filteredProducts[index];
                          return ProductTile(
                            product: product,
                            onTap: () => controller.addToCart(product),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 360, child: CartPanel(controller: controller)),
      ],
    );
  }
}

class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PosController>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (controller.isCartEmpty) return const SizedBox.shrink();

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${controller.itemCount} ${l10n.products}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyUtils.format(controller.total),
                  style: AppTextStyles.money(theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label: l10n.checkout,
              icon: Icons.point_of_sale,
              expanded: true,
              loading: controller.isCheckingOut,
              onPressed: () => showPaymentSheet(context, controller),
            ),
          ],
        ),
      ),
    );
  }
}
