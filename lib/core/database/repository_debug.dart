import 'package:uuid/uuid.dart';

import '../../models/expense_transaction.dart';
import '../../models/expense_transaction_item.dart';
import '../../repositories/lookup_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../utils/date_range_utils.dart';
import '../utils/money_utils.dart';

class RepositoryDebug {
  static Future<void> insertSampleTransaction() async {
    final lookupRepository = LookupRepository();
    final transactionRepository = TransactionRepository();
    const uuid = Uuid();

    final merchantId = await lookupRepository.findOrCreateMerchant(
      'Alturas Grocery',
    );

    final paymentMethodId = await lookupRepository.getDefaultPaymentMethodId();
    final accountId = await lookupRepository.getDefaultAccountId();

    final now = DateTime.now().toIso8601String();

    final riceAmount = MoneyUtils.pesosToCentavos('120');
    final coffeeAmount = MoneyUtils.pesosToCentavos('250');
    final breadAmount = MoneyUtils.pesosToCentavos('45');

    final items = [
      ExpenseTransactionItem(
        uuid: uuid.v4(),
        lineNo: 1,
        itemName: 'Rice',
        normalizedItemName: 'rice',
        categoryId: null,
        quantity: 1,
        unit: 'kg',
        unitPriceAmount: riceAmount,
        discountAmount: 0,
        taxAmount: 0,
        subtotalAmount: riceAmount,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'local',
      ),
      ExpenseTransactionItem(
        uuid: uuid.v4(),
        lineNo: 2,
        itemName: 'Coffee',
        normalizedItemName: 'coffee',
        categoryId: null,
        quantity: 1,
        unit: 'pc',
        unitPriceAmount: coffeeAmount,
        discountAmount: 0,
        taxAmount: 0,
        subtotalAmount: coffeeAmount,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'local',
      ),
      ExpenseTransactionItem(
        uuid: uuid.v4(),
        lineNo: 3,
        itemName: 'Bread',
        normalizedItemName: 'bread',
        categoryId: null,
        quantity: 1,
        unit: 'pc',
        unitPriceAmount: breadAmount,
        discountAmount: 0,
        taxAmount: 0,
        subtotalAmount: breadAmount,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'local',
      ),
    ];

    final subtotal = items.fold<int>(
      0,
          (sum, item) => sum + item.subtotalAmount,
    );

    final transaction = ExpenseTransaction(
      uuid: uuid.v4(),
      merchantId: merchantId,
      title: 'Alturas Grocery',
      transactionDate: DateRangeUtils.todayDate(),
      transactionTime: DateRangeUtils.currentTimeHHmm(),
      paymentMethodId: paymentMethodId,
      accountId: accountId,
      notes: 'Sample transaction',
      subtotalAmount: subtotal,
      discountAmount: 0,
      taxAmount: 0,
      extraAmount: 0,
      totalAmount: subtotal,
      itemCount: items.length,
      receiptCount: 0,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'local',
    );

    await transactionRepository.createTransaction(
      transaction: transaction,
      items: items,
    );

    final todayTotal = await transactionRepository.getTodayTotal();
    final transactions = await transactionRepository.getTransactions();

    print('SAMPLE TRANSACTION INSERTED');
    print('Today Total: ${MoneyUtils.centavosToPesoText(todayTotal)}');
    print('Transactions Count: ${transactions.length}');
  }
}