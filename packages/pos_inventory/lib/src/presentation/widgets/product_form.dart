import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
  });

  final Product? product;
  final List<Category> categories;
  final Future<bool> Function(Product draft) onSave;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _taxController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _barcodeController;
  int? _categoryId;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuController = TextEditingController(text: p?.sku ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: _fmt(p?.price));
    _costController = TextEditingController(text: _fmt(p?.costPrice));
    _taxController = TextEditingController(text: _fmt(p?.taxRate));
    _stockController = TextEditingController(text: _fmt(p?.stock));
    _thresholdController =
        TextEditingController(text: _fmt(p?.lowStockThreshold));
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _categoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;
  }

  static String _fmt(double? value) {
    final v = value ?? 0;
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _taxController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final existing = widget.product;
    final draft = Product(
      id: existing?.id ?? 0,
      sku: _skuController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _categoryId,
      price: _parse(_priceController.text),
      costPrice: _parse(_costController.text),
      taxRate: _parse(_taxController.text),
      stock: _parse(_stockController.text),
      lowStockThreshold: _parse(_thresholdController.text),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      isActive: _isActive,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
      syncStatus: existing?.syncStatus ?? SyncStatus.synced,
    );

    final ok = await widget.onSave(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
      );
    }
  }

  static double _parse(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  Future<void> _scanBarcode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(title: 'Scanner un code-barres'),
      ),
    );
    if (scanned == null || !mounted) return;
    setState(() => _barcodeController.text = scanned);
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product == null ? l10n.add : l10n.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: '${l10n.sku} *',
                controller: _skuController,
                validator: Validators.sku,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: '${l10n.name} *',
                controller: _nameController,
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: l10n.description,
                controller: _descriptionController,
                maxLines: 2,
                minLines: 2,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: l10n.barcode,
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scanner',
                  onPressed: _scanBarcode,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: l10n.categories,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.price,
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Coût',
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: '${l10n.tax} (%)',
                      controller: _taxController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: l10n.quantity,
                      controller: _stockController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Seuil',
                      controller: _thresholdController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
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
                      label: l10n.save,
                      icon: Icons.save_outlined,
                      loading: _saving,
                      onPressed: _saving ? null : _submit,
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
