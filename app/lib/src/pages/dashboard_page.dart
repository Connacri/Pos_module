import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../dashboard/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                AppDateUtils.formatDate(DateTime.now()),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _KpiGrid(controller: controller),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: 'Chiffre d\'affaires (7 derniers jours)',
                    subtitle:
                        '${CurrencyUtils.format(controller.totalRevenue)} au total',
                    child: SizedBox(
                      height: 220,
                      child: _RevenueChart(data: controller.revenueByDay),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      final categoryChart = _ChartCard(
                        title: 'Ventes par catégorie',
                        child: SizedBox(
                          height: 220,
                          child: _CategoryChart(
                            data: controller.revenueByCategory,
                          ),
                        ),
                      );
                      final topProducts = _ChartCard(
                        title: 'Top produits',
                        subtitle: 'Par quantité vendue',
                        child: _TopProducts(data: controller.topProducts),
                      );
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: categoryChart),
                            const SizedBox(width: 16),
                            Expanded(child: topProducts),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          categoryChart,
                          const SizedBox(height: 16),
                          topProducts,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _SecondaryMetrics(controller: controller),
                  const SizedBox(height: 16),
                  _SyncCard(syncUseCases: context.watch<SyncUseCases>()),
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
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final kpis = [
      _Kpi(
        label: 'CA aujourd\'hui',
        value: CurrencyUtils.format(controller.revenueToday),
        icon: Icons.trending_up,
        color: scheme.primary,
      ),
      _Kpi(
        label: 'Ventes aujourd\'hui',
        value: '${controller.salesTodayCount}',
        icon: Icons.receipt_long_outlined,
        color: scheme.secondary,
      ),
      _Kpi(
        label: 'Panier moyen',
        value: CurrencyUtils.format(controller.averageBasket),
        icon: Icons.shopping_cart_outlined,
        color: scheme.tertiary,
      ),
      _Kpi(
        label: 'Créances clients',
        value: CurrencyUtils.format(controller.outstandingAmount),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: ResponsiveLayout.isDesktop(context) ? 2.4 : 1.5,
      children: [for (final kpi in kpis) _KpiCard(kpi: kpi)],
    );
  }
}

class _Kpi {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(kpi.icon, size: 18, color: kpi.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kpi.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            kpi.value,
            style: AppTextStyles.titleLarge(kpi.color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetrics extends StatelessWidget {
  const _SecondaryMetrics({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Produits', '${controller.totalProducts}', Icons.inventory_2_outlined),
      (
        'Valeur du stock',
        CurrencyUtils.format(controller.stockValue),
        Icons.payments_outlined,
      ),
      ('Ruptures', '${controller.outOfStockCount}', Icons.block),
      ('Clients', '${controller.customerCount}', Icons.people_outline),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value, icon) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '$label : ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});

  final List<(DateTime, double)> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final maxValue = data.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].$2,
                  color: color,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compact(value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final day = data[index].$1;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _dayLabel(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = data[group.x].$2;
              return BarTooltipItem(
                '${_dayLabel(data[group.x].$1)}\n'
                '${CurrencyUtils.format(value)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});

  final List<(String, double)> data;

  static const _palette = [
    Color(0xFF1976D2),
    Color(0xFF26A69A),
    Color(0xFF7E57C2),
    Color(0xFFED6C02),
    Color(0xFF0288D1),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.fold<double>(0, (s, e) => s + e.$2);

    if (total <= 0) {
      return Center(
        child: Text(
          'Aucune vente pour le moment',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].$2,
                    color: _palette[i % _palette.length],
                    radius: 48,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < data.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data[i].$1,
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(data[i].$2 / total * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.data});

  final List<(String, double)> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Aucune vente pour le moment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final max = data.first.$2;

    return Column(
      children: [
        for (final (name, qty) in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    name,
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max <= 0 ? 0 : qty / max,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${qty.round()}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

String _dayLabel(DateTime date) {
  const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  return weekdays[date.weekday - 1];
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toStringAsFixed(0);
}
