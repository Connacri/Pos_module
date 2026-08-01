#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
POS Module - Générateur de projet complet
Flutter + ObjectBox + Supabase + Clean Architecture
"""

import os
import sys
from pathlib import Path
import textwrap

# ============================================================================
# CONFIGURATION
# ============================================================================
PROJECT_NAME = "Pos_module"
ROOT_FILES = {}
PACKAGES = {}

def write_file(path: str, content: str):
    """Crée un fichier avec son contenu, en créant les dossiers parents si nécessaire."""
    file_path = Path(path)
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")
    print(f"  ✓ {path}")

# ============================================================================
# FICHIERS RACINE
# ============================================================================
print(f"\n📁 Création du projet : {PROJECT_NAME}\n")

# --- pubspec.yaml (workspace) ---
write_file(f"{PROJECT_NAME}/pubspec.yaml", """
    name: pos_module_workspace
    description: Module POS cross-platform - Flutter, ObjectBox, Supabase
    publish_to: none
    version: 1.0.0+1
    environment:
      sdk: '>=3.3.0 <4.0.0'
      flutter: ">=3.19.0"
    workspace:
      - app
      - packages/pos_core
      - packages/pos_domain
      - packages/pos_data
      - packages/pos_pos
      - packages/pos_inventory
      - packages/pos_billing
      - packages/pos_reports
    dependencies:
      flutter:
        sdk: flutter
    dev_dependencies:
      flutter_test:
        sdk: flutter
      flutter_lints: ^4.0.0
""")

# --- analysis_options.yaml ---
write_file(f"{PROJECT_NAME}/analysis_options.yaml", """
    include: package:flutter_lints/flutter.yaml
    linter:
      rules:
        - always_declare_return_types
        - annotate_overrides
        - avoid_empty_else
        - avoid_print
        - prefer_const_constructors
        - prefer_const_declarations
        - prefer_final_fields
        - prefer_single_quotes
        - sort_child_widgets_last
        - use_key_in_widget_constructors
    analyzer:
      exclude:
        - "**/*.g.dart"
        - "**/*.freezed.dart"
        - "**/generated/**"
""")

# --- build.yaml ---
write_file(f"{PROJECT_NAME}/build.yaml", """
    targets:
      $default:
        builders:
          objectbox_generator|resolver:
            generate_for:
              include:
                - packages/pos_data/lib/**/*.dart
          json_serializable:
            generate_for:
              include:
                - packages/pos_domain/lib/**/*.dart
                - packages/pos_data/lib/**/*.dart
            options:
              explicit_to_json: true
              field_rename: snake
""")

# --- .gitignore ---
write_file(f"{PROJECT_NAME}/.gitignore", """
    .dart_tool/
    .packages
    build/
    .flutter-plugins
    .flutter-plugins-dependencies
    pubspec.lock
    *.g.dart
    objectbox-model.json
    .idea/
    .vscode/
    *.iml
    .DS_Store
    Thumbs.db
    .env
    .env.local
    coverage/
