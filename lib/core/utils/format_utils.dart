import 'package:intl/intl.dart';

/// Utility functions for currency and date formatting
/// Used throughout the VKU Expense Tracker app
class FormatUtils {
  FormatUtils._(); // Prevent instantiation

  /// Vietnamese Dong currency formatter
  /// Formats double amounts with dot grouping and đ symbol
  /// Example: 150000.0 → "150.000 đ"
  static final NumberFormat _vndFormatter = NumberFormat.decimalPattern('vi');

  /// Format a double amount as Vietnamese Dong currency string
  /// [amount]: The monetary value to format
  /// Returns formatted string, e.g., "150.000 đ"
  static String formatVND(double amount) {
    return '${_vndFormatter.format(amount)} đ';
  }

  /// Format a double amount as compact currency (no symbol)
  /// Useful for charts and compact display
  static String formatVNDCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Date formatter for display (dd/MM/yyyy)
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  /// Short date formatter (dd/MM)
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM');

  /// Full datetime formatter
  static final DateFormat _dateTimeFormatter =
      DateFormat('dd/MM/yyyy HH:mm');

  /// Format a DateTime as "dd/MM/yyyy"
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Format a DateTime as "dd/MM"
  static String formatShortDate(DateTime date) =>
      _shortDateFormatter.format(date);

  /// Format a DateTime as "dd/MM/yyyy HH:mm"
  static String formatDateTime(DateTime date) =>
      _dateTimeFormatter.format(date);

  /// Format a DateTime as day-of-week abbreviation in Vietnamese (T2, T3, ..., CN)
  static String formatDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  /// Parse a Vietnamese currency string back to double
  /// Handles formats: "150.000 đ", "150,000", "150000"
  /// Returns null if parsing fails
  static double? parseVNDAmount(String text) {
    // Remove currency symbol and whitespace
    final cleaned = text
        .replaceAll('đ', '')
        .replaceAll('VND', '')
        .replaceAll('vnđ', '')
        .trim();

    // Try parsing with dot as thousand separator (Vietnamese format)
    // e.g. "150.000" -> 150000
    final dotRemoved = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(dotRemoved);
  }

  /// Get the start of the current week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get list of 7 dates for the current week (Mon–Sun)
  static List<DateTime> getCurrentWeekDates() {
    final now = DateTime.now();
    final weekStart = startOfWeek(now);
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }
}
