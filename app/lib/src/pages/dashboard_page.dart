import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../customers/customers_list_screen.dart';
import '../dashboard/dashboard_controller.dart';
import '../sales/sales_list_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<DashboardController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight:
                        ResponsiveLayout.isDesktop(context) ? 200 : 168,
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
                    flexibleSpace: FlexibleSpaceBar(
                      background: _ParallaxHeader(
                        primary: theme.colorScheme.primary,
                        secondary: theme.colorScheme.secondary,
                        tertiary: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        AnimatedEntrance(
                          child: _KpiGrid(controller: controller),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: _RevenueCard(controller: controller),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 180),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 900;
                              final categoryChart = _CategoryCard(
                                data: controller.categorySales,
                              );
                              final topProducts = _ChartCard(
                                title: 'Top produits',
                                subtitle: 'Par quantité vendue',
                                child: _TopProducts(
                                  data: controller.topProducts,
                                ),
                              );
                              if (isDesktop) {
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 240),
                          child: _SecondaryMetrics(controller: controller),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 320),
                          child: _SyncCard(
                            syncUseCases: context.watch<SyncUseCases>(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 400),
                          child: GridView.count(
                            crossAxisCount:
                                ResponsiveLayout.isDesktop(context) ? 4 : 2,
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
                                icon: Icons.replay_outlined,
                                label: 'Retours',
                                color: theme.colorScheme.error,
                                onTap: () => context.go(Routes.returns),
                              ),
                              _ActionCard(
                                icon: Icons.settings_outlined,
                                label: l10n.settings,
                                color: theme.colorScheme.outline,
                                onTap: () => context.go(Routes.settings),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ParallaxHeader extends StatelessWidget {
  const _ParallaxHeader({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.12),
                tertiary.withValues(alpha: 0.06),
                secondary.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: GlowOrb(color: primary, size: 200),
        ),
        Positioned(
          bottom: -90,
          left: -40,
          child: GlowOrb(color: secondary, size: 220),
        ),
        Positioned(
          top: 10,
          left: 60,
          child: GlowOrb(color: tertiary, size: 90),
        ),
      ],
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
        onTap: () => _openSalesList(
          context,
          title: 'Ventes du jour',
          sales: controller.todaySales,
          controller: controller,
        ),
      ),
      _Kpi(
        label: 'Ventes aujourd\'hui',
        value: '${controller.salesTodayCount}',
        icon: Icons.receipt_long_outlined,
        color: scheme.secondary,
        onTap: () => _openSalesList(
          context,
          title: 'Ventes du jour',
          sales: controller.todaySales,
          controller: controller,
        ),
      ),
      _Kpi(
        label: 'Panier moyen',
        value: CurrencyUtils.format(controller.averageBasket),
        icon: Icons.shopping_cart_outlined,
        color: scheme.tertiary,
        onTap: () => _openSalesList(
          context,
          title: 'Toutes les ventes',
          sales: controller.completedSales,
          controller: controller,
        ),
      ),
      _Kpi(
        label: 'Créances clients',
        value: CurrencyUtils.format(controller.outstandingAmount),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
        onTap: () => context.go(Routes.billing),
      ),
    ];

    return GridView.count(
      crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: ResponsiveLayout.isDesktop(context) ? 2.3 : 1.4,
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
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: kpi.onTap,
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
      _MetricChipData(
        label: 'Produits',
        value: '${controller.totalProducts}',
        icon: Icons.inventory_2_outlined,
        color: theme.colorScheme.primary,
        onTap: () => context.go(Routes.inventory),
      ),
      _MetricChipData(
        label: 'Valeur du stock',
        value: CurrencyUtils.format(controller.stockValue),
        icon: Icons.payments_outlined,
        color: theme.colorScheme.tertiary,
        onTap: () => context.go(Routes.inventory),
      ),
      _MetricChipData(
        label: 'Ruptures',
        value: '${controller.outOfStockCount}',
        icon: Icons.block,
        color: theme.colorScheme.error,
        onTap: () => context.go('${Routes.inventory}?filter=ruptures'),
      ),
      _MetricChipData(
        label: 'Clients',
        value: '${controller.customerCount}',
        icon: Icons.people_outline,
        color: theme.colorScheme.secondary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CustomersListScreen(customers: controller.customers),
          ),
        ),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final item in items) _MetricChip(data: item)],
    );
  }
}

