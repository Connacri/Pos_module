import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../pos_controller.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key, required this.controller});

  final PosController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(l10n.checkout, style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: controller.isCartEmpty ? null : controller.clearCart,
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.delete,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: controller.isCartEmpty
              ? EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: l10n.emptyCart,
                  subtitle: l10n.addToCart,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.cartItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = controller.cartItems[index];
                    return ListTile(
                      dense: true,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'cart-thumb-${item.productId}',
                            child: AppImageThumb(
                              url: controller
                                  .productById(item.productId)
                                  ?.primaryImageUrl,
                              size: 40,
                              borderRadius: BorderRadius.circular(10),
                              fallbackIcon: Icons.shopping_bag_outlined,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () =>
                                controller.decrement(item.productId),
                            icon: const Icon(Icons.remove_circle_outline),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.increment(item.productId),
                            icon: const Icon(Icons.add_circle_outline),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      title: Text(item.productName),
                      subtitle: Text(
                        '${CurrencyUtils.format(item.unitPrice)} x ${item.quantity}',
                      ),
                      trailing: Text(
                        CurrencyUtils.format(item.lineTotal),
                        style: AppTextStyles.money(theme.colorScheme.onSurface),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TotalRow(label: l10n.subtotal, value: controller.subtotal),
              _TotalRow(label: l10n.tax, value: controller.taxTotal),
              const SizedBox(height: 4),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 4),
              _TotalRow(
                label: l10n.total,
                value: controller.total,
                highlight: true,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.checkout,
                icon: Icons.point_of_sale,
                expanded: true,
                loading: controller.isCheckingOut,
                onPressed: controller.isCartEmpty
                    ? null
                    : () => showPaymentSheet(context, controller),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showPaymentSheet(BuildContext context, PosController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        SafeArea(child: _PaymentSheet(controller: controller)),
  );
}

/// Ouvre le panier en mode mobile (liste des articles, sous-total, taxe,
/// suppression / diminution des quantités) — l'équivalent latéral du
/// [CartPanel] utilisé en mode desktop.
Future<void> showCartSheet(BuildContext context, PosController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        SafeArea(child: _CartSheet(controller: controller)),
  );
}

class _CartSheet extends StatefulWidget {
  const _CartSheet({required this.controller});

  final PosController controller;

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

/// La feuille du panier vit dans une route (bottom sheet) séparée de l'écran
/// caisse : elle doit donc s'abonner elle-même au [PosController] pour
/// refléter les modifications (+ / - / suppression) effectuées depuis ses
/// boutons.
class _CartSheetState extends State<_CartSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Text(l10n.checkout, style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed:
                      controller.isCartEmpty ? null : controller.clearCart,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller.isCartEmpty
                ? EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: l10n.emptyCart,
                    subtitle: l10n.addToCart,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.cartItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = controller.cartItems[index];
                      final product =
                          controller.productById(item.productId);
                      return _CartSheetRow(
                        item: item,
                        imageUrl: product?.primaryImageUrl,
                        onDecrement: () =>
                            controller.decrement(item.productId),
                        onIncrement: () =>
                            controller.increment(item.productId),
                        onRemove: () =>
                            controller.removeFromCart(item.productId),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow(label: l10n.subtotal, value: controller.subtotal),
                _TotalRow(label: l10n.tax, value: controller.taxTotal),
                const SizedBox(height: 4),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 4),
                _TotalRow(
                  label: l10n.total,
                  value: controller.total,
                  highlight: true,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.checkout,
                  icon: Icons.point_of_sale,
                  expanded: true,
                  loading: controller.isCheckingOut,
                  onPressed: controller.isCartEmpty
                      ? null
                      : () => showPaymentSheet(context, controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSheetRow extends StatelessWidget {
  const _CartSheetRow({
    required this.item,
    required this.imageUrl,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final SaleItem item;
  final String? imageUrl;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AppImageThumb(
            url: imageUrl,
            size: 40,
            borderRadius: BorderRadius.circular(10),
            fallbackIcon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
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
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline),
            visualDensity: VisualDensity.compact,
            tooltip: 'Diminuer',
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
            visualDensity: VisualDensity.compact,
            tooltip: 'Augmenter',
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            visualDensity: VisualDensity.compact,
            tooltip: 'Supprimer',
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: highlight
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
          Text(
            CurrencyUtils.format(value),
            style: highlight
                ? AppTextStyles.money(theme.colorScheme.primary)
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.controller});

  final PosController controller;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late PaymentMethod _method;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _method = widget.controller.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.payment, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethod.values.map((m) {
              return ChoiceChip(
                label: Text(m.label),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.total} : ${CurrencyUtils.format(widget.controller.total)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.money(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.confirm,
            icon: Icons.check_circle_outline,
            expanded: true,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    widget.controller.setPaymentMethod(_method);
    final success = await widget.controller.checkout();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? AppLocalizations.of(context).error,
          ),
        ),
      );
    }
  }
}
