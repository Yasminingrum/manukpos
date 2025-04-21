// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Utility class for date and time operations
class DateTimeUtils {
  /// Get the current date as DateTime
  static DateTime getCurrentDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get the current date and time as DateTime
  static DateTime getCurrentDateTime() {
    return DateTime.now();
  }

  /// Format date to string with custom format
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format date and time to string with custom format
  static String formatDateTime(DateTime dateTime, {String format = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  /// Parse string to DateTime
  static DateTime? parseDate(String dateStr, {String format = 'dd/MM/yyyy'}) {
    try {
      return DateFormat(format).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday as first day)
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  /// Get end of week (Sunday as last day)
  static DateTime endOfWeek(DateTime date) {
    final diff = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day + diff, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Calculate difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// Get a list of dates for a date range
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = daysBetween(start, end);
    return List.generate(days + 1, (i) => addDays(start, i));
  }

  /// Get a list of months between two dates
  static List<DateTime> getMonthRange(DateTime start, DateTime end) {
    List<DateTime> months = [];
    DateTime month = DateTime(start.year, start.month, 1);
    
    while (month.isBefore(DateTime(end.year, end.month + 1, 1))) {
      months.add(month);
      month = DateTime(month.year, month.month + 1, 1);
    }
    
    return months;
  }

  /// Format a date in relative terms (today, yesterday, etc.)
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Hari ini';
    } else if (isYesterday(date)) {
      return 'Kemarin';
    } else if (isTomorrow(date)) {
      return 'Besok';
    } else {
      return formatDate(date);
    }
  }

  /// Get a date with a specific time
  static DateTime setTime(DateTime date, int hour, int minute, [int second = 0, int millisecond = 0]) {
    return DateTime(date.year, date.month, date.day, hour, minute, second, millisecond);
  }

  /// Parse SQLite date/time string to DateTime
  static DateTime? parseSqliteDateTime(String? sqliteDateTime) {
    if (sqliteDateTime == null || sqliteDateTime.isEmpty) {
      return null;
    }
    
    try {
      return DateTime.parse(sqliteDateTime);
    } catch (e) {
      try {
        // Try custom parsing for different SQLite date formats
        final parts = sqliteDateTime.split(' ');
        if (parts.isNotEmpty) {
          final dateParts = parts[0].split('-');
          if (dateParts.length == 3) {
            final year = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final day = int.parse(dateParts[2]);
            
            if (parts.length >= 2) {
              final timeParts = parts[1].split(':');
              if (timeParts.length >= 2) {
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;
                
                return DateTime(year, month, day, hour, minute, second);
              }
            }
            
            return DateTime(year, month, day);
          }
        }
      } catch (_) {
        // Ignore parsing errors in fallback
      }
      
      return null;
    }
  }

  /// Format for SQLite date storage
  static String formatSqliteDate(DateTime date) {
    return date.toIso8601String();
  }
}