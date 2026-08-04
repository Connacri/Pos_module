import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_data/pos_data.dart';
import 'package:pos_inventory/pos_inventory.dart';

import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<SettingsController>();

    return AppScaffold(
      title: l10n.settings,
      showBack: showBackButton,
      body: AppResponsiveBody(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.theme, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: FittedBox(child: Text('Clair')),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: FittedBox(child: Text('Sombre')),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_brightness_outlined),
                          label: FittedBox(child: Text('Système')),
                        ),
                      ],
                      selected: {controller.themeMode},
                      onSelectionChanged: (selection) =>
                          controller.setThemeMode(selection.first),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.language, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'fr',
                          label: FittedBox(child: Text('FR')),
                        ),
                        ButtonSegment(
                          value: 'en',
                          label: FittedBox(child: Text('EN')),
                        ),
                        ButtonSegment(
                          value: 'es',
                          label: FittedBox(child: Text('ES')),
                        ),
                        ButtonSegment(
                          value: 'ar',
                          label: FittedBox(child: Text('AR')),
                        ),
                      ],
                      selected: {
                        controller.locale?.languageCode ??
                            Localizations.localeOf(context).languageCode,
                      },
                      onSelectionChanged: (selection) =>
                          controller.setLocale(Locale(selection.first)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TaxSection(
              controller: context.read<SettingsController>(),
            ),
            const SizedBox(height: 16),
            const _StorageSection(),
            const SizedBox(height: 16),
            const _VersionSection(),
          ],
        ),
      ),
    );
  }
}

class _TaxSection extends StatefulWidget {
  const _TaxSection({required this.controller});

  final SettingsController controller;

  @override
  State<_TaxSection> createState() => _TaxSectionState();
}

class _TaxSectionState extends State<_TaxSection> {
  late final TextEditingController _rateController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: _formatPercent(widget.controller.defaultTaxRate),
    );
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final rate = await TaxSettings.defaultRate();
    if (!mounted) return;
    setState(() => _rateController.text = _formatPercent(rate));
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  static String _formatPercent(double rate) {
    final percent = rate * 100;
    return percent == percent.roundToDouble()
        ? percent.round().toString()
        : percent.toStringAsFixed(1);
  }

  Future<void> _save() async {
    final raw = _rateController.text.trim().replaceAll(',', '.');
    final percent = double.tryParse(raw);
    if (percent == null || percent < 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taux invalide. Entrez une valeur entre 0 et 100.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.controller.setDefaultTaxRate(percent / 100);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TVA par défaut enregistrée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.percent,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('TVA par défaut', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Taux de TVA appliqué par défaut aux nouveaux produits dans les formulaires.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Taux de TVA (%)',
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Enregistrer',
                icon: Icons.check,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VersionSection extends StatefulWidget {
  const _VersionSection();

  @override
  State<_VersionSection> createState() => _VersionSectionState();
}

class _VersionSectionState extends State<_VersionSection> {
  String? _packageVersion;
  String? _buildNumber;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? version;
    String? build;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } catch (_) {
      version = null;
      build = null;
    }
    if (!mounted) return;
    setState(() {
      _packageVersion = version;
      _buildNumber = build;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = _packageVersion ?? AppConstants.appVersion;
    final build = _buildNumber;

    return AppCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppConstants.appName} v$version',
              style: theme.textTheme.titleSmall,
            ),
            if (build != null)
              const SizedBox(height: 2),
            if (build != null)
              Text(
                'Build $build',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StorageSection extends StatefulWidget {
  const _StorageSection();

  @override
  State<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<_StorageSection> {
  bool _busy = false;
  String? _lastUrl;

  Future<void> _uploadImage() async {
    final picked = await FilePickerService.pickImage();
    if (picked == null || !mounted) return;
    await _run(() => SupabaseStorageService.uploadImage(
          picked.bytes,
          picked.name,
        ));
  }

  Future<void> _uploadCsv() async {
    final picked = await FilePickerService.pickCsv();
    if (picked == null || !mounted) return;
    final content = String.fromCharCodes(picked.bytes);
    await _run(
      () => SupabaseStorageService.uploadCsv(content, picked.name),
    );
  }

  Future<void> _exportCsv() async {
    final controller = context.read<InventoryController>();
    final rows = <String>[
      'sku,name,price,tax_rate,stock,barcode',
      for (final p in controller.products)
        '${p.sku},'
        '"${p.name.replaceAll('"', '""')}",'
        '${p.price},'
        '${p.taxRate},'
        '${p.stock.round()},'
        '${p.barcode ?? ''}',
    ];
    final content = rows.join('\n');
    final saved = await FilePickerService.saveTextFile(
      fileName: 'produits.csv',
      content: content,
    );
    if (!mounted) return;
    _showMessage(
      saved != null ? 'Fichier enregistré : $saved' : 'Export annulé',
    );
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _lastUrl = null;
    });
    final url = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastUrl = url;
    });
    _showMessage(
      url != null
          ? 'Upload réussi'
          : 'Upload impossible (hors ligne ou supabase non configuré)',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Stockage & fichiers', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionnez une image ou un CSV : il sera uploadé dans le bucket Supabase et vous pourrez copier son URL.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Image',
                icon: Icons.image_outlined,
                variant: AppButtonVariant.secondary,
                loading: _busy,
                onPressed: _busy ? null : _uploadImage,
              ),
              AppButton(
                label: 'CSV',
                icon: Icons.table_chart_outlined,
                variant: AppButtonVariant.secondary,
                loading: _busy,
                onPressed: _busy ? null : _uploadCsv,
              ),
              AppButton(
                label: 'Exporter produits',
                icon: Icons.download_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: _busy ? null : _exportCsv,
              ),
            ],
          ),
          if (_lastUrl != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                _lastUrl!,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
