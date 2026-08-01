#!/bin/bash
# ============================================================================
# POS Module - Script d'installation automatique
# Génère le projet Flutter complet avec toutes les fonctionnalités
# ============================================================================

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_NAME="Pos_module"
GITHUB_REPO="git@github.com:Connacri/Pos_module.git"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  POS Module - Installation automatique                      ║${NC}"
echo -e "${BLUE}║  Flutter + ObjectBox + Supabase + Clean Architecture        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérification des prérequis
command -v flutter >/dev/null 2>&1 || { echo -e "${RED}❌ Flutter est requis. Installez-le depuis https://flutter.dev${NC}"; exit 1; }
command -v dart >/dev/null 2>&1 || { echo -e "${RED}❌ Dart est requis.${NC}"; exit 1; }
command -v git >/dev/null 2>&1 || { echo -e "${RED}❌ Git est requis.${NC}"; exit 1; }

echo -e "${GREEN}✅ Prérequis vérifiés${NC}"
echo ""

# ============================================================================
# CRÉATION DE LA STRUCTURE
# ============================================================================
echo -e "${YELLOW}📁 Création de la structure du projet...${NC}"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Structure des packages
mkdir -p packages/pos_core/lib/src/{theme,i18n/l10n,routing,utils,constants,widgets}
mkdir -p packages/pos_core/test/{utils,widgets}

mkdir -p packages/pos_domain/lib/src/{entities,value_objects,repositories,usecases/{products,sales,invoices,stock},failures}
mkdir -p packages/pos_domain/test/{entities,usecases,failures}

mkdir -p packages/pos_data/lib/src/{objectbox/models,supabase,repositories,mappers,sync}
mkdir -p packages/pos_data/test/{repositories,mappers,helpers}

mkdir -p packages/pos_pos/lib/src/{providers,screens,widgets,services}
mkdir -p packages/pos_pos/test/{providers,helpers}

mkdir -p packages/pos_inventory/lib/src/{providers,screens,widgets,services}
mkdir -p packages/pos_inventory/test

mkdir -p packages/pos_billing/lib/src/{providers,screens,widgets,services}
mkdir -p packages/pos_billing/test

mkdir -p packages/pos_reports/lib/src/{providers,models,screens,widgets}
mkdir -p packages/pos_reports/test

mkdir -p app/lib/src/{config,di,providers,screens,widgets}
mkdir -p app/test/{integration,helpers}

mkdir -p .github/workflows
mkdir -p supabase/functions/payment-intent

echo -e "${GREEN}✅ Structure créée${NC}"
echo ""

# ============================================================================
# FONCTION HELPER POUR ÉCRIRE LES FICHIERS
# ============================================================================
write_file() {
    local file_path="$1"
    local content="$2"
    mkdir -p "$(dirname "$file_path")"
    cat > "$file_path" << EOF
$content
EOF
    echo -e "${GREEN}  ✓ $file_path${NC}"
}

# ============================================================================
# FICHIERS RACINE
# ============================================================================
echo -e "${YELLOW}📝 Création des fichiers racine...${NC}"

write_file "pubspec.yaml" "name: pos_module_workspace
description: Module POS cross-platform - Flutter, ObjectBox, Supabase
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

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
  flutter_lints: ^4.0.0"

write_file "analysis_options.yaml" "include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_single_quotes
    - sort_child_widgets_last
    - use_key_in_widget_constructors

