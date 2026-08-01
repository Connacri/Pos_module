import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({
    super.key,
    required this.sales,
    required this.customers,
    required this.onCreate,
  });

  final List<Sale> sales;
  final List<Customer> customers;
  final Future<bool> Function(int saleId) onCreate;

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  int? _saleId;
  bool _saving = false;

  String? _customerName(int? customerId) {
    if (customerId == null) return null;
    return widget.customers
        .where((c) => c.id == customerId)
        .map((c) => c.name)
        .firstOrNull;
  }

  Future<void> _submit() async {
    final saleId = _saleId;
    if (saleId == null) return;
    setState(() => _saving = true);
    final ok = await widget.onCreate(saleId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final sales =
        widget.sales
            .where(
              (s) =>
                  s.status == SaleStatus.completed ||
                  s.status == SaleStatus.pending,
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

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
          Text('Nouvelle facture', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (sales.isEmpty)
            Text(
              'Aucune vente disponible. Encaisser d\'abord une vente dans la caisse.',
              style: theme.textTheme.bodySmall,
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _saleId,
              decoration: const InputDecoration(
                labelText: 'Vente',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final sale in sales)
                  DropdownMenuItem(
                    value: sale.id,
                    child: Text(
                      '#${sale.saleNumber}'
                      ' — ${_customerName(sale.customerId) ?? 'Client inconnu'}'
                      ' — ${CurrencyUtils.format(sale.total)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _saleId = value),
            ),
          const SizedBox(height: 12),
          Text(
            'La facture sera générée à partir de la vente sélectionnée.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.confirm,
                  icon: Icons.check_circle_outline,
                  loading: _saving,
                  onPressed: (_saleId == null || _saving || sales.isEmpty)
                      ? null
                      : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
