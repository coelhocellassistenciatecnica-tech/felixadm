import 'package:intl/intl.dart';

class AppFormatters {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final _month = DateFormat('MMMM yyyy', 'pt_BR');

  static String currency(double value) => _currency.format(value);
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String month(DateTime d) => _month.format(d);
  static String phone(String p) {
    final digits = p.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return p;
  }
}