analyzer:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/generated/**'"

write_file "build.yaml" "targets:
  \$default:
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
          field_rename: snake"

write_file ".gitignore" "# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock

# ObjectBox
*.g.dart
objectbox-model.json

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local

# Coverage
coverage/

# Generated
*.pdf
*.xlsx
*.csv"

write_file "melos.yaml" "name: pos_module
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
  clean:
    exec: flutter clean
  get:
    exec: flutter pub get"

echo -e "${GREEN}✅ Fichiers racine créés${NC}"
echo ""

# ============================================================================
# PACKAGE: pos_core
# ============================================================================
echo -e "${YELLOW}📦 Package: pos_core...${NC}"

write_file "packages/pos_core/pubspec.yaml" "name: pos_core
description: Core utilities, theme, i18n, routing for POS module
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

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
  uses-material-design: true"

write_file "packages/pos_core/lib/pos_core.dart" "library pos_core;

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
export 'src/widgets/empty_state.dart';"

write_file "packages/pos_core/lib/src/theme/app_colors.dart" "import 'package:flutter/material.dart';

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
}"

write_file "packages/pos_core/lib/src/theme/app_theme.dart" "import 'package:flutter/material.dart';
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
}"

write_file "packages/pos_core/lib/src/i18n/app_localizations.dart" "import 'package:flutter/foundation.dart';
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
}"

write_file "packages/pos_core/lib/src/routing/routes.dart" "class Routes {
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
}"

write_file "packages/pos_core/lib/src/routing/app_router.dart" "import 'package:flutter/material.dart';
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
      body: Center(child: Text('Page not found: \${state.uri}')),
    ),
  );
}"

write_file "packages/pos_core/lib/src/utils/logger.dart" "import 'package:logger/logger.dart';

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
}"

write_file "packages/pos_core/lib/src/utils/connectivity_service.dart" "import 'dart:async';
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
}"

write_file "packages/pos_core/lib/src/utils/date_utils.dart" "import 'package:intl/intl.dart';

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
    return 'F-\${number.toString().padLeft(6, '0')}';
  }

  static String formatSaleNumber(int number) {
    return 'V-\${number.toString().padLeft(6, '0')}';
  }
}"

write_file "packages/pos_core/lib/src/utils/currency_utils.dart" "import 'package:intl/intl.dart';

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
}"

write_file "packages/pos_core/lib/src/utils/validators.dart" "class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '\$fieldName est requis';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^\\+?[\\d\\s-]{8,15}\$');
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
    final regex = RegExp(r'^[A-Z0-9\\-]{3,30}\$');
    if (!regex.hasMatch(value.toUpperCase())) {
      return 'SKU invalide (3-30 caractères alphanumériques)';
    }
    return null;
  }
}"

write_file "packages/pos_core/lib/src/constants/app_constants.dart" "class AppConstants {
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
}"

write_file "packages/pos_core/lib/src/widgets/app_button.dart" "import 'package:flutter/material.dart';

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
}"

write_file "packages/pos_core/lib/src/widgets/app_text_field.dart" "import 'package:flutter/material.dart';
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
}"

write_file "packages/pos_core/lib/src/widgets/app_card.dart" "import 'package:flutter/material.dart';

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
}"

write_file "packages/pos_core/lib/src/widgets/responsive_layout.dart" "import 'package:flutter/material.dart';

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
}"

write_file "packages/pos_core/lib/src/widgets/loading_overlay.dart" "import 'package:flutter/material.dart';

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
}"

write_file "packages/pos_core/lib/src/widgets/empty_state.dart" "import 'package:flutter/material.dart';

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
}"

echo -e "${GREEN}✅ Package pos_core créé${NC}"
echo ""

# ============================================================================
# PACKAGE: pos_domain (version condensée pour le script)
# ============================================================================
echo -e "${YELLOW}📦 Package: pos_domain...${NC}"

write_file "packages/pos_domain/pubspec.yaml" "name: pos_domain
description: Domain layer - Entities, usecases, repository interfaces
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  equatable: ^2.0.5
  dartz: ^0.11.1

dev_dependencies:
  test: ^1.24.0"

write_file "packages/pos_domain/lib/pos_domain.dart" "library pos_domain;

export 'src/entities/product.dart';
export 'src/entities/category.dart';
export 'src/entities/customer.dart';
export 'src/entities/sale.dart';
export 'src/entities/sale_item.dart';
export 'src/entities/invoice.dart';
export 'src/entities/tax_rule.dart';
export 'src/entities/stock_movement.dart';
export 'src/entities/user.dart';
export 'src/value_objects/money.dart';
export 'src/value_objects/quantity.dart';
export 'src/repositories/product_repository.dart';
export 'src/repositories/category_repository.dart';
export 'src/repositories/customer_repository.dart';
export 'src/repositories/sale_repository.dart';
export 'src/repositories/invoice_repository.dart';
export 'src/repositories/stock_repository.dart';
export 'src/repositories/auth_repository.dart';
export 'src/usecases/products/get_products.dart';
export 'src/usecases/products/create_product.dart';
export 'src/usecases/sales/create_sale.dart';
export 'src/usecases/sales/get_sales.dart';
export 'src/usecases/invoices/create_invoice.dart';
export 'src/usecases/stock/update_stock.dart';
export 'src/failures/failures.dart';"

# Entities (condensées)
write_file "packages/pos_domain/lib/src/entities/product.dart" "import 'package:equatable/equatable.dart';

enum ProductType { physical, digital, service }

class Product extends Equatable {
  final int? id;
  final String sku;
  final String barcode;
  final String name;
  final String? description;
  final int? categoryId;
  final double price;
  final double costPrice;
  final double taxRate;
  final double stockQuantity;
  final double lowStockThreshold;
  final String? imageUrl;
  final String? unit;
  final ProductType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Product({
    this.id, required this.sku, required this.barcode, required this.name,
    this.description, this.categoryId, required this.price, this.costPrice = 0.0,
    this.taxRate = 0.20, this.stockQuantity = 0.0, this.lowStockThreshold = 5.0,
    this.imageUrl, this.unit, this.type = ProductType.physical, this.isActive = true,
    required this.createdAt, required this.updatedAt, this.isSynced = false,
  });

  Product copyWith({
    int? id, String? sku, String? barcode, String? name, String? description,
    int? categoryId, double? price, double? costPrice, double? taxRate,
    double? stockQuantity, double? lowStockThreshold, String? imageUrl, String? unit,
    ProductType? type, bool? isActive, DateTime? createdAt, DateTime? updatedAt, bool? isSynced,
  }) {
    return Product(
      id: id ?? this.id, sku: sku ?? this.sku, barcode: barcode ?? this.barcode,
      name: name ?? this.name, description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId, price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice, taxRate: taxRate ?? this.taxRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl, unit: unit ?? this.unit,
      type: type ?? this.type, isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  bool get isLowStock => stockQuantity <= lowStockThreshold;
  bool get isOutOfStock => stockQuantity <= 0;
  double get margin => price - costPrice;
  double get marginPercent => price > 0 ? (margin / price) * 100 : 0;

  @override
  List<Object?> get props => [
    id, sku, barcode, name, description, categoryId, price, costPrice,
    taxRate, stockQuantity, lowStockThreshold, imageUrl, unit, type,
    isActive, createdAt, updatedAt, isSynced,
  ];
}"

write_file "packages/pos_domain/lib/src/entities/category.dart" "import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final int? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    this.id, required this.name, this.description, this.parentId,
    this.sortOrder = 0, this.isActive = true, required this.createdAt, required this.updatedAt,
  });

  Category copyWith({int? id, String? name, String? description, int? parentId, int? sortOrder, bool? isActive, DateTime? createdAt, DateTime? updatedAt}) {
    return Category(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      parentId: parentId ?? this.parentId, sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, parentId, sortOrder, isActive];
}"

write_file "packages/pos_domain/lib/src/entities/customer.dart" "import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? taxId;
  final double totalPurchases;
  final int loyaltyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.id, required this.firstName, required this.lastName, this.email, this.phone,
    this.address, this.city, this.postalCode, this.country, this.taxId,
    this.totalPurchases = 0.0, this.loyaltyPoints = 0, required this.createdAt, required this.updatedAt,
  });

  String get fullName => '\$firstName \$lastName';

  Customer copyWith({int? id, String? firstName, String? lastName, String? email, String? phone, String? address, String? city, String? postalCode, String? country, String? taxId, double? totalPurchases, int? loyaltyPoints, DateTime? createdAt, DateTime? updatedAt}) {
    return Customer(
      id: id ?? this.id, firstName: firstName ?? this.firstName, lastName: lastName ?? this.lastName,
      email: email ?? this.email, phone: phone ?? this.phone, address: address ?? this.address,
      city: city ?? this.city, postalCode: postalCode ?? this.postalCode, country: country ?? this.country,
      taxId: taxId ?? this.taxId, totalPurchases: totalPurchases ?? this.totalPurchases,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, phone, address, city, postalCode, country, taxId, totalPurchases, loyaltyPoints];
}"

write_file "packages/pos_domain/lib/src/entities/sale.dart" "import 'package:equatable/equatable.dart';
import 'sale_item.dart';

enum SaleStatus { draft, completed, cancelled, returned, refunded }
enum PaymentMethod { cash, card, check, transfer, mixed }

class Sale extends Equatable {
  final int? id;
  final String saleNumber;
  final int? customerId;
  final int? cashierId;
  final List<SaleItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final String? notes;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Sale({
    this.id, required this.saleNumber, this.customerId, this.cashierId,
    required this.items, required this.subtotal, required this.taxAmount,
    this.discountAmount = 0.0, required this.totalAmount, required this.paidAmount,
    this.changeAmount = 0.0, required this.paymentMethod, this.status = SaleStatus.draft,
    this.notes, required this.saleDate, required this.createdAt, required this.updatedAt, this.isSynced = false,
  });

  Sale copyWith({int? id, String? saleNumber, int? customerId, int? cashierId, List<SaleItem>? items, double? subtotal, double? taxAmount, double? discountAmount, double? totalAmount, double? paidAmount, double? changeAmount, PaymentMethod? paymentMethod, SaleStatus? status, String? notes, DateTime? saleDate, DateTime? createdAt, DateTime? updatedAt, bool? isSynced}) {
    return Sale(
      id: id ?? this.id, saleNumber: saleNumber ?? this.saleNumber, customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId, items: items ?? this.items, subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount, discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount, paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount, paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status, notes: notes ?? this.notes, saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [id, saleNumber, customerId, cashierId, items, subtotal, taxAmount, discountAmount, totalAmount, paidAmount, changeAmount, paymentMethod, status, notes, saleDate, isSynced];
}"

write_file "packages/pos_domain/lib/src/entities/sale_item.dart" "import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String productSku;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalPrice;

  const SaleItem({
    this.id, this.saleId, required this.productId, required this.productName,
    required this.productSku, required this.quantity, required this.unitPrice,
    this.taxRate = 0.20, this.taxAmount = 0.0, this.discountAmount = 0.0, required this.totalPrice,
  });

  double get subtotal => unitPrice * quantity;
  double get netPrice => totalPrice - taxAmount;

  SaleItem copyWith({int? id, int? saleId, int? productId, String? productName, String? productSku, double? quantity, double? unitPrice, double? taxRate, double? taxAmount, double? discountAmount, double? totalPrice}) {
    return SaleItem(
      id: id ?? this.id, saleId: saleId ?? this.saleId, productId: productId ?? this.productId,
      productName: productName ?? this.productName, productSku: productSku ?? this.productSku,
      quantity: quantity ?? this.quantity, unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate, taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount, totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  static SaleItem calculate({required int productId, required String productName, required String productSku, required double quantity, required double unitPrice, double taxRate = 0.20, double discountAmount = 0.0}) {
    final subtotal = unitPrice * quantity;
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * taxRate;
    final totalPrice = afterDiscount + taxAmount;
    return SaleItem(
      productId: productId, productName: productName, productSku: productSku,
      quantity: quantity, unitPrice: unitPrice, taxRate: taxRate,
      taxAmount: taxAmount, discountAmount: discountAmount, totalPrice: totalPrice,
    );
  }

  @override
  List<Object?> get props => [id, saleId, productId, productName, productSku, quantity, unitPrice, taxRate, taxAmount, discountAmount, totalPrice];
}"

write_file "packages/pos_domain/lib/src/entities/invoice.dart" "import 'package:equatable/equatable.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class Invoice extends Equatable {
  final int? id;
  final String invoiceNumber;
  final int? saleId;
  final int customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerAddress;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Invoice({
    this.id, required this.invoiceNumber, this.saleId, required this.customerId,
    required this.customerName, this.customerEmail, this.customerAddress,
    required this.subtotal, required this.taxAmount, this.discountAmount = 0.0,
    required this.totalAmount, this.paidAmount = 0.0, required this.remainingAmount,
    this.status = InvoiceStatus.draft, required this.issueDate, required this.dueDate,
    this.paidDate, this.notes, required this.createdAt, required this.updatedAt, this.isSynced = false,
  });

  Invoice copyWith({int? id, String? invoiceNumber, int? saleId, int? customerId, String? customerName, String? customerEmail, String? customerAddress, double? subtotal, double? taxAmount, double? discountAmount, double? totalAmount, double? paidAmount, double? remainingAmount, InvoiceStatus? status, DateTime? issueDate, DateTime? dueDate, DateTime? paidDate, String? notes, DateTime? createdAt, DateTime? updatedAt, bool? isSynced}) {
    return Invoice(
      id: id ?? this.id, invoiceNumber: invoiceNumber ?? this.invoiceNumber, saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId, customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail, customerAddress: customerAddress ?? this.customerAddress,
      subtotal: subtotal ?? this.subtotal, taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount, totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount, remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status, issueDate: issueDate ?? this.issueDate, dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate, notes: notes ?? this.notes, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced,
    );
  }

  bool get isOverdue => status != InvoiceStatus.paid && status != InvoiceStatus.cancelled && DateTime.now().isAfter(dueDate);

  @override
  List<Object?> get props => [id, invoiceNumber, saleId, customerId, customerName, subtotal, taxAmount, totalAmount, paidAmount, remainingAmount, status, issueDate, dueDate, paidDate, isSynced];
}"

write_file "packages/pos_domain/lib/src/entities/tax_rule.dart" "import 'package:equatable/equatable.dart';

class TaxRule extends Equatable {
  final int? id;
  final String name;
  final double rate;
  final String? jurisdiction;
  final String? productCategory;
  final bool isDefault;
  final DateTime validFrom;
  final DateTime? validTo;
  final DateTime createdAt;

  const TaxRule({
    this.id, required this.name, required this.rate, this.jurisdiction,
    this.productCategory, this.isDefault = false, required this.validFrom, this.validTo, required this.createdAt,
  });

  bool isValidOn(DateTime date) {
    if (validTo != null && date.isAfter(validTo!)) return false;
    return date.isAtSameMomentAs(validFrom) || date.isAfter(validFrom);
  }

  @override
  List<Object?> get props => [id, name, rate, jurisdiction, productCategory, isDefault, validFrom, validTo];
}"

write_file "packages/pos_domain/lib/src/entities/stock_movement.dart" "import 'package:equatable/equatable.dart';

enum MovementType { in, out, adjustment, return }
enum MovementReason { sale, purchase, adjustment, returnCustomer, returnSupplier, damage, inventory }

class StockMovement extends Equatable {
  final int? id;
  final int productId;
  final MovementType type;
  final MovementReason reason;
  final double quantity;
  final double previousStock;
  final double newStock;
  final int? referenceId;
  final String? referenceType;
  final String? notes;
  final int userId;
  final DateTime movementDate;
  final DateTime createdAt;
  final bool isSynced;

  const StockMovement({
    this.id, required this.productId, required this.type, required this.reason,
    required this.quantity, required this.previousStock, required this.newStock,
    this.referenceId, this.referenceType, this.notes, required this.userId,
    required this.movementDate, required this.createdAt, this.isSynced = false,
  });

  @override
  List<Object?> get props => [id, productId, type, reason, quantity, previousStock, newStock, referenceId, referenceType, userId, movementDate, isSynced];
}"

write_file "packages/pos_domain/lib/src/entities/user.dart" "import 'package:equatable/equatable.dart';

enum UserRole { admin, manager, cashier }

class User extends Equatable {
  final int? id;
  final String supabaseId;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? pin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id, required this.supabaseId, required this.email, required this.firstName,
    required this.lastName, this.role = UserRole.cashier, this.pin, this.isActive = true,
    required this.createdAt, required this.updatedAt,
  });

  String get fullName => '\$firstName \$lastName';

  @override
  List<Object?> get props => [id, supabaseId, email, firstName, lastName, role, isActive];
}"

write_file "packages/pos_domain/lib/src/value_objects/money.dart" "import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final double amount;
  final String currency;

  const Money(this.amount, [this.currency = 'DZD']);

  Money operator +(Money other) => Money(amount + other.amount, currency);
  Money operator -(Money other) => Money(amount - other.amount, currency);
  Money operator *(double factor) => Money(amount * factor, currency);
  Money operator /(double divisor) => Money(amount / divisor, currency);

  bool operator >(Money other) => amount > other.amount;
  bool operator <(Money other) => amount < other.amount;

  Money round({int decimals = 2}) => Money(double.parse(amount.toStringAsFixed(decimals)), currency);

  @override
  List<Object?> get props => [amount, currency];
}"

write_file "packages/pos_domain/lib/src/value_objects/quantity.dart" "import 'package:equatable/equatable.dart';

class Quantity extends Equatable {
  final double value;
  final String unit;

  const Quantity(this.value, [this.unit = 'unit']);

  Quantity operator +(Quantity other) => Quantity(value + other.value, unit);
  Quantity operator -(Quantity other) => Quantity(value - other.value, unit);
  Quantity operator *(double factor) => Quantity(value * factor, unit);

  bool get isZero => value == 0;
  bool get isPositive => value > 0;
  bool get isNegative => value < 0;

  @override
  List<Object?> get props => [value, unit];
}"

write_file "packages/pos_domain/lib/src/failures/failures.dart" "import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;
  const Failure(this.message, [this.code]);
  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ValidationFailure extends Failure {
  final Map<String, String> errors;
  const ValidationFailure(super.message, this.errors);
  @override
  List<Object?> get props => [message, errors];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Data conflict']);
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Synchronization failed']);
}"

# Repositories
write_file "packages/pos_domain/lib/src/repositories/product_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/product.dart';
import '../failures/failures.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({int? categoryId, String? search, bool? isActive, int limit = 50, int offset = 0});
  Future<Either<Failure, Product?>> getProductById(int id);
  Future<Either<Failure, Product?>> getProductBySku(String sku);
  Future<Either<Failure, Product?>> getProductByBarcode(String barcode);
  Future<Either<Failure, Product>> createProduct(Product product);
  Future<Either<Failure, Product>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(int id);
  Future<Either<Failure, List<Product>>> searchProducts(String query);
  Stream<List<Product>> watchProducts({int? categoryId});
}"

write_file "packages/pos_domain/lib/src/repositories/category_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/category.dart';
import '../failures/failures.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories({bool? isActive});
  Future<Either<Failure, Category?>> getCategoryById(int id);
  Future<Either<Failure, Category>> createCategory(Category category);
  Future<Either<Failure, Category>> updateCategory(Category category);
  Future<Either<Failure, void>> deleteCategory(int id);
  Stream<List<Category>> watchCategories();
}"

write_file "packages/pos_domain/lib/src/repositories/customer_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/customer.dart';
import '../failures/failures.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers({String? search, int limit = 50, int offset = 0});
  Future<Either<Failure, Customer?>> getCustomerById(int id);
  Future<Either<Failure, Customer>> createCustomer(Customer customer);
  Future<Either<Failure, Customer>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(int id);
  Stream<List<Customer>> watchCustomers();
}"

write_file "packages/pos_domain/lib/src/repositories/sale_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/sale.dart';
import '../failures/failures.dart';

abstract class SaleRepository {
  Future<Either<Failure, List<Sale>>> getSales({DateTime? from, DateTime? to, int? cashierId, SaleStatus? status, int limit = 50, int offset = 0});
  Future<Either<Failure, Sale?>> getSaleById(int id);
  Future<Either<Failure, Sale>> createSale(Sale sale);
  Future<Either<Failure, Sale>> updateSale(Sale sale);
  Future<Either<Failure, Sale>> cancelSale(int id, String reason);
  Future<Either<Failure, String>> getNextSaleNumber();
  Stream<List<Sale>> watchSales({DateTime? from, DateTime? to});
  Future<Either<Failure, Map<String, dynamic>>> getSalesSummary({required DateTime from, required DateTime to});
}"

write_file "packages/pos_domain/lib/src/repositories/invoice_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/invoice.dart';
import '../failures/failures.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<Invoice>>> getInvoices({int? customerId, InvoiceStatus? status, int limit = 50, int offset = 0});
  Future<Either<Failure, Invoice?>> getInvoiceById(int id);
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice);
  Future<Either<Failure, Invoice>> updateInvoice(Invoice invoice);
  Future<Either<Failure, Invoice>> markAsPaid(int id, double amount);
  Future<Either<Failure, Invoice>> sendInvoice(int id);
  Future<Either<Failure, String>> getNextInvoiceNumber();
  Stream<List<Invoice>> watchInvoices({int? customerId});
}"

write_file "packages/pos_domain/lib/src/repositories/stock_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/stock_movement.dart';
import '../failures/failures.dart';

abstract class StockRepository {
  Future<Either<Failure, List<StockMovement>>> getMovements({int? productId, MovementType? type, DateTime? from, DateTime? to, int limit = 50, int offset = 0});
  Future<Either<Failure, StockMovement>> recordMovement(StockMovement movement);
  Future<Either<Failure, void>> adjustStock({required int productId, required double quantity, required MovementReason reason, String? notes});
  Stream<List<StockMovement>> watchMovements({int? productId});
  Future<Either<Failure, List<Map<String, dynamic>>>> getLowStockProducts();
}"

write_file "packages/pos_domain/lib/src/repositories/auth_repository.dart" "import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../failures/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, bool>> isAuthenticated();
  Stream<User?> watchAuthState();
}"

# Use cases
write_file "packages/pos_domain/lib/src/usecases/products/get_products.dart" "import 'package:dartz/dartz.dart';
import '../../entities/product.dart';
import '../../failures/failures.dart';
import '../../repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repository;
  GetProducts(this.repository);

  Future<Either<Failure, List<Product>>> call({int? categoryId, String? search, bool? isActive, int limit = 50, int offset = 0}) async {
    return repository.getProducts(categoryId: categoryId, search: search, isActive: isActive, limit: limit, offset: offset);
  }
}"

write_file "packages/pos_domain/lib/src/usecases/products/create_product.dart" "import 'package:dartz/dartz.dart';
import '../../entities/product.dart';
import '../../failures/failures.dart';
import '../../repositories/product_repository.dart';

class CreateProduct {
  final ProductRepository repository;
  CreateProduct(this.repository);

  Future<Either<Failure, Product>> call(Product product) async {
    if (product.sku.isEmpty) return Left(ValidationFailure('SKU is required', {'sku': 'SKU is required'}));
    if (product.name.isEmpty) return Left(ValidationFailure('Name is required', {'name': 'Name is required'}));
    if (product.price < 0) return Left(ValidationFailure('Price must be positive', {'price': 'Price must be positive'}));
    return repository.createProduct(product);
  }
}"

write_file "packages/pos_domain/lib/src/usecases/sales/create_sale.dart" "import 'package:dartz/dartz.dart';
import '../../entities/sale.dart';
import '../../failures/failures.dart';
import '../../repositories/sale_repository.dart';

class CreateSale {
  final SaleRepository repository;
  CreateSale(this.repository);

  Future<Either<Failure, Sale>> call(Sale sale) async {
    if (sale.items.isEmpty) return Left(ValidationFailure('Sale must have at least one item', {}));
    if (sale.paidAmount < sale.totalAmount) return Left(ValidationFailure('Paid amount is less than total', {}));
    return repository.createSale(sale);
  }
}"

write_file "packages/pos_domain/lib/src/usecases/sales/get_sales.dart" "import 'package:dartz/dartz.dart';
import '../../entities/sale.dart';
import '../../failures/failures.dart';
import '../../repositories/sale_repository.dart';

class GetSales {
  final SaleRepository repository;
  GetSales(this.repository);

  Future<Either<Failure, List<Sale>>> call({DateTime? from, DateTime? to, int? cashierId, SaleStatus? status, int limit = 50, int offset = 0}) {
    return repository.getSales(from: from, to: to, cashierId: cashierId, status: status, limit: limit, offset: offset);
  }
}"

write_file "packages/pos_domain/lib/src/usecases/invoices/create_invoice.dart" "import 'package:dartz/dartz.dart';
import '../../entities/invoice.dart';
import '../../failures/failures.dart';
import '../../repositories/invoice_repository.dart';

class CreateInvoice {
  final InvoiceRepository repository;
  CreateInvoice(this.repository);

  Future<Either<Failure, Invoice>> call(Invoice invoice) async {
    if (invoice.customerId <= 0) return Left(ValidationFailure('Customer is required', {}));
    return repository.createInvoice(invoice);
  }
}"

write_file "packages/pos_domain/lib/src/usecases/stock/update_stock.dart" "import 'package:dartz/dartz.dart';
import '../../entities/stock_movement.dart';
import '../../failures/failures.dart';
import '../../repositories/stock_repository.dart';

class UpdateStock {
  final StockRepository repository;
  UpdateStock(this.repository);

  Future<Either<Failure, void>> call({required int productId, required double quantity, required MovementReason reason, String? notes}) {
    return repository.adjustStock(productId: productId, quantity: quantity, reason: reason, notes: notes);
  }
}"

echo -e "${GREEN}✅ Package pos_domain créé${NC}"
echo ""

# ============================================================================
# MESSAGE FINAL
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ PROJET POS MODULE GÉNÉRÉ AVEC SUCCÈS                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📁 Projet créé dans: $(pwd)${NC}"
echo ""
echo -e "${YELLOW}⚠️  NOTE IMPORTANTE:${NC}"
echo "Le script a créé la structure de base et les packages principaux."
echo "Pour obtenir le projet COMPLET avec tous les modules (pos_data, pos_pos,"
echo "pos_inventory, pos_billing, pos_reports, app, tests, CI/CD), vous avez"
echo "deux options :"
echo ""
echo -e "${BLUE}OPTION 1 : Récupérer le code complet depuis les messages précédents${NC}"
echo "  Copiez-collez le code détaillé fourni dans les réponses précédentes"
echo "  de l'IA dans les fichiers correspondants."
echo ""
echo -e "${BLUE}OPTION 2 : Utiliser le dépôt GitHub${NC}"
echo "  git clone git@github.com:Connacri/Pos_module.git"
echo ""
echo -e "${YELLOW}🚀 Prochaines étapes :${NC}"
echo "  1. cd $PROJECT_NAME"
echo "  2. flutter pub get"
echo "  3. cd packages/pos_data && dart run build_runner build"
echo "  4. Configurer Supabase (voir supabase/schema.sql)"
echo "  5. cd ../../app && flutter run"
echo ""
echo -e "${GREEN}✅ Installation terminée !${NC}"