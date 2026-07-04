import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../core/utils/date_range_utils.dart';
import '../models/expense_transaction.dart';
import '../models/expense_transaction_item.dart';

class TransactionRepository {
  Future<int> createTransaction({
    required ExpenseTransaction transaction,
    required List<ExpenseTransactionItem> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Transaction must have at least one item.');
    }

    final db = await AppDatabase.instance.database;

    return await db.transaction((txn) async {
      final transactionId = await txn.insert(
        'expense_transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in items) {
        await txn.insert(
          'expense_transaction_items',
          item.toMap(overrideTransactionId: transactionId),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      return transactionId;
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await AppDatabase.instance.database;

    return await db.rawQuery('''
      SELECT
        t.*,
        m.name AS merchant_name,
        p.name AS payment_method_name,
        a.name AS account_name
      FROM expense_transactions t
      LEFT JOIN merchants m ON m.id = t.merchant_id
      LEFT JOIN payment_methods p ON p.id = t.payment_method_id
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE t.deleted_at IS NULL
      ORDER BY t.transaction_date DESC, t.transaction_time DESC, t.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 5,
  }) async {
    final db = await AppDatabase.instance.database;

    return await db.rawQuery(
      '''
    SELECT
      t.*,
      m.name AS merchant_name,
      p.name AS payment_method_name,
      a.name AS account_name,

      (
        SELECT COALESCE(c.name, 'Uncategorized')
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_name,

      (
        SELECT c.color
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_color,

      (
        SELECT c.icon
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_icon

    FROM expense_transactions t
    LEFT JOIN merchants m ON m.id = t.merchant_id
    LEFT JOIN payment_methods p ON p.id = t.payment_method_id
    LEFT JOIN accounts a ON a.id = t.account_id
    WHERE t.deleted_at IS NULL
    ORDER BY
      t.transaction_date DESC,
      t.transaction_time DESC,
      t.id DESC
    LIMIT ?
    ''',
      [limit],
    );
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT
        t.*,
        m.name AS merchant_name,
        p.name AS payment_method_name,
        a.name AS account_name
      FROM expense_transactions t
      LEFT JOIN merchants m ON m.id = t.merchant_id
      LEFT JOIN payment_methods p ON p.id = t.payment_method_id
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE t.id = ? AND t.deleted_at IS NULL
      LIMIT 1
    ''',
      [id],
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getItemsByTransactionId(
    int transactionId,
  ) async {
    final db = await AppDatabase.instance.database;

    return await db.rawQuery(
      '''
      SELECT
        i.*,
        c.name AS category_name,
        c.color AS category_color,
        c.icon AS category_icon
      FROM expense_transaction_items i
      LEFT JOIN categories c ON c.id = i.category_id
      WHERE i.transaction_id = ? AND i.deleted_at IS NULL
      ORDER BY i.line_no ASC
    ''',
      [transactionId],
    );
  }

  Future<void> softDeleteTransaction(int transactionId) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'expense_transactions',
        {'deleted_at': now, 'updated_at': now, 'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      await txn.update(
        'expense_transaction_items',
        {'deleted_at': now, 'updated_at': now, 'sync_status': 'pending_delete'},
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<int> getTodayTotal() async {
    final db = await AppDatabase.instance.database;
    final today = DateRangeUtils.todayDate();

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM expense_transactions
      WHERE transaction_date = ?
      AND deleted_at IS NULL
    ''',
      [today],
    );

    return _readTotal(result);
  }

  Future<int> getMonthTotal() async {
    final db = await AppDatabase.instance.database;
    final monthPrefix = DateRangeUtils.currentMonthPrefix();

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM expense_transactions
      WHERE transaction_date LIKE ?
      AND deleted_at IS NULL
    ''',
      ['$monthPrefix%'],
    );

    return _readTotal(result);
  }

  Future<int> getWeekTotal() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final start = DateRangeUtils.dateOnly(DateRangeUtils.startOfWeek(now));

    final end = DateRangeUtils.dateOnly(DateRangeUtils.endOfWeek(now));

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM expense_transactions
      WHERE transaction_date BETWEEN ? AND ?
      AND deleted_at IS NULL
    ''',
      [start, end],
    );

    return _readTotal(result);
  }

  Future<int> getTodayTransactionCount() async {
    final db = await AppDatabase.instance.database;
    final today = DateRangeUtils.todayDate();

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date = ?
    AND deleted_at IS NULL
    ''',
      [today],
    );

    return _readCount(result);
  }

  Future<int> getWeekTransactionCount() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final start = DateRangeUtils.dateOnly(
      DateRangeUtils.startOfWeek(now),
    );

    final end = DateRangeUtils.dateOnly(
      DateRangeUtils.endOfWeek(now),
    );

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date BETWEEN ? AND ?
    AND deleted_at IS NULL
    ''',
      [start, end],
    );

    return _readCount(result);
  }

  Future<int> getMonthTransactionCount() async {
    final db = await AppDatabase.instance.database;
    final monthPrefix = DateRangeUtils.currentMonthPrefix();

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date LIKE ?
    AND deleted_at IS NULL
    ''',
      ['$monthPrefix%'],
    );

    return _readCount(result);
  }

  Future<List<Map<String, dynamic>>>
  getTotalsByCategoryForCurrentMonth() async {
    final db = await AppDatabase.instance.database;
    final monthPrefix = DateRangeUtils.currentMonthPrefix();

    return await db.rawQuery(
      '''
      SELECT
        c.id AS category_id,
        c.name AS category_name,
        c.color AS category_color,
        c.icon AS category_icon,
        COALESCE(SUM(i.subtotal_amount), 0) AS total_amount
      FROM expense_transaction_items i
      INNER JOIN expense_transactions t ON t.id = i.transaction_id
      LEFT JOIN categories c ON c.id = i.category_id
      WHERE t.transaction_date LIKE ?
      AND t.deleted_at IS NULL
      AND i.deleted_at IS NULL
      GROUP BY c.id, c.name, c.color, c.icon
      ORDER BY total_amount DESC
    ''',
      ['$monthPrefix%'],
    );
  }

  Future<void> updateTransaction({
    required int transactionId,
    required ExpenseTransaction transaction,
    required List<ExpenseTransactionItem> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Transaction must have at least one item.');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'expense_transactions',
        {
          'merchant_id': transaction.merchantId,
          'title': transaction.title,
          'transaction_date': transaction.transactionDate,
          'transaction_time': transaction.transactionTime,
          'payment_method_id': transaction.paymentMethodId,
          'account_id': transaction.accountId,
          'notes': transaction.notes,
          'subtotal_amount': transaction.subtotalAmount,
          'discount_amount': transaction.discountAmount,
          'tax_amount': transaction.taxAmount,
          'extra_amount': transaction.extraAmount,
          'total_amount': transaction.totalAmount,
          'item_count': transaction.itemCount,
          'receipt_count': transaction.receiptCount,
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      await txn.delete(
        'expense_transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      for (final item in items) {
        await txn.insert(
          'expense_transaction_items',
          item.toMap(overrideTransactionId: transactionId),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenseTrend({
    int monthCount = 6,
  }) async {
    if (monthCount <= 0) {
      return [];
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final firstMonth = DateTime(
      now.year,
      now.month - monthCount + 1,
      1,
    );

    final startDate = DateRangeUtils.dateOnly(firstMonth);

    return await db.rawQuery(
      '''
    SELECT
      SUBSTR(transaction_date, 1, 7) AS month_key,
      COALESCE(SUM(total_amount), 0) AS total_amount,
      COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date >= ?
    AND deleted_at IS NULL
    GROUP BY SUBSTR(transaction_date, 1, 7)
    ORDER BY month_key ASC
    ''',
      [startDate],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsForDate(
      DateTime date,
      ) async {
    final db = await AppDatabase.instance.database;
    final dateText = DateRangeUtils.dateOnly(date);

    return await db.rawQuery(
      '''
    SELECT
      t.*,
      m.name AS merchant_name,
      p.name AS payment_method_name,
      a.name AS account_name,

      (
        SELECT COALESCE(c.name, 'Uncategorized')
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_name,

      (
        SELECT c.color
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_color,

      (
        SELECT c.icon
        FROM expense_transaction_items i
        LEFT JOIN categories c ON c.id = i.category_id
        WHERE i.transaction_id = t.id
        AND i.deleted_at IS NULL
        ORDER BY i.subtotal_amount DESC, i.line_no ASC
        LIMIT 1
      ) AS primary_category_icon

    FROM expense_transactions t
    LEFT JOIN merchants m ON m.id = t.merchant_id
    LEFT JOIN payment_methods p ON p.id = t.payment_method_id
    LEFT JOIN accounts a ON a.id = t.account_id
    WHERE t.transaction_date = ?
    AND t.deleted_at IS NULL
    ORDER BY
      t.transaction_time DESC,
      t.id DESC
    ''',
      [dateText],
    );
  }

  Future<int> getTotalForDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateText = DateRangeUtils.dateOnly(date);

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(total_amount), 0) AS total
    FROM expense_transactions
    WHERE transaction_date = ?
    AND deleted_at IS NULL
    ''',
      [dateText],
    );

    return _readTotal(result);
  }

  Future<int> getTransactionCountForDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateText = DateRangeUtils.dateOnly(date);

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date = ?
    AND deleted_at IS NULL
    ''',
      [dateText],
    );

    return _readCount(result);
  }

  Future<List<Map<String, dynamic>>> getTotalsByCategoryForDate(
      DateTime date,
      ) async {
    final db = await AppDatabase.instance.database;
    final dateText = DateRangeUtils.dateOnly(date);

    return await db.rawQuery(
      '''
    SELECT
      COALESCE(c.id, 0) AS category_id,
      COALESCE(c.name, 'Uncategorized') AS category_name,
      c.color AS category_color,
      c.icon AS category_icon,
      COUNT(DISTINCT i.transaction_id) AS transaction_count,
      COALESCE(SUM(i.subtotal_amount), 0) AS total_amount
    FROM expense_transaction_items i
    INNER JOIN expense_transactions t
      ON t.id = i.transaction_id
    LEFT JOIN categories c
      ON c.id = i.category_id
    WHERE t.transaction_date = ?
    AND t.deleted_at IS NULL
    AND i.deleted_at IS NULL
    GROUP BY
      c.id,
      c.name,
      c.color,
      c.icon
    ORDER BY total_amount DESC
    ''',
      [dateText],
    );
  }

  Future<int?> getEarliestTransactionYear() async {
    final db = await AppDatabase.instance.database;

    final result = await db.rawQuery(
      '''
    SELECT MIN(
      CAST(SUBSTR(transaction_date, 1, 4) AS INTEGER)
    ) AS earliest_year
    FROM expense_transactions
    WHERE deleted_at IS NULL
    AND transaction_date IS NOT NULL
    AND transaction_date != ''
    ''',
    );

    if (result.isEmpty) {
      return null;
    }

    final value = result.first['earliest_year'];

    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenseTrendForYear(
      int year,
      ) async {
    final db = await AppDatabase.instance.database;

    final startDate = '$year-01-01';
    final endDate = '${year + 1}-01-01';

    return await db.rawQuery(
      '''
    SELECT
      CAST(SUBSTR(transaction_date, 6, 2) AS INTEGER)
        AS month_number,
      SUBSTR(transaction_date, 1, 7) AS month_key,
      COALESCE(SUM(total_amount), 0) AS total_amount,
      COUNT(*) AS transaction_count
    FROM expense_transactions
    WHERE transaction_date >= ?
    AND transaction_date < ?
    AND deleted_at IS NULL
    GROUP BY SUBSTR(transaction_date, 1, 7)
    ORDER BY month_number ASC
    ''',
      [startDate, endDate],
    );
  }

  Future<int> getYearTotal(int year) async {
    final db = await AppDatabase.instance.database;

    final startDate = '$year-01-01';
    final endDate = '${year + 1}-01-01';

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(total_amount), 0) AS total
    FROM expense_transactions
    WHERE transaction_date >= ?
    AND transaction_date < ?
    AND deleted_at IS NULL
    ''',
      [startDate, endDate],
    );

    return _readTotal(result);
  }

  int _readTotal(List<Map<String, dynamic>> result) {
    if (result.isEmpty) return 0;

    final value = result.first['total'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  int _readCount(List<Map<String, dynamic>> result) {
    if (result.isEmpty) return 0;

    final value = result.first['transaction_count'];

    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }
}
