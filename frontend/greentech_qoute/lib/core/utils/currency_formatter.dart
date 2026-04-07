import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _currencyFormat = NumberFormat(
    '#,##0.00',
    AppConstants.currencyLocale,
  );

  static final _compactFormat = NumberFormat.compactCurrency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
  );

  /// Format a number as currency string
  static String format(double value) => _currencyFormat.format(value);

  /// Format a number as currency with symbol
  static String formatWithSymbol(double value) =>
      '${AppConstants.currencySymbol}${format(value)}';

  /// Format compact currency (e.g., ₱1.2K, ₱1.5M)
  static String formatCompact(double value) => _compactFormat.format(value);

  /// Parse currency string back to double
  static double? tryParse(String value) {
    try {
      return _currencyFormat.parse(value.replaceAll(',', '')).toDouble();
    } catch (e) {
      return null;
    }
  }
}

/// Extension methods for double
extension CurrencyDoubleExtension on double {
  String get asCurrency => CurrencyFormatter.format(this);
  String get asCurrencyWithSymbol =>
      CurrencyFormatter.formatWithSymbol(this);
}

/// Extension methods for int
extension CurrencyIntExtension on int {
  String get asCurrency => CurrencyFormatter.format(toDouble());
  String get asCurrencyWithSymbol =>
      CurrencyFormatter.formatWithSymbol(toDouble());
}
