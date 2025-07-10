import 'package:intl/intl.dart';

class Global {

  static String formatAmount(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }

  static double calculateAmount(List<String> amounts) {
    double total = 0.0;
    for (String amount in amounts) {
      double? value = double.tryParse(amount);
      if (value != null) {
        total += value;
      }
    }
    return total;
  }
}
