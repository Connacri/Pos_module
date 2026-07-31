import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pos_billing/pos_billing.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_inventory/pos_inventory.dart';
import 'package:pos_pos/pos_pos.dart';

import 'di/app_dependencies.dart';
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
        ChangeNotifierProvider<PosController>(
          create: (_) => PosController(
            productUseCases: dependencies.productUseCases,
            saleUseCases: dependencies.saleUseCases,
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
      localizationsDelegates: const [AppLocalizations.delegate],
      routerConfig: AppRouter.router,
    );
  }
}
