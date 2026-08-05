import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
            const _IssuerSection(),
            const SizedBox(height: 16),
            const _StorageSection(),
            const SizedBox(height: 16),
            const _DataSection(),
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

class _IssuerSection extends StatefulWidget {
  const _IssuerSection();

  @override
  State<_IssuerSection> createState() => _IssuerSectionState();
}

class _IssuerSectionState extends State<_IssuerSection> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _pickingLogo = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await IssuerSettings.load();
    if (!mounted) return;
    setState(() {
      _nameController.text = data.name ?? '';
      _addressController.text = data.address ?? '';
      _taxIdController.text = data.taxId ?? '';
      _phoneController.text = data.phone ?? '';
      _emailController.text = data.email ?? '';
      _logoUrl = data.logoUrl;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _load();
    setState(() => _editing = false);
  }

  Future<void> _pickLogo() async {
    final picked = await FilePickerService.pickImage();
    if (picked == null || !mounted) return;
    setState(() => _pickingLogo = true);
    final url = await SupabaseStorageService.uploadImage(
      picked.bytes,
      picked.name,
    );
    if (!mounted) return;
    setState(() {
      _pickingLogo = false;
      _logoUrl = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url != null
              ? 'Logo enregistré'
              : 'Upload impossible (hors ligne ou supabase non configuré)',
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await IssuerSettings.save(
      IssuerData(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        taxId: _taxIdController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        logoUrl: _logoUrl,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Émetteur enregistré')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: _editing ? _buildForm(theme) : _buildPreview(theme),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final hasData = _nameController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _taxIdController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _logoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Émetteur', style: theme.textTheme.titleMedium),
            const Spacer(),
            AppButton(
              label: 'Modifier',
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: _startEditing,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasData) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Émetteur non configuré. Cliquez sur « Modifier » pour '
                    'ajouter les coordonnées et le logo affichés sur les factures.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (_logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.network(
                      _logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _logoPlaceholder(theme),
                    ),
                  ),
                )
              else
                _logoPlaceholder(theme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Sans nom'
                          : _nameController.text.trim(),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (_addressController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _addressController.text.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_taxIdController.text.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.badge_outlined,
              text: _taxIdController.text.trim(),
            ),
          if (_phoneController.text.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              text: _phoneController.text.trim(),
            ),
          if (_emailController.text.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.email_outlined,
              text: _emailController.text.trim(),
            ),
        ],
      ],
    );
  }

  Widget _logoPlaceholder(ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.business_outlined,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Modifier l\'émetteur', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Nom, coordonnées et logo affichés sur les factures.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    _logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.business_outlined),
                  ),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton(
                    label: _logoUrl == null
                        ? 'Choisir un logo'
                        : 'Changer le logo',
                    icon: Icons.image_outlined,
                    variant: AppButtonVariant.secondary,
                    loading: _pickingLogo,
                    onPressed: _pickingLogo ? null : _pickLogo,
                  ),
                  if (_logoUrl != null)
                    AppButton(
                      label: 'Retirer',
                      icon: Icons.close,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => setState(() => _logoUrl = null),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nom de l\'entreprise',
          controller: _nameController,
          prefixIcon: const Icon(Icons.business_outlined),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Adresse',
          controller: _addressController,
          prefixIcon: const Icon(Icons.location_on_outlined),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Numéro d\'identification fiscale (NIF)',
          controller: _taxIdController,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Téléphone',
          controller: _phoneController,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Annuler',
                variant: AppButtonVariant.outlined,
                onPressed: _saving ? null : _cancelEditing,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Enregistrer',
                icon: Icons.check,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends StatefulWidget {
  const _DataSection();

  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  String? _busyAction;

  Future<void> _confirmClear({
    required String actionKey,
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyAction = actionKey);
    try {
      await action();
    } catch (e) {
      _showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
    if (!mounted) return;
    _showMessage('Base vidée');
  }

  Future<void> _confirmPopulate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remplir la base locale ?'),
        content: const Text(
          'La base locale sera vidée puis remplie avec les données de '
          'démonstration du script (produits, catégories, clients, ventes, '
          'factures, paiements).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Populate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyAction = 'populate');
    try {
      await SeedService.populateObjectBox();
    } catch (e) {
      _showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
    if (!mounted) return;
    _showMessage('Base locale remplie');
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
                Icons.delete_sweep_outlined,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text('Données', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Videz la base locale (ObjectBox) et/ou la base distante (Supabase). '
            'Action irréversible.',
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
                label: 'Populate (démo)',
                icon: Icons.auto_fix_high_outlined,
                variant: AppButtonVariant.secondary,
                loading: _busyAction == 'populate',
                onPressed: _busyAction == 'populate'
                    ? null
                    : _confirmPopulate,
              ),
              AppButton(
                label: 'Vider base locale',
                icon: Icons.storage_outlined,
                variant: AppButtonVariant.danger,
                loading: _busyAction == 'clear_local',
                onPressed: _busyAction == 'clear_local'
                    ? null
                    : () => _confirmClear(
                          actionKey: 'clear_local',
                          title: 'Vider la base locale ?',
                          message: 'Toutes les données locales seront supprimées '
                              '(produits, catégories, clients, ventes, factures, '
                              'paiements, retours).',
                          action: SeedService.clearObjectBox,
                        ),
              ),
              AppButton(
                label: 'Vider base distante',
                icon: Icons.cloud_off_outlined,
                variant: AppButtonVariant.danger,
                loading: _busyAction == 'clear_remote',
                onPressed: _busyAction == 'clear_remote'
                    ? null
                    : () => _confirmClear(
                          actionKey: 'clear_remote',
                          title: 'Vider la base Supabase ?',
                          message: 'Toutes les tables distantes seront supprimées '
                              '(produits, catégories, clients, ventes, factures, '
                              'paiements, retours).',
                          action: SeedService.clearSupabase,
                        ),
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
  static const String _githubRepo = 'Connacri/Pos_module';

  String? _packageVersion;
  String? _buildNumber;
  String? _latestTag;
  bool _checkingUpdate = true;

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
    await _loadLatestTag();
  }

  /// Récupère le dernier tag publié sur le dépôt GitHub pour afficher la
  /// version à jour. Silencieux en cas d'échec (hors ligne, limites API...).
  Future<void> _loadLatestTag() async {
    String? tag;
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_githubRepo/tags?per_page=1',
      );
      final res = await http
          .get(uri, headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List<dynamic>;
        if (body.isNotEmpty) {
          final name = (body.first as Map<String, dynamic>)['name'];
          if (name is String) tag = name;
        }
      }
    } catch (_) {
      tag = null;
    }
    if (!mounted) return;
    setState(() {
      _latestTag = tag;
      _checkingUpdate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = _packageVersion ?? AppConstants.appVersion;
    final build = _buildNumber;
    final latest = _latestTag;
    final hasUpdate = latest != null &&
        latest.replaceFirst('v', '') != version.replaceFirst('v', '');

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
            const SizedBox(height: 8),
            Text(
              _checkingUpdate
                  ? 'Vérification de la dernière version…'
                  : latest != null
                  ? hasUpdate
                      ? 'Dernière version dispo : $latest'
                      : 'À jour (dernier tag : $latest)'
                  : 'Impossible de vérifier la dernière version',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUpdate
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: hasUpdate ? FontWeight.w600 : null,
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
