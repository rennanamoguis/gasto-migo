class DateRangeUtils {
  static String todayDate() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  static String currentTimeHHmm() {
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  static String currentMonthPrefix() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');

    return '$year-$month';
  }

  static DateTime startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return start.add(const Duration(days: 6));
  }

  static String dateOnly(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }
}
