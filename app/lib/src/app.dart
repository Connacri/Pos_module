import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:pos_billing/pos_billing.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_inventory/pos_inventory.dart';
import 'package:pos_pos/pos_pos.dart';

import 'dashboard/dashboard_controller.dart';
import 'di/app_dependencies.dart';
import 'returns/return_controller.dart';
import 'settings/settings_controller.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider.value(value: dependencies.connectivityService),
        ChangeNotifierProvider<DashboardController>(
          create: (_) => DashboardController(
            saleUseCases: dependencies.saleUseCases,
            productUseCases: dependencies.productUseCases,
            categoryUseCases: dependencies.categoryUseCases,
            customerUseCases: dependencies.customerUseCases,
            invoiceUseCases: dependencies.invoiceUseCases,
          ),
        ),
        ChangeNotifierProvider<PosController>(
          create: (_) => PosController(
            productUseCases: dependencies.productUseCases,
            saleUseCases: dependencies.saleUseCases,
            invoiceUseCases: dependencies.invoiceUseCases,
          ),
        ),
        ChangeNotifierProvider<InventoryController>(
          create: (_) => InventoryController(
            productUseCases: dependencies.productUseCases,
            categoryUseCases: dependencies.categoryUseCases,
          ),
        ),
        ChangeNotifierProvider<BillingController>(
          create: (_) => BillingController(
            invoiceUseCases: dependencies.invoiceUseCases,
            customerUseCases: dependencies.customerUseCases,
            saleUseCases: dependencies.saleUseCases,
          ),
        ),
        ChangeNotifierProvider<ReturnController>(
          create: (_) => ReturnController(
            returnUseCases: dependencies.returnUseCases,
            saleUseCases: dependencies.saleUseCases,
            customerUseCases: dependencies.customerUseCases,
          ),
        ),
        Provider<SyncUseCases>.value(value: dependencies.syncUseCases),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
