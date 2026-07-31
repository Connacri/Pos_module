import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncUseCases = context.watch<SyncUseCases>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SyncCard(syncUseCases: syncUseCases),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _ActionCard(
                icon: Icons.point_of_sale,
                label: l10n.pos,
                color: theme.colorScheme.primary,
                onTap: () => context.go(Routes.pos),
              ),
              _ActionCard(
                icon: Icons.inventory_2_outlined,
                label: l10n.inventory,
                color: theme.colorScheme.secondary,
                onTap: () => context.go(Routes.inventory),
              ),
              _ActionCard(
                icon: Icons.receipt_long_outlined,
                label: l10n.billing,
                color: theme.colorScheme.tertiary,
                onTap: () => context.go(Routes.billing),
              ),
              _ActionCard(
                icon: Icons.settings_outlined,
                label: l10n.settings,
                color: theme.colorScheme.outline,
                onTap: () => context.go(Routes.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatefulWidget {
  const _SyncCard({required this.syncUseCases});

  final SyncUseCases syncUseCases;

  @override
  State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  bool _online = true;
  DateTime? _lastSync;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    widget.syncUseCases.watchOnline().listen((online) {
      if (mounted) setState(() => _online = online);
    });
    widget.syncUseCases.lastSyncAt().then((result) {
      final value = result.fold<DateTime?>((v) => v, (_) => null);
      if (mounted) setState(() => _lastSync = value);
    });
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final result = await widget.syncUseCases.syncAll();
    if (!mounted) return;
    setState(() => _syncing = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
            (_) => AppLocalizations.of(context).syncComplete,
            (failure) => failure.message,
          ),
        ),
      ),
    );
    final last = await widget.syncUseCases.lastSyncAt();
    if (!mounted) return;
    setState(() {
      _lastSync = last.fold<DateTime?>((v) => v, (_) => null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _online ? Colors.green : theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _online ? l10n.online : l10n.offline,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  _lastSync == null
                      ? '${l10n.syncing}...'
                      : '${l10n.syncComplete} ${AppDateUtils.formatDateTime(_lastSync!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Synchroniser',
            icon: Icons.sync,
            loading: _syncing,
            onPressed: _syncing ? null : _sync,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
