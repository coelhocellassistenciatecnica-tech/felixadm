import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jennifer_felix.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        whatsapp TEXT,
        address TEXT,
        neighborhood TEXT,
        city TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        code TEXT,
        cost_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        min_stock_alert INTEGER NOT NULL DEFAULT 5,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        final_amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        installments_count INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'pending',
        amount_paid REAL NOT NULL DEFAULT 0,
        sale_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_brand TEXT NOT NULL,
        unit_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        installment_number INTEGER NOT NULL,
        total_installments INTEGER NOT NULL,
        amount REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL,
        paid_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        client_name TEXT NOT NULL,
        installment_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (installment_id) REFERENCES installments (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        sale_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    return {
      'clients': await db.query('clients'),
      'products': await db.query('products'),
      'sales': await db.query('sales'),
      'sale_items': await db.query('sale_items'),
      'installments': await db.query('installments'),
      'payments': await db.query('payments'),
      'stock_movements': await db.query('stock_movements'),
      'app_settings': await db.query('app_settings'),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'payments', 'installments', 'sale_items', 'sales',
        'stock_movements', 'products', 'clients', 'app_settings'
      ]) {
        await txn.delete(table);
      }
      for (final table in [
        'clients', 'products', 'sales', 'sale_items',
        'installments', 'payments', 'stock_movements', 'app_settings'
      ]) {
        final rows = data[table] as List<dynamic>? ?? [];
        for (final row in rows) {
          await txn.insert(table, Map<String, dynamic>.from(row));
        }
      }
    });
  }
}
