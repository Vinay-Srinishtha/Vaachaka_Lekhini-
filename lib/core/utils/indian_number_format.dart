import 'package:intl/intl.dart';

/// Indian-style number grouping: 1,00,00,000 (crore).
/// Uses the `en_IN` locale's grouping rules.
abstract final class IndianNumberFormat {
  static final _decimal = NumberFormat.decimalPattern('en_IN');
  static final _compact = NumberFormat.compact(locale: 'en_IN');

  /// e.g. 27934 -> "27,934", 10000000 -> "1,00,00,000".
  static String format(num value) => _decimal.format(value);

  /// e.g. 3100000 -> "31L", 10000000 -> "1Cr".
  static String compact(num value) => _compact.format(value);
}
