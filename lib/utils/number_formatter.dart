/// Utility functions for consistent number formatting throughout the app
class NumberFormatter {
  /// Format a double value to show only 1 decimal place
  ///
  /// Examples:
  /// - 65.33333333 becomes "65.3"
  /// - 87.123456789 becomes "87.1"
  /// - 42.0 becomes "42.0"
  /// - 0.0 becomes "0.0"
  static String formatDouble(double value) {
    return value.toStringAsFixed(1);
  }

  /// Format a num value (int or double) to show only 1 decimal place
  static String formatNum(num value) {
    return value.toDouble().toStringAsFixed(1);
  }

  /// Format a value that might be null or of various numeric types
  ///
  /// This handles cases where the value might be:
  /// - null
  /// - int
  /// - double
  /// - num
  static String formatDynamic(dynamic value) {
    if (value == null) return "0.0";

    try {
      final numValue = num.parse(value.toString());
      return numValue.toDouble().toStringAsFixed(1);
    } catch (e) {
      return "0.0";
    }
  }

  /// Format currency amount with 1 decimal place
  ///
  /// Adds ₹ symbol and formats to 1 decimal place
  /// Example: 1234.56 becomes "₹1234.6"
  static String formatCurrency(dynamic value) {
    final formatted = formatDynamic(value);
    return "₹$formatted";
  }

  /// Format karma points with " pts" suffix
  /// Example: 123.45 becomes "123.5 pts"
  static String formatKarmaPoints(dynamic value) {
    final formatted = formatDynamic(value);
    return "$formatted pts";
  }

  /// Format karma points with " karma" suffix
  /// Example: 123.45 becomes "123.5 karma"
  static String formatKarma(dynamic value) {
    final formatted = formatDynamic(value);
    return "$formatted karma";
  }

  /// Format split amount per person with currency symbol
  /// Example: 123.45 becomes "₹123.5 each"
  static String formatSplitAmount(dynamic value) {
    final formatted = formatDynamic(value);
    return "₹$formatted each";
  }

  /// Format karma points display with " Karma Points" suffix
  /// Example: 123.45 becomes "123.5 Karma Points"
  static String formatKarmaPointsDisplay(dynamic value) {
    final formatted = formatDynamic(value);
    return "$formatted Karma Points";
  }
}
