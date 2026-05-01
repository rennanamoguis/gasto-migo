import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/merchant_model.dart';
import '../models/payment_method_model.dart';

class LookupRepository {
  final _uuid = const Uuid();

  Future<List<CategoryModel>> getCategories() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'categories',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'sort_order ASC, name ASC',
    );

    return result.map(CategoryModel.fromMap).toList();
  }

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'payment_methods',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'sort_order ASC, name ASC',
    );

    return result.map(PaymentMethodModel.fromMap).toList();
  }

  Future<List<AccountModel>> getAccounts() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'accounts',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'name ASC',
    );

    return result.map(AccountModel.fromMap).toList();
  }

  Future<List<MerchantModel>> getMerchants() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'merchants',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );

    return result.map(MerchantModel.fromMap).toList();
  }

  Future<int> findOrCreateMerchant(String merchantName) async {
    final cleanName = merchantName.trim();

    if (cleanName.isEmpty) {
      throw Exception('Merchant name is required.');
    }

    final normalizedName = cleanName.toLowerCase();
    final db = await AppDatabase.instance.database;

    final existing = await db.query(
      'merchants',
      where: 'normalized_name = ? AND deleted_at IS NULL',
      whereArgs: [normalizedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    final now = DateTime.now().toIso8601String();

    return await db.insert(
      'merchants',
      {
        'uuid': _uuid.v4(),
        'name': cleanName,
        'normalized_name': normalizedName,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int?> getDefaultAccountId() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'accounts',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['id'] as int;
  }

  Future<int?> getDefaultPaymentMethodId() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'payment_methods',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'sort_order ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['id'] as int;
  }
}