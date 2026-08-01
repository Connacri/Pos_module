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
                          label: Text('Clair'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Sombre'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_brightness_outlined),
                          label: Text('Système'),
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
                        ButtonSegment(value: 'fr', label: Text('FR')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                        ButtonSegment(value: 'es', label: Text('ES')),
                        ButtonSegment(value: 'ar', label: Text('AR')),
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
            const _StorageSection(),
            const SizedBox(height: 16),
            const _VersionSection(),
          ],
        ),
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
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Center(
        child: Text(
          '${AppConstants.appName} v${_version ?? AppConstants.appVersion}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
