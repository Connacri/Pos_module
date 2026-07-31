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
    return 'F-${number.toString().padLeft(6, '0')}';
  }

  static String formatSaleNumber(int number) {
    return 'V-${number.toString().padLeft(6, '0')}';
  }
}
