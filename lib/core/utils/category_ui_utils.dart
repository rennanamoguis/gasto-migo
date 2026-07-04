import 'package:flutter/material.dart';

abstract final class CategoryUiUtils {
  static const List<Color> _fallbackColors = [
    Color(0xFF078C44),
    Color(0xFFF57C00),
    Color(0xFF7047EB),
    Color(0xFF1769D2),
    Color(0xFFE9A23B),
    Color(0xFFDC4C64),
    Color(0xFF00897B),
  ];

  static Color resolveColor(
      dynamic rawColor, {
        int fallbackIndex = 0,
      }) {
    final fallback =
    _fallbackColors[fallbackIndex % _fallbackColors.length];

    if (rawColor == null) {
      return fallback;
    }

    if (rawColor is int) {
      final value = rawColor <= 0xFFFFFF
          ? rawColor | 0xFF000000
          : rawColor;

      return Color(value);
    }

    final text = rawColor.toString().trim().toLowerCase();

    const namedColors = {
      'green': Color(0xFF078C44),
      'orange': Color(0xFFF57C00),
      'purple': Color(0xFF7047EB),
      'blue': Color(0xFF1769D2),
      'yellow': Color(0xFFE9A23B),
      'red': Color(0xFFDC4C64),
      'teal': Color(0xFF00897B),
    };

    if (namedColors.containsKey(text)) {
      return namedColors[text]!;
    }

    var hex = text
        .replaceFirst('#', '')
        .replaceFirst('0x', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);

      if (parsed != null) {
        return Color(parsed);
      }
    }

    return fallback;
  }

  static IconData resolveIcon(
      dynamic rawIcon,
      String categoryName,
      ) {
    if (rawIcon is int) {
      return IconData(
        rawIcon,
        fontFamily: 'MaterialIcons',
      );
    }

    final rawText =
        rawIcon?.toString().trim().toLowerCase() ?? '';

    final numericCodePoint = int.tryParse(rawText);

    if (numericCodePoint != null) {
      return IconData(
        numericCodePoint,
        fontFamily: 'MaterialIcons',
      );
    }

    final searchableText =
        '$rawText ${categoryName.toLowerCase()}';

    if (searchableText.contains('food') ||
        searchableText.contains('drink') ||
        searchableText.contains('restaurant') ||
        searchableText.contains('meal') ||
        searchableText.contains('dining')) {
      return Icons.restaurant_rounded;
    }

    if (searchableText.contains('shopping') ||
        searchableText.contains('shop') ||
        searchableText.contains('grocery') ||
        searchableText.contains('supermarket')) {
      return Icons.shopping_bag_rounded;
    }

    if (searchableText.contains('health') ||
        searchableText.contains('medical') ||
        searchableText.contains('medicine') ||
        searchableText.contains('pharmacy') ||
        searchableText.contains('hospital')) {
      return Icons.medical_services_rounded;
    }

    if (searchableText.contains('transport') ||
        searchableText.contains('car') ||
        searchableText.contains('bus') ||
        searchableText.contains('ride') ||
        searchableText.contains('travel')) {
      return Icons.directions_car_rounded;
    }

    if (searchableText.contains('bill') ||
        searchableText.contains('utility') ||
        searchableText.contains('electric') ||
        searchableText.contains('water')) {
      return Icons.receipt_long_rounded;
    }

    if (searchableText.contains('education') ||
        searchableText.contains('school')) {
      return Icons.school_rounded;
    }

    if (searchableText.contains('entertainment') ||
        searchableText.contains('movie') ||
        searchableText.contains('game')) {
      return Icons.movie_rounded;
    }

    if (searchableText.contains('home') ||
        searchableText.contains('house') ||
        searchableText.contains('rent')) {
      return Icons.home_rounded;
    }

    if (searchableText.contains('personal') ||
        searchableText.contains('care')) {
      return Icons.person_rounded;
    }

    if (searchableText.contains('gift')) {
      return Icons.card_giftcard_rounded;
    }

    return Icons.category_rounded;
  }
}