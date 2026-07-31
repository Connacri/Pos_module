import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({
    super.key,
    required this.customers,
    required this.onCreate,
  });

  final List<Customer> customers;
  final Future<bool> Function(int? customerId) onCreate;

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  int? _customerId;
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);
    final ok = await widget.onCreate(_customerId);
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
    final l10n = AppLocalizations.of(context);

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
          Text('Nouvelle facture', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _customerId,
            decoration: const InputDecoration(
              labelText: 'Client',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in widget.customers)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (value) => setState(() => _customerId = value),
          ),
          const SizedBox(height: 16),
          Text(
            'La facture sera générée à partir de la vente sélectionnée.',
            style: Theme.of(context).textTheme.bodySmall,
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
                  onPressed: _saving ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
