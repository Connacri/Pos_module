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
    final cleaned = value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}