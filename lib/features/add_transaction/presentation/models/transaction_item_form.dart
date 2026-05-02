class TransactionItemForm {
  final String itemName;
  final int? categoryId;
  final double quantity;
  final String unit;
  final int unitPriceAmount;
  final int discountAmount;
  final int taxAmount;
  final String? notes;

  TransactionItemForm({
    required this.itemName,
    this.categoryId,
    required this.quantity,
    required this.unit,
    required this.unitPriceAmount,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.notes,
  });

  int get subtotalAmount {
    final gross = (quantity * unitPriceAmount).round();
    return gross - discountAmount + taxAmount;
  }

  TransactionItemForm copyWith({
    String? itemName,
    int? categoryId,
    double? quantity,
    String? unit,
    int? unitPriceAmount,
    int? discountAmount,
    int? taxAmount,
    String? notes,
  }) {
    return TransactionItemForm(
      itemName: itemName ?? this.itemName,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPriceAmount: unitPriceAmount ?? this.unitPriceAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      notes: notes ?? this.notes,
    );
  }
}
