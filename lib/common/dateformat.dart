import 'package:intl/intl.dart';

class AppDateFormat {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String format(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  static DateTime? parse(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}