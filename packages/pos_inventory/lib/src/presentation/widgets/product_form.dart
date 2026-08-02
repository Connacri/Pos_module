import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../inventory_controller.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
    this.uploader,
  });

  final Product? product;
  final List<Category> categories;
  final Future<bool> Function(Product draft) onSave;
  final ProductImageUploader? uploader;

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
  late final List<String> _photos = [];
  late bool _uploading;
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
    _photos.addAll(p?.imageUrls ?? const []);
    _uploading = false;
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
      imageUrl: _photos.isEmpty ? null : Product.joinImages([..._photos]),
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

  Future<void> _pickPhotos() async {
    final uploader = widget.uploader;
    final picked = await FilePickerService.pickImages();
    if (picked.isEmpty || !mounted) return;
    if (uploader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos désactivées : stockage non configuré'),
        ),
      );
      return;
    }
    setState(() => _uploading = true);
    int added = 0;
    for (final image in picked) {
      final url = await uploader(image.bytes, image.name);
      if (url != null) {
        _photos.add(url);
        added++;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du téléversement de ${image.name}')),
        );
      }
    }
    if (!mounted) return;
    setState(_uploading = false);
    if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$added photo(s) ajoutée(s)')),
      );
    }
  }

  void _removePhoto(String url) {
    setState(() => _photos.remove(url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
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
              _PhotoPicker(
                photos: _photos,
                uploading: _uploading,
                onPick: _pickPhotos,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 16),
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
      ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> photos;
  final bool uploading;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos du produit', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final url in photos)
              _PhotoThumb(url: url, onRemove: () => onRemove(url)),
            _AddPhotoTile(uploading: uploading, onTap: onPick),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 72,
              height: 72,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: Center(
          child: uploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