""")

# --- melos.yaml ---
write_file(f"{PROJECT_NAME}/melos.yaml", """
    name: pos_module
    repository: https://github.com/Connacri/Pos_module
    packages:
      - app
      - packages/*
    command:
      bootstrap:
        usePubspecOverrides: true
    scripts:
      analyze:
        exec: flutter analyze --no-pub
      test:all:
        exec: flutter test --coverage
      build:runner:
        exec: dart run build_runner build --delete-conflicting-outputs
        packageFilters:
          dependsOn: build_runner
""")

# --- README.md ---
write_file(f"{PROJECT_NAME}/README.md", """
    # POS Module - Flutter Cross-Platform
    
    Module de Point de Vente complet, modulaire et cross-platform construit avec Flutter, ObjectBox et Supabase.
    
    ## 🏗️ Architecture
    
    Clean Architecture organisée en packages Dart séparés :
    
    - **`pos_core`** : Thème Material 3, i18n (FR/EN/ES/AR), routing, utilitaires
    - **`pos_domain`** : Entities, use cases, interfaces de repositories
    - **`pos_data`** : Implémentations ObjectBox, Supabase, PowerSync
    - **`pos_pos`** : Feature caisse (interface de vente)
    - **`pos_inventory`** : Feature gestion de stock
    - **`pos_billing`** : Feature facturation
    - **`pos_reports`** : Dashboard et rapports
    - **`app`** : Application hôte
    
    ## ✨ Fonctionnalités
    
    - ✅ Multiplateforme : Android, iOS, Web, Windows, macOS, Linux
    - ✅ Material 3 avec mode clair/sombre
    - ✅ Multilingue (FR, EN, ES, AR)
    - ✅ Mode hors-ligne avec ObjectBox + PowerSync
    - ✅ Synchronisation temps réel Supabase
    - ✅ Layout adaptatif (mobile/tablette/desktop)
    - ✅ Impression PDF (tickets 80mm + factures A4)
    - ✅ Gestion des taxes multiples
    - ✅ Import/Export CSV/Excel
    - ✅ Clean Architecture testable
    
    ## 🚀 Démarrage rapide
    
    ```bash
    # 1. Installer les dépendances
    flutter pub get
    
    # 2. Générer le code ObjectBox
    cd packages/pos_data
    dart run build_runner build --delete-conflicting-outputs
    cd ../..
    
    # 3. Configurer Supabase
    # Éditer app/lib/src/config/app_config.dart
    
    # 4. Lancer l'app
    cd app
    flutter run
    ```
    
    ## 📄 Licence
    
    Propriétaire - Tous droits réservés
""")

print("\n✅ Fichiers racine créés\n")

# ============================================================================
# PACKAGE: pos_core
# ============================================================================
print("📦 Package: pos_core")

write_file(f"{PROJECT_NAME}/packages/pos_core/pubspec.yaml", """
    name: pos_core
    description: Core utilities, theme, i18n, routing for POS module
    version: 1.0.0
    publish_to: none
    environment:
      sdk: '>=3.3.0 <4.0.0'
      flutter: ">=3.19.0"
    dependencies:
      flutter:
        sdk: flutter
      flutter_localizations:
        sdk: flutter
      go_router: ^14.2.0
      provider: ^6.1.2
      intl: ^0.19.0
      logger: ^2.3.0
      connectivity_plus: ^6.0.3
      shared_preferences: ^2.2.3
      path_provider: ^2.1.3
    dev_dependencies:
      flutter_test:
        sdk: flutter
      flutter_lints: ^4.0.0
    flutter:
      uses-material-design: true
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/pos_core.dart", """
    library pos_core;
    
    export 'src/theme/app_theme.dart';
    export 'src/theme/app_colors.dart';
    export 'src/i18n/app_localizations.dart';
    export 'src/routing/app_router.dart';
    export 'src/routing/routes.dart';
    export 'src/utils/logger.dart';
    export 'src/utils/connectivity_service.dart';
    export 'src/utils/date_utils.dart';
    export 'src/utils/currency_utils.dart';
    export 'src/utils/validators.dart';
    export 'src/constants/app_constants.dart';
    export 'src/widgets/app_button.dart';
    export 'src/widgets/app_text_field.dart';
    export 'src/widgets/app_card.dart';
    export 'src/widgets/responsive_layout.dart';
    export 'src/widgets/loading_overlay.dart';
    export 'src/widgets/empty_state.dart';
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/theme/app_colors.dart", """
    import 'package:flutter/material.dart';
    
    class AppColors {
      AppColors._();
    
      static const Color primaryLight = Color(0xFF1976D2);
      static const Color primaryDark = Color(0xFF90CAF9);
      static const Color onPrimaryLight = Color(0xFFFFFFFF);
      static const Color onPrimaryDark = Color(0xFF003258);
    
      static const Color secondaryLight = Color(0xFF26A69A);
      static const Color secondaryDark = Color(0xFF80CBC4);
    
      static const Color tertiaryLight = Color(0xFF7E57C2);
      static const Color tertiaryDark = Color(0xFFD1C4E9);
    
      static const Color success = Color(0xFF2E7D32);
      static const Color warning = Color(0xFFED6C02);
      static const Color error = Color(0xFFD32F2F);
      static const Color info = Color(0xFF0288D1);
    
      static const Color surfaceLight = Color(0xFFFEFEFE);
      static const Color surfaceDark = Color(0xFF121212);
      static const Color backgroundLight = Color(0xFFFAFAFA);
      static const Color backgroundDark = Color(0xFF0A0A0A);
    
      static Color statusColor(String status) {
        switch (status.toLowerCase()) {
          case 'paid':
          case 'completed':
          case 'active':
            return success;
          case 'pending':
          case 'processing':
            return warning;
          case 'cancelled':
          case 'failed':
          case 'returned':
            return error;
          default:
            return info;
        }
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/theme/app_theme.dart", """
    import 'package:flutter/material.dart';
    import 'app_colors.dart';
    
    class AppTheme {
      AppTheme._();
    
      static ThemeData lightTheme() {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          tertiary: AppColors.tertiaryLight,
          brightness: Brightness.light,
          surface: AppColors.surfaceLight,
        );
        return _buildTheme(colorScheme);
      }
    
      static ThemeData darkTheme() {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
          tertiary: AppColors.tertiaryDark,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark,
        );
        return _buildTheme(colorScheme);
      }
    
      static ThemeData _buildTheme(ColorScheme colorScheme) {
        return ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: colorScheme.surface,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            color: colorScheme.surface,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/i18n/app_localizations.dart", """
    import 'package:flutter/foundation.dart';
    import 'package:flutter/widgets.dart';
    
    class AppLocalizations {
      final Locale locale;
      AppLocalizations(this.locale);
    
      static AppLocalizations of(BuildContext context) {
        return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      }
    
      static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
    
      static const List<Locale> supportedLocales = [
        Locale('fr'), Locale('en'), Locale('es'), Locale('ar'),
      ];
    
      static const Map<String, Map<String, String>> _localizedValues = {
        'fr': {
          'appTitle': 'Module POS', 'home': 'Accueil', 'pos': 'Caisse',
          'inventory': 'Stock', 'billing': 'Facturation', 'reports': 'Rapports',
          'settings': 'Paramètres', 'products': 'Produits', 'categories': 'Catégories',
          'customers': 'Clients', 'sales': 'Ventes', 'invoices': 'Factures',
          'search': 'Rechercher', 'add': 'Ajouter', 'edit': 'Modifier',
          'delete': 'Supprimer', 'save': 'Enregistrer', 'cancel': 'Annuler',
          'confirm': 'Confirmer', 'name': 'Nom', 'price': 'Prix',
          'quantity': 'Quantité', 'total': 'Total', 'tax': 'Taxe',
          'discount': 'Remise', 'subtotal': 'Sous-total', 'payment': 'Paiement',
          'cash': 'Espèces', 'card': 'Carte', 'checkout': 'Encaisser',
          'newSale': 'Nouvelle vente', 'emptyCart': 'Panier vide',
          'addToCart': 'Ajouter au panier', 'lowStock': 'Stock faible',
          'outOfStock': 'Rupture de stock', 'sku': 'SKU', 'barcode': 'Code-barres',
          'print': 'Imprimer', 'export': 'Exporter', 'import': 'Importer',
          'loading': 'Chargement...', 'error': 'Erreur', 'success': 'Succès',
          'noData': 'Aucune donnée', 'offline': 'Hors ligne', 'online': 'En ligne',
        },
        'en': {
          'appTitle': 'POS Module', 'home': 'Home', 'pos': 'POS',
          'inventory': 'Inventory', 'billing': 'Billing', 'reports': 'Reports',
          'settings': 'Settings', 'products': 'Products', 'categories': 'Categories',
          'customers': 'Customers', 'sales': 'Sales', 'invoices': 'Invoices',
          'search': 'Search', 'add': 'Add', 'edit': 'Edit',
          'delete': 'Delete', 'save': 'Save', 'cancel': 'Cancel',
          'confirm': 'Confirm', 'name': 'Name', 'price': 'Price',
          'quantity': 'Quantity', 'total': 'Total', 'tax': 'Tax',
          'discount': 'Discount', 'subtotal': 'Subtotal', 'payment': 'Payment',
          'cash': 'Cash', 'card': 'Card', 'checkout': 'Checkout',
          'newSale': 'New sale', 'emptyCart': 'Empty cart',
          'addToCart': 'Add to cart', 'lowStock': 'Low stock',
          'outOfStock': 'Out of stock', 'sku': 'SKU', 'barcode': 'Barcode',
          'print': 'Print', 'export': 'Export', 'import': 'Import',
          'loading': 'Loading...', 'error': 'Error', 'success': 'Success',
          'noData': 'No data', 'offline': 'Offline', 'online': 'Online',
        },
        'es': {
          'appTitle': 'Módulo POS', 'home': 'Inicio', 'pos': 'Caja',
          'inventory': 'Inventario', 'billing': 'Facturación', 'reports': 'Informes',
          'settings': 'Ajustes', 'products': 'Productos', 'total': 'Total',
          'checkout': 'Cobrar', 'search': 'Buscar', 'cancel': 'Cancelar',
        },
        'ar': {
          'appTitle': 'وحدة نقطة البيع', 'home': 'الرئيسية', 'pos': 'نقطة البيع',
          'inventory': 'المخزون', 'billing': 'الفواتير', 'reports': 'التقارير',
          'settings': 'الإعدادات', 'products': 'المنتجات', 'total': 'المجموع',
          'checkout': 'الدفع', 'search': 'بحث', 'cancel': 'إلغاء',
        },
      };
    
      String translate(String key) {
        return _localizedValues[locale.languageCode]?[key] ??
            _localizedValues['fr']?[key] ?? key;
      }
    
      String get appTitle => translate('appTitle');
      String get home => translate('home');
      String get pos => translate('pos');
      String get inventory => translate('inventory');
      String get billing => translate('billing');
      String get reports => translate('reports');
      String get settings => translate('settings');
      String get products => translate('products');
      String get categories => translate('categories');
      String get customers => translate('customers');
      String get sales => translate('sales');
      String get invoices => translate('invoices');
      String get search => translate('search');
      String get add => translate('add');
      String get edit => translate('edit');
      String get delete => translate('delete');
      String get save => translate('save');
      String get cancel => translate('cancel');
      String get confirm => translate('confirm');
      String get name => translate('name');
      String get price => translate('price');
      String get quantity => translate('quantity');
      String get total => translate('total');
      String get tax => translate('tax');
      String get discount => translate('discount');
      String get subtotal => translate('subtotal');
      String get payment => translate('payment');
      String get cash => translate('cash');
      String get card => translate('card');
      String get checkout => translate('checkout');
      String get newSale => translate('newSale');
      String get emptyCart => translate('emptyCart');
      String get addToCart => translate('addToCart');
      String get lowStock => translate('lowStock');
      String get outOfStock => translate('outOfStock');
      String get sku => translate('sku');
      String get barcode => translate('barcode');
      String get print => translate('print');
      String get export => translate('export');
      String get import => translate('import');
      String get loading => translate('loading');
      String get error => translate('error');
      String get success => translate('success');
      String get noData => translate('noData');
      String get offline => translate('offline');
      String get online => translate('online');
    }
    
    class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
      const _AppLocalizationsDelegate();
    
      @override
      bool isSupported(Locale locale) {
        return AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
      }
    
      @override
      Future<AppLocalizations> load(Locale locale) {
        return SynchronousFuture(AppLocalizations(locale));
      }
    
      @override
      bool shouldReload(_AppLocalizationsDelegate old) => false;
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/routing/routes.dart", """
    class Routes {
      Routes._();
      static const String splash = '/';
      static const String home = '/home';
      static const String pos = '/pos';
      static const String inventory = '/inventory';
      static const String products = '/inventory/products';
      static const String categories = '/inventory/categories';
      static const String customers = '/customers';
      static const String sales = '/sales';
      static const String billing = '/billing';
      static const String invoices = '/billing/invoices';
      static const String reports = '/reports';
      static const String settings = '/settings';
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/routing/app_router.dart", """
    import 'package:flutter/material.dart';
    import 'package:go_router/go_router.dart';
    import 'routes.dart';
    
    class AppRouter {
      static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    
      static final GoRouter router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: Routes.home,
        routes: [],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Page not found: \\${state.uri}')),
        ),
      );
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/utils/logger.dart", """
    import 'package:logger/logger.dart';
    
    class AppLogger {
      static final Logger _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
        ),
      );
    
      static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
        _logger.d(message, error: error, stackTrace: stackTrace);
      }
    
      static void info(String message, [dynamic error, StackTrace? stackTrace]) {
        _logger.i(message, error: error, stackTrace: stackTrace);
      }
    
      static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
        _logger.w(message, error: error, stackTrace: stackTrace);
      }
    
      static void error(String message, [dynamic error, StackTrace? stackTrace]) {
        _logger.e(message, error: error, stackTrace: stackTrace);
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/utils/connectivity_service.dart", """
    import 'dart:async';
    import 'package:connectivity_plus/connectivity_plus.dart';
    import 'package:flutter/foundation.dart';
    
    class ConnectivityService extends ChangeNotifier {
      final Connectivity _connectivity = Connectivity();
      bool _isOnline = true;
      StreamSubscription<List<ConnectivityResult>>? _subscription;
    
      ConnectivityService() {
        _init();
      }
    
      bool get isOnline => _isOnline;
    
      Future<void> _init() async {
        final results = await _connectivity.checkConnectivity();
        _updateConnectionStatus(results);
        _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      }
    
      void _updateConnectionStatus(List<ConnectivityResult> results) {
        final hasConnection = results.any((r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet);
        if (_isOnline != hasConnection) {
          _isOnline = hasConnection;
          notifyListeners();
        }
      }
    
      @override
      void dispose() {
        _subscription?.cancel();
        super.dispose();
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/utils/date_utils.dart", """
    import 'package:intl/intl.dart';
    
    class AppDateUtils {
      AppDateUtils._();
    
      static String formatDate(DateTime date, {String locale = 'fr'}) {
        return DateFormat.yMMMd(locale).format(date);
      }
    
      static String formatDateTime(DateTime date, {String locale = 'fr'}) {
        return DateFormat.yMMMd(locale).add_Hms().format(date);
      }
    
      static String formatTime(DateTime date, {String locale = 'fr'}) {
        return DateFormat.Hms(locale).format(date);
      }
    
      static String formatInvoiceNumber(int number) {
        return 'F-\\${number.toString().padLeft(6, '0')}';
      }
    
      static String formatSaleNumber(int number) {
        return 'V-\\${number.toString().padLeft(6, '0')}';
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/utils/currency_utils.dart", """
    import 'package:intl/intl.dart';
    
    class CurrencyUtils {
      CurrencyUtils._();
    
      static String format(double amount, {String locale = 'fr_FR', String symbol = 'DA'}) {
        final formatter = NumberFormat.currency(
          locale: locale,
          symbol: symbol,
          decimalDigits: 2,
        );
        return formatter.format(amount);
      }
    
      static double parse(String value) {
        final cleaned = value.replaceAll(RegExp(r'[^\\d.,]'), '').replaceAll(',', '.');
        return double.tryParse(cleaned) ?? 0.0;
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/utils/validators.dart", """
    class Validators {
      Validators._();
    
      static String? required(String? value, [String fieldName = 'Ce champ']) {
        if (value == null || value.trim().isEmpty) {
          return '\\$fieldName est requis';
        }
        return null;
      }
    
      static String? email(String? value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\\$');
        if (!regex.hasMatch(value)) return 'Email invalide';
        return null;
      }
    
      static String? phone(String? value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(r'^\\+?[\\d\\s-]{8,15}\\$');
        if (!regex.hasMatch(value)) return 'Numéro de téléphone invalide';
        return null;
      }
    
      static String? positiveNumber(String? value) {
        if (value == null || value.isEmpty) return null;
        final number = double.tryParse(value.replaceAll(',', '.'));
        if (number == null || number < 0) return 'Doit être un nombre positif';
        return null;
      }
    
      static String? sku(String? value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(r'^[A-Z0-9\\-]{3,30}\\$');
        if (!regex.hasMatch(value.toUpperCase())) {
          return 'SKU invalide (3-30 caractères alphanumériques)';
        }
        return null;
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/constants/app_constants.dart", """
    class AppConstants {
      AppConstants._();
    
      static const String appName = 'POS Module';
      static const String appVersion = '1.0.0';
    
      static const String keyThemeMode = 'theme_mode';
      static const String keyLocale = 'locale';
      static const String keyAccessToken = 'access_token';
      static const String keyRefreshToken = 'refresh_token';
      static const String keyUserId = 'user_id';
      static const String keyLastSync = 'last_sync';
    
      static const int defaultPageSize = 20;
      static const int maxPageSize = 100;
    
      static const Duration httpTimeout = Duration(seconds: 30);
      static const Duration syncInterval = Duration(minutes: 5);
    
      static const int lowStockThreshold = 5;
      static const int criticalStockThreshold = 2;
    
      static const double defaultTaxRate = 0.19;
      static const String defaultCurrency = 'DZD';
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/app_button.dart", """
    import 'package:flutter/material.dart';
    
    enum AppButtonVariant { primary, secondary, outlined, text, danger }
    
    class AppButton extends StatelessWidget {
      final String label;
      final VoidCallback? onPressed;
      final AppButtonVariant variant;
      final IconData? icon;
      final bool loading;
      final bool expanded;
    
      const AppButton({
        super.key,
        required this.label,
        this.onPressed,
        this.variant = AppButtonVariant.primary,
        this.icon,
        this.loading = false,
        this.expanded = false,
      });
    
      @override
      Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final child = loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getForegroundColor(theme),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ],
              );
    
        Widget button;
        switch (variant) {
          case AppButtonVariant.primary:
            button = FilledButton(onPressed: onPressed, child: child);
            break;
          case AppButtonVariant.secondary:
            button = FilledButton.tonal(onPressed: onPressed, child: child);
            break;
          case AppButtonVariant.outlined:
            button = OutlinedButton(onPressed: onPressed, child: child);
            break;
          case AppButtonVariant.text:
            button = TextButton(onPressed: onPressed, child: child);
            break;
          case AppButtonVariant.danger:
            button = FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: child,
            );
            break;
        }
    
        return expanded ? SizedBox(width: double.infinity, child: button) : button;
      }
    
      Color _getForegroundColor(ThemeData theme) {
        switch (variant) {
          case AppButtonVariant.primary:
          case AppButtonVariant.danger:
            return theme.colorScheme.onPrimary;
          case AppButtonVariant.secondary:
            return theme.colorScheme.onSecondaryContainer;
          default:
            return theme.colorScheme.primary;
        }
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/app_text_field.dart", """
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';
    
    class AppTextField extends StatelessWidget {
      final String label;
      final String? hint;
      final TextEditingController? controller;
      final String? Function(String?)? validator;
      final TextInputType keyboardType;
      final List<TextInputFormatter>? inputFormatters;
      final Widget? prefixIcon;
      final Widget? suffixIcon;
      final bool obscureText;
      final bool readOnly;
      final VoidCallback? onTap;
      final ValueChanged<String>? onChanged;
      final int? maxLines;
      final int? minLines;
    
      const AppTextField({
        super.key,
        required this.label,
        this.hint,
        this.controller,
        this.validator,
        this.keyboardType = TextInputType.text,
        this.inputFormatters,
        this.prefixIcon,
        this.suffixIcon,
        this.obscureText = false,
        this.readOnly = false,
        this.onTap,
        this.onChanged,
        this.maxLines = 1,
        this.minLines,
      });
    
      @override
      Widget build(BuildContext context) {
        return TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        );
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/app_card.dart", """
    import 'package:flutter/material.dart';
    
    class AppCard extends StatelessWidget {
      final Widget child;
      final EdgeInsetsGeometry? padding;
      final VoidCallback? onTap;
    
      const AppCard({super.key, required this.child, this.padding, this.onTap});
    
      @override
      Widget build(BuildContext context) {
        final card = Card(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );
        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: card,
          );
        }
        return card;
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/responsive_layout.dart", """
    import 'package:flutter/material.dart';
    
    class ResponsiveLayout {
      static const double mobileBreakpoint = 600;
      static const double tabletBreakpoint = 900;
      static const double desktopBreakpoint = 1200;
    
      static bool isMobile(BuildContext context) =>
          MediaQuery.sizeOf(context).width < mobileBreakpoint;
      static bool isTablet(BuildContext context) {
        final width = MediaQuery.sizeOf(context).width;
        return width >= mobileBreakpoint && width < tabletBreakpoint;
      }
      static bool isDesktop(BuildContext context) =>
          MediaQuery.sizeOf(context).width >= tabletBreakpoint;
    }
    
    class ResponsiveBuilder extends StatelessWidget {
      final Widget Function(BuildContext, bool, bool, bool) builder;
      const ResponsiveBuilder({super.key, required this.builder});
    
      @override
      Widget build(BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < ResponsiveLayout.mobileBreakpoint;
            final isTablet = constraints.maxWidth >= ResponsiveLayout.mobileBreakpoint &&
                constraints.maxWidth < ResponsiveLayout.tabletBreakpoint;
            final isDesktop = constraints.maxWidth >= ResponsiveLayout.tabletBreakpoint;
            return builder(context, isMobile, isTablet, isDesktop);
          },
        );
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/loading_overlay.dart", """
    import 'package:flutter/material.dart';
    
    class LoadingOverlay extends StatelessWidget {
      final bool isLoading;
      final Widget child;
      final String? message;
    
      const LoadingOverlay({
        super.key,
        required this.isLoading,
        required this.child,
        this.message,
      });
    
      @override
      Widget build(BuildContext context) {
        return Stack(
          children: [
            child,
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          if (message != null) ...[
                            const SizedBox(height: 16),
                            Text(message!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    }
""")

write_file(f"{PROJECT_NAME}/packages/pos_core/lib/src/widgets/empty_state.dart", """
    import 'package:flutter/material.dart';
    
    class EmptyState extends StatelessWidget {
      final IconData icon;
      final String title;
      final String? subtitle;
      final Widget? action;
    
      const EmptyState({
        super.key,
        required this.icon,
        required this.title,
        this.subtitle,
        this.action,
      });
    
      @override
      Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 80, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        );
      }
    }
""")

print("✅ Package pos_core créé\n")

# ============================================================================
# MESSAGE FINAL
# ============================================================================
print("\n" + "=" * 70)
print("✅ STRUCTURE DE BASE CRÉÉE AVEC SUCCÈS")
print("=" * 70)
print(f"\n📁 Projet créé dans : {Path.cwd() / PROJECT_NAME}")
print("\n📦 Packages créés :")
print("   ✓ pos_core (thème, i18n, utils, widgets)")
print("\n⚠️  NOTE IMPORTANTE :")
print("   Ce script Python génère la structure de base et le package pos_core.")
print("   Pour obtenir le projet COMPLET avec tous les modules (pos_domain,")
print("   pos_data, pos_pos, pos_inventory, pos_billing, pos_reports, app,")
print("   tests, CI/CD), veuillez utiliser les codes fournis dans les réponses")
print("   précédentes de l'IA et les copier dans les dossiers correspondants.")
print("\n🚀 Prochaines étapes :")
print(f"   1. cd {PROJECT_NAME}")
print("   2. flutter pub get")
print("   3. Copier les fichiers des messages précédents dans chaque package")
print("   4. cd packages/pos_data && dart run build_runner build")
print("   5. Configurer Supabase (voir supabase/schema.sql)")
print("   6. cd ../../app && flutter run")
print("\n💡 Alternative recommandée :")
print("   Utilisez le dépôt GitHub : git clone git@github.com:Connacri/Pos_module.git")
print("\n✅ Génération terminée !\n")