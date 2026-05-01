import 'app_database.dart';

class DatabaseDebug {
  static Future<void> printDatabaseStatus() async {
    final db = await AppDatabase.instance.database;

    final categories = await db.query('categories');
    final paymentMethods = await db.query('payment_methods');
    final accounts = await db.query('accounts');

    print('DATABASE READY');
    print('Categories: ${categories.length}');
    print('Payment Methods: ${paymentMethods.length}');
    print('Accounts: ${accounts.length}');
  }
}