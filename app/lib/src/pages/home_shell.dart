import 'package:flutter/material.dart';

import 'package:pos_billing/pos_billing.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_inventory/pos_inventory.dart';
import 'package:pos_pos/pos_pos.dart';

import '../sales/sale_detail_screen.dart';
import '../settings/settings_page.dart';
import 'dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openSale(Sale sale) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
    );
  }

  List<Widget> get _pages => [
    DashboardPage(),
    PosScreen(),
    InventoryScreen(),
    BillingScreen(onOpenSale: _openSale),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        final content = PageFadeTransition(
          child: IndexedStack(
            key: ValueKey(_index),
            index: _index,
            children: _pages,
          ),
        );
        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (index) =>
                      setState(() => _index = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: _barDestinations,
          ),
        );
      },
    );
  }

  List<NavigationRailDestination> get _railDestinations {
    final l10n = AppLocalizations.of(context);
    return [
      NavigationRailDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: Text(l10n.home)),
      NavigationRailDestination(icon: const Icon(Icons.point_of_sale_outlined), selectedIcon: const Icon(Icons.point_of_sale), label: Text(l10n.pos)),
      NavigationRailDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: Text(l10n.inventory)),
      NavigationRailDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: Text(l10n.billing)),
      NavigationRailDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: Text(l10n.settings)),
    ];
  }

  List<NavigationDestination> get _barDestinations {
    final l10n = AppLocalizations.of(context);
    return [
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.home),
      NavigationDestination(icon: const Icon(Icons.point_of_sale_outlined), selectedIcon: const Icon(Icons.point_of_sale), label: l10n.pos),
      NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: l10n.inventory),
      NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.billing),
      NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l10n.settings),
    ];
  }
}