class _MetricChipData {
  const _MetricChipData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.data});

  final _MetricChipData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 16, color: data.color),
            const SizedBox(width: 6),
            Text(
              '${data.label} : ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              data.value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profitColor = controller.profitLast7Days >= 0
        ? Colors.green
        : theme.colorScheme.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chiffre d\'affaires (7 derniers jours)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            '${CurrencyUtils.format(controller.revenueLast7Days)} au total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _RevenueChart(data: controller.revenueByDay),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RevenueStat(
                  label: 'CA',
                  value: controller.revenueLast7Days,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RevenueStat(
                  label: 'Coût',
                  value: controller.costLast7Days,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RevenueStat(
                  label: 'Bénéfice',
                  value: controller.profitLast7Days,
                  color: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueStat extends StatelessWidget {
  const _RevenueStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyUtils.format(value),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.data});

  final List<CategorySaleStats> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ventes par catégorie', style: theme.textTheme.titleSmall),
          const SizedBox(height: 16),
          _CategoryChart(data: data),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});

  final List<CategorySaleStats> data;

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
    final total = data.fold<double>(0, (s, e) => s + e.revenue);

    if (total <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Aucune vente pour le moment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _LegendItem(
              color: _palette[i % _palette.length],
              stats: data[i],
              total: total,
            ),
          ),
      ],
    );

    final chart = SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 52,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].revenue,
                    color: _palette[i % _palette.length],
                    radius: 48,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyUtils.format(total),
                    style: AppTextStyles.money(theme.colorScheme.primary),
                  ),
                ),
                Text(
                  'CA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final isMobile = ResponsiveLayout.isMobile(context);
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Center(child: chart),
            const SizedBox(height: 24),
            legend,
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          chart,
          const SizedBox(width: 24),
          Expanded(child: legend),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.stats,
    required this.total,
  });

  final Color color;
  final CategorySaleStats stats;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profitColor =
        stats.profit >= 0 ? Colors.green : theme.colorScheme.error;
    final percent = total <= 0 ? 0 : (stats.revenue / total * 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${stats.salesCount} vente(s) • ${percent.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _LegendValue(
                label: 'CA',
                value: stats.revenue,
                color: theme.colorScheme.primary,
              ),
              _LegendValue(
                label: 'Coût',
                value: stats.cost,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _LegendValue(
                label: 'Bénéfice',
                value: stats.profit,
                color: profitColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyUtils.format(value),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
  DateTime? _lastSync;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
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
    final connectivity = context.watch<ConnectivityService>();
    final online = connectivity.isOnline;
    final supabaseOnline = connectivity.isSupabaseOnline;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(connected: online),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? l10n.online : l10n.offline,
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _IndicatorPill(
                label: 'Internet',
                connected: online,
                color: theme.colorScheme,
              ),
              const SizedBox(width: 8),
              _IndicatorPill(
                label: 'Supabase',
                connected: supabaseOnline,
                color: theme.colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Synchroniser',
            icon: Icons.sync,
            loading: _syncing,
            expanded: true,
            onPressed: _syncing ? null : _sync,
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected ? Colors.green : theme.colorScheme.error,
      ),
    );
  }
}

class _IndicatorPill extends StatelessWidget {
  const _IndicatorPill({
    required this.label,
    required this.connected,
    required this.color,
  });

  final String label;
  final bool connected;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    final statusColor = connected ? Colors.green : color.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
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

void _openSalesList(
  BuildContext context, {
  required String title,
  required List<Sale> sales,
  required DashboardController controller,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SalesListScreen(
        title: title,
        sales: sales,
        customerName: (id) => controller.customers
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull,
      ),
    ),
  );
}
