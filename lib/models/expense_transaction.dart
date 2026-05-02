class ExpenseTransaction {
  final int? id;
  final String uuid;
  final int? merchantId;
  final String title;
  final String transactionDate;
  final String? transactionTime;
  final int? paymentMethodId;
  final int? accountId;
  final String? notes;
  final int subtotalAmount;
  final int discountAmount;
  final int taxAmount;
  final int extraAmount;
  final int totalAmount;
  final int itemCount;
  final int receiptCount;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  ExpenseTransaction({
    this.id,
    required this.uuid,
    this.merchantId,
    required this.title,
    required this.transactionDate,
    this.transactionTime,
    this.paymentMethodId,
    this.accountId,
    this.notes,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.extraAmount,
    required this.totalAmount,
    required this.itemCount,
    required this.receiptCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      merchantId: map['merchant_id'] as int?,
      title: map['title'] as String,
      transactionDate: map['transaction_date'] as String,
      transactionTime: map['transaction_time'] as String?,
      paymentMethodId: map['payment_method_id'] as int?,
      accountId: map['account_id'] as int?,
      notes: map['notes'] as String?,
      subtotalAmount: map['subtotal_amount'] as int? ?? 0,
      discountAmount: map['discount_amount'] as int? ?? 0,
      taxAmount: map['tax_amount'] as int? ?? 0,
      extraAmount: map['extra_amount'] as int? ?? 0,
      totalAmount: map['total_amount'] as int? ?? 0,
      itemCount: map['item_count'] as int? ?? 0,
      receiptCount: map['receipt_count'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'merchant_id': merchantId,
      'title': title,
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'payment_method_id': paymentMethodId,
      'account_id': accountId,
      'notes': notes,
      'subtotal_amount': subtotalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'extra_amount': extraAmount,
      'total_amount': totalAmount,
      'item_count': itemCount,
      'receipt_count': receiptCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  ExpenseTransaction copyWith({
    int? id,
    String? uuid,
    int? merchantId,
    String? title,
    String? transactionDate,
    String? transactionTime,
    int? paymentMethodId,
    int? accountId,
    String? notes,
    int? subtotalAmount,
    int? discountAmount,
    int? taxAmount,
    int? extraAmount,
    int? totalAmount,
    int? itemCount,
    int? receiptCount,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      merchantId: merchantId ?? this.merchantId,
      title: title ?? this.title,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      extraAmount: extraAmount ?? this.extraAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
      receiptCount: receiptCount ?? this.receiptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
