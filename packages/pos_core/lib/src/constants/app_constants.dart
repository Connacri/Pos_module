class AppConstants {
  AppConstants._();

  static const String appName = 'POS Module';
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyDefaultTaxRate = 'default_tax_rate';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyLastSync = 'last_sync';
  static const String keyDeviceId = 'device_id';

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  static const Duration httpTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);

  static const int lowStockThreshold = 5;
  static const int criticalStockThreshold = 2;

  static const double defaultTaxRate = 0.19;
  static const String defaultCurrency = 'DZD';
}
