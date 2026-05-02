import 'package:intl/intl.dart';

class MoneyUtils {
  static int pesosToCentavos(String value) {
    return amountToMinorUnit(value);
  }

  static int amountToMinorUnit(String value) {
    final cleanValue = value.replaceAll(',', '').trim();

    if (cleanValue.isEmpty) return 0;

    final amount = double.tryParse(cleanValue) ?? 0;
    return (amount * 100).round();
  }

  static String formatAmount(
      int minorUnitAmount, {
        String currencySymbol = '₱',
      }) {
    final amount = minorUnitAmount / 100;

    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }

  static String centavosToPesoText(int centavos) {
    return formatAmount(
      centavos,
      currencySymbol: '₱',
    );
  }

  static int calculateItemSubtotal({
    required double quantity,
    required int unitPriceAmount,
    int discountAmount = 0,
    int taxAmount = 0,
  }) {
    final grossAmount = (quantity * unitPriceAmount).round();
    return grossAmount - discountAmount + taxAmount;
  }
}