import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_billing/pos_billing.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_inventory/pos_inventory.dart';
import 'package:pos_pos/pos_pos.dart';

import '../pages/home_shell.dart';
import '../pages/splash_page.dart';
import '../returns/returns_screen.dart';
import '../sales/sale_detail_screen.dart';
import '../settings/settings_page.dart';

List<GoRoute> buildAppRoutes() {
  return [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: Routes.pos,
      builder: (context, state) => const PosScreen(showBackButton: true),
    ),
    GoRoute(
      path: Routes.inventory,
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'];
        return InventoryScreen(
          showBackButton: true,
          initialFilter: switch (filter) {
            'ruptures' => InventoryFilter.outOfStock,
            'low' => InventoryFilter.lowStock,
            _ => null,
          },
        );
      },
    ),
    GoRoute(
      path: Routes.billing,
      builder: (context, state) => BillingScreen(
        showBackButton: true,
        onOpenSale: (sale) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
        ),
      ),
    ),
    GoRoute(
      path: Routes.returns,
      builder: (context, state) => const ReturnsScreen(showBackButton: true),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsPage(showBackButton: true),
    ),
  ];
}
