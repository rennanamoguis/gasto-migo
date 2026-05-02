import 'package:intl/intl.dart';

class AppFormatUtils {
  static String formatDate(
      String dateValue, {
        String dateFormat = 'MMM dd, yyyy',
      }) {
    try {
      final date = DateTime.parse(dateValue);
      return DateFormat(dateFormat).format(date);
    } catch (_) {
      return dateValue;
    }
  }

  static String formatTime(
      String? timeValue, {
        String timeFormat = '12h',
      }) {
    if (timeValue == null || timeValue.trim().isEmpty) {
      return '';
    }

    try {
      final parts = timeValue.split(':');

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      final dateTime = DateTime(2026, 1, 1, hour, minute);

      if (timeFormat == '24h') {
        return DateFormat('HH:mm').format(dateTime);
      }

      return DateFormat('h:mm a').format(dateTime);
    } catch (_) {
      return timeValue;
    }
  }

  static String formatDateTime({
    required String date,
    String? time,
    String dateFormat = 'MMM dd, yyyy',
    String timeFormat = '12h',
  }) {
    final formattedDate = formatDate(
      date,
      dateFormat: dateFormat,
    );

    final formattedTime = formatTime(
      time,
      timeFormat: timeFormat,
    );

    if (formattedTime.isEmpty) {
      return formattedDate;
    }

    return '$formattedDate, $formattedTime';
  }
}