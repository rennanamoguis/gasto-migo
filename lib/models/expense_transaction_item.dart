class ExpenseTransactionItem {
  final int? id;
  final String uuid;
  final int? transactionId;
  final int lineNo;
  final String itemName;
  final String? normalizedItemName;
  final int? categoryId;
  final double quantity;
  final String? unit;
  final int unitPriceAmount;
  final int discountAmount;
  final int taxAmount;
  final int subtotalAmount;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  ExpenseTransactionItem({
    this.id,
    required this.uuid,
    this.transactionId,
    required this.lineNo,
    required this.itemName,
    this.normalizedItemName,
    this.categoryId,
    required this.quantity,
    this.unit,
    required this.unitPriceAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.subtotalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  factory ExpenseTransactionItem.fromMap(Map<String, dynamic> map) {
    return ExpenseTransactionItem(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      transactionId: map['transaction_id'] as int?,
      lineNo: map['line_no'] as int? ?? 0,
      itemName: map['item_name'] as String,
      normalizedItemName: map['normalized_item_name'] as String?,
      categoryId: map['category_id'] as int?,
      quantity: (map['quantity'] as num? ?? 1).toDouble(),
      unit: map['unit'] as String?,
      unitPriceAmount: map['unit_price_amount'] as int? ?? 0,
      discountAmount: map['discount_amount'] as int? ?? 0,
      taxAmount: map['tax_amount'] as int? ?? 0,
      subtotalAmount: map['subtotal_amount'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toMap({int? overrideTransactionId}) {
    return {
      'id': id,
      'uuid': uuid,
      'transaction_id': overrideTransactionId ?? transactionId,
      'line_no': lineNo,
      'item_name': itemName,
      'normalized_item_name': normalizedItemName,
      'category_id': categoryId,
      'quantity': quantity,
      'unit': unit,
      'unit_price_amount': unitPriceAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'subtotal_amount': subtotalAmount,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  ExpenseTransactionItem copyWith({
    int? id,
    String? uuid,
    int? transactionId,
    int? lineNo,
    String? itemName,
    String? normalizedItemName,
    int? categoryId,
    double? quantity,
    String? unit,
    int? unitPriceAmount,
    int? discountAmount,
    int? taxAmount,
    int? subtotalAmount,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return ExpenseTransactionItem(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      transactionId: transactionId ?? this.transactionId,
      lineNo: lineNo ?? this.lineNo,
      itemName: itemName ?? this.itemName,
      normalizedItemName: normalizedItemName ?? this.normalizedItemName,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPriceAmount: unitPriceAmount ?? this.unitPriceAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
