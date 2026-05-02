import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../models/app_preferences.dart';

class SettingsRepository {
  final _uuid = const Uuid();

  Future<String?> getMetaValue(String key) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['value']?.toString();
  }

  Future<AppPreferences> getPreferences() async {
    final currencyCode = await getMetaValue('currency_code') ?? 'PHP';
    final currencySymbol = await getMetaValue('currency_symbol') ?? '₱';
    final currencyName = await getMetaValue('currency_name') ?? 'Philippine Peso';
    final dateFormat = await getMetaValue('date_format') ?? 'MMM dd, yyyy';
    final timeFormat = await getMetaValue('time_format') ?? '12h';

    return AppPreferences(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencyName: currencyName,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
    );
  }

  Future<void> setMetaValue(String key, String value) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'app_meta',
      {
        'key': key,
        'value': value,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await AppDatabase.instance.database;

    return db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC, name ASC',
    );
  }

  Future<void> saveCategory({
    int? id,
    required String name,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      await db.insert('categories', {
        'uuid': _uuid.v4(),
        'name': name.trim(),
        'icon': 'category',
        'color': '#4B5563',
        'sort_order': 99,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      });
    } else {
      await db.update(
        'categories',
        {
          'name': name.trim(),
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> softDeleteCategory(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'categories',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending_delete',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final db = await AppDatabase.instance.database;

    return db.query(
      'payment_methods',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC, name ASC',
    );
  }

  Future<void> savePaymentMethod({
    int? id,
    required String name,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      await db.insert('payment_methods', {
        'uuid': _uuid.v4(),
        'name': name.trim(),
        'icon': 'payment',
        'sort_order': 99,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      });
    } else {
      await db.update(
        'payment_methods',
        {
          'name': name.trim(),
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> softDeletePaymentMethod(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'payment_methods',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending_delete',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await AppDatabase.instance.database;

    return db.query(
      'accounts',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
  }

  Future<void> saveAccount({
    int? id,
    required String name,
    String accountType = 'cash',
    String currency = 'PHP',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      await db.insert('accounts', {
        'uuid': _uuid.v4(),
        'name': name.trim(),
        'account_type': accountType,
        'currency': currency,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      });
    } else {
      await db.update(
        'accounts',
        {
          'name': name.trim(),
          'account_type': accountType,
          'currency': currency,
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> softDeleteAccount(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'accounts',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending_delete',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getMerchants() async {
    final db = await AppDatabase.instance.database;

    return db.query(
      'merchants',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
  }

  Future<void> saveMerchant({
    int? id,
    required String name,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final cleanName = name.trim();

    if (id == null) {
      await db.insert('merchants', {
        'uuid': _uuid.v4(),
        'name': cleanName,
        'normalized_name': cleanName.toLowerCase(),
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
      });
    } else {
      await db.update(
        'merchants',
        {
          'name': cleanName,
          'normalized_name': cleanName.toLowerCase(),
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> softDeleteMerchant(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'merchants',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending_delete',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}