import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('es'),
    Locale('ar'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'appTitle': 'Module POS',
      'home': 'Accueil',
      'pos': 'Caisse',
      'inventory': 'Stock',
      'billing': 'Facturation',
      'reports': 'Rapports',
      'settings': 'Paramètres',
      'products': 'Produits',
      'categories': 'Catégories',
      'customers': 'Clients',
      'sales': 'Ventes',
      'invoices': 'Factures',
      'search': 'Rechercher',
      'add': 'Ajouter',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'name': 'Nom',
      'price': 'Prix',
      'quantity': 'Quantité',
      'total': 'Total',
      'tax': 'Taxe',
      'discount': 'Remise',
      'subtotal': 'Sous-total',
      'payment': 'Paiement',
      'cash': 'Espèces',
      'card': 'Carte',
      'checkout': 'Encaisser',
      'newSale': 'Nouvelle vente',
      'emptyCart': 'Panier vide',
      'addToCart': 'Ajouter au panier',
      'removeFromCart': 'Retirer du panier',
      'lowStock': 'Stock faible',
      'outOfStock': 'Rupture de stock',
      'inStock': 'En stock',
      'sku': 'SKU',
      'barcode': 'Code-barres',
      'description': 'Description',
      'print': 'Imprimer',
      'printInvoice': 'Imprimer la facture',
      'downloadPdf': 'Télécharger PDF',
      'export': 'Exporter',
      'import': 'Importer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'noData': 'Aucune donnée',
      'offline': 'Hors ligne',
      'online': 'En ligne',
      'syncing': 'Synchronisation...',
      'syncComplete': 'Synchronisation terminée',
      'theme': 'Thème',
      'language': 'Langue',
      'darkMode': 'Mode sombre',
      'lightMode': 'Mode clair',
    },
    'en': {
      'appTitle': 'POS Module',
      'home': 'Home',
      'pos': 'POS',
      'inventory': 'Inventory',
      'billing': 'Billing',
      'reports': 'Reports',
      'settings': 'Settings',
      'products': 'Products',
      'categories': 'Categories',
      'customers': 'Customers',
      'sales': 'Sales',
      'invoices': 'Invoices',
      'search': 'Search',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'name': 'Name',
      'price': 'Price',
      'quantity': 'Quantity',
      'total': 'Total',
      'tax': 'Tax',
      'discount': 'Discount',
      'subtotal': 'Subtotal',
      'payment': 'Payment',
      'cash': 'Cash',
      'card': 'Card',
      'checkout': 'Checkout',
      'newSale': 'New sale',
      'emptyCart': 'Empty cart',
      'addToCart': 'Add to cart',
      'removeFromCart': 'Remove from cart',
      'lowStock': 'Low stock',
      'outOfStock': 'Out of stock',
      'inStock': 'In stock',
      'sku': 'SKU',
      'barcode': 'Barcode',
      'description': 'Description',
      'print': 'Print',
      'printInvoice': 'Print invoice',
      'downloadPdf': 'Download PDF',
      'export': 'Export',
      'import': 'Import',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'noData': 'No data',
      'offline': 'Offline',
      'online': 'Online',
      'syncing': 'Syncing...',
      'syncComplete': 'Sync complete',
      'theme': 'Theme',
      'language': 'Language',
      'darkMode': 'Dark mode',
      'lightMode': 'Light mode',
    },
    'es': {
      'appTitle': 'Módulo POS',
      'home': 'Inicio',
      'pos': 'Caja',
      'inventory': 'Inventario',
      'billing': 'Facturación',
      'reports': 'Informes',
      'settings': 'Ajustes',
      'products': 'Productos',
      'categories': 'Categorías',
      'customers': 'Clientes',
      'sales': 'Ventas',
      'invoices': 'Facturas',
      'search': 'Buscar',
      'add': 'Añadir',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'name': 'Nombre',
      'price': 'Precio',
      'quantity': 'Cantidad',
      'total': 'Total',
      'tax': 'Impuesto',
      'discount': 'Descuento',
      'subtotal': 'Subtotal',
      'payment': 'Pago',
      'cash': 'Efectivo',
      'card': 'Tarjeta',
      'checkout': 'Cobrar',
      'newSale': 'Nueva venta',
      'emptyCart': 'Carrito vacío',
      'addToCart': 'Añadir al carrito',
      'removeFromCart': 'Quitar del carrito',
      'lowStock': 'Stock bajo',
      'outOfStock': 'Sin stock',
      'inStock': 'En stock',
      'sku': 'SKU',
      'barcode': 'Código de barras',
      'description': 'Descripción',
      'print': 'Imprimir',
      'printInvoice': 'Imprimir factura',
      'downloadPdf': 'Descargar PDF',
      'export': 'Exportar',
      'import': 'Importar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'noData': 'Sin datos',
      'offline': 'Desconectado',
      'online': 'En línea',
      'syncing': 'Sincronizando...',
      'syncComplete': 'Sincronización completa',
      'theme': 'Tema',
      'language': 'Idioma',
      'darkMode': 'Modo oscuro',
      'lightMode': 'Modo claro',
    },
    'ar': {
      'appTitle': 'وحدة نقطة البيع',
      'home': 'الرئيسية',
      'pos': 'نقطة البيع',
      'inventory': 'المخزون',
      'billing': 'الفواتير',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'products': 'المنتجات',
      'categories': 'الفئات',
      'customers': 'العملاء',
      'sales': 'المبيعات',
      'invoices': 'الفواتير',
      'search': 'بحث',
      'add': 'إضافة',
      'edit': 'تعديل',
      'delete': 'حذف',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'name': 'الاسم',
      'price': 'السعر',
      'quantity': 'الكمية',
      'total': 'المجموع',
      'tax': 'الضريبة',
      'discount': 'الخصم',
      'subtotal': 'المجموع الفرعي',
      'payment': 'الدفع',
      'cash': 'نقداً',
      'card': 'بطاقة',
      'checkout': 'الدفع',
      'newSale': 'بيع جديد',
      'emptyCart': 'السلة فارغة',
      'addToCart': 'أضف إلى السلة',
      'removeFromCart': 'إزالة من السلة',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'noData': 'لا توجد بيانات',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }

  // Convenience getters
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
  String get removeFromCart => translate('removeFromCart');
  String get lowStock => translate('lowStock');
  String get outOfStock => translate('outOfStock');
  String get inStock => translate('inStock');
  String get sku => translate('sku');
  String get barcode => translate('barcode');
  String get description => translate('description');
  String get print => translate('print');
  String get printInvoice => translate('printInvoice');
  String get downloadPdf => translate('downloadPdf');
  String get export => translate('export');
  String get import => translate('import');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get noData => translate('noData');
  String get offline => translate('offline');
  String get online => translate('online');
  String get syncing => translate('syncing');
  String get syncComplete => translate('syncComplete');
  String get theme => translate('theme');
  String get language => translate('language');
  String get darkMode => translate('darkMode');
  String get lightMode => translate('lightMode');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}