import 'package:go_router/go_router.dart';

import 'package:pos_billing/pos_billing.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_inventory/pos_inventory.dart';
import 'package:pos_pos/pos_pos.dart';

import '../pages/home_shell.dart';
import '../pages/splash_page.dart';
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
      builder: (context, state) => const PosScreen(),
    ),
    GoRoute(
      path: Routes.inventory,
      builder: (context, state) => const InventoryScreen(),
    ),
    GoRoute(
      path: Routes.billing,
      builder: (context, state) => const BillingScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ];
}
