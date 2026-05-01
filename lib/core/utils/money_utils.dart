import 'package:intl/intl.dart';

class MoneyUtils {
  static int pesosToCentavos(String value) {
    final cleanValue = value.replaceAll(',', '').trim();

    if (cleanValue.isEmpty) return 0;

    final amount = double.tryParse(cleanValue) ?? 0;
    return (amount * 100).round();
  }

  static String centavosToPesoText(int centavos) {
    final pesos = centavos / 100;

    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return formatter.format(pesos);
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