import 'package:sqflite/sqflite.dart';

class DatabaseSchema {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        icon TEXT,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE merchants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        normalized_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        account_type TEXT,
        currency TEXT DEFAULT 'PHP',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        merchant_id INTEGER,
        title TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        transaction_time TEXT,
        payment_method_id INTEGER,
        account_id INTEGER,
        notes TEXT,
        subtotal_amount INTEGER DEFAULT 0,
        discount_amount INTEGER DEFAULT 0,
        tax_amount INTEGER DEFAULT 0,
        extra_amount INTEGER DEFAULT 0,
        total_amount INTEGER DEFAULT 0,
        item_count INTEGER DEFAULT 0,
        receipt_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local',
        FOREIGN KEY (merchant_id) REFERENCES merchants(id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        transaction_id INTEGER NOT NULL,
        line_no INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        normalized_item_name TEXT,
        category_id INTEGER,
        quantity REAL DEFAULT 1,
        unit TEXT,
        unit_price_amount INTEGER DEFAULT 0,
        discount_amount INTEGER DEFAULT 0,
        tax_amount INTEGER DEFAULT 0,
        subtotal_amount INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local',
        FOREIGN KEY (transaction_id) REFERENCES expense_transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        transaction_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'local',
        FOREIGN KEY (transaction_id) REFERENCES expense_transactions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_expense_transactions_date
      ON expense_transactions(transaction_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_expense_transactions_deleted
      ON expense_transactions(deleted_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_expense_items_transaction_id
      ON expense_transaction_items(transaction_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_expense_items_category_id
      ON expense_transaction_items(category_id)
    ''');
  }

  static Future<void> seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('app_meta', {
      'key': 'schema_version',
      'value': '1',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('app_meta', {
      'key': 'currency_code',
      'value': 'PHP',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('app_meta', {
      'key': 'currency_symbol',
      'value': '₱',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('app_meta', {
      'key': 'currency_name',
      'value': 'Philippine Peso',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('payment_methods', {
      'uuid': 'pm-cash',
      'name': 'Cash',
      'icon': 'cash',
      'sort_order': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('payment_methods', {
      'uuid': 'pm-gcash',
      'name': 'GCash',
      'icon': 'mobile',
      'sort_order': 2,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('payment_methods', {
      'uuid': 'pm-card',
      'name': 'Card',
      'icon': 'card',
      'sort_order': 3,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('payment_methods', {
      'uuid': 'pm-bank-transfer',
      'name': 'Bank Transfer',
      'icon': 'bank',
      'sort_order': 4,
      'created_at': now,
      'updated_at': now,
    });

    final categories = [
      {
        'uuid': 'cat-food-dining',
        'name': 'Food & Dining',
        'icon': 'restaurant',
        'color': '#0B7A3E',
      },
      {
        'uuid': 'cat-groceries',
        'name': 'Groceries',
        'icon': 'shopping_cart',
        'color': '#1F78BE',
      },
      {
        'uuid': 'cat-transport',
        'name': 'Transport',
        'icon': 'directions_car',
        'color': '#D97706',
      },
      {
        'uuid': 'cat-health',
        'name': 'Health',
        'icon': 'local_pharmacy',
        'color': '#DC2626',
      },
      {
        'uuid': 'cat-utilities',
        'name': 'Utilities',
        'icon': 'bolt',
        'color': '#6D28D9',
      },
      {
        'uuid': 'cat-education',
        'name': 'Education',
        'icon': 'school',
        'color': '#0F766E',
      },
      {
        'uuid': 'cat-personal',
        'name': 'Personal',
        'icon': 'person',
        'color': '#BE185D',
      },
      {
        'uuid': 'cat-others',
        'name': 'Others',
        'icon': 'category',
        'color': '#4B5563',
      },
    ];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];

      await db.insert('categories', {
        'uuid': category['uuid'],
        'name': category['name'],
        'icon': category['icon'],
        'color': category['color'],
        'sort_order': i + 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    await db.insert('accounts', {
      'uuid': 'acc-wallet',
      'name': 'Wallet',
      'account_type': 'cash',
      'currency': 'PHP',
      'created_at': now,
      'updated_at': now,
    });
  }
}
