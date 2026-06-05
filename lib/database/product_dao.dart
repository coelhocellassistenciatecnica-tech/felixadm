import '../models/product.dart';
import 'database_helper.dart';

class ProductDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(Product product) async {
    final db = await _db.database;
    return await db.insert('products', product.toMap()..remove('id'));
  }

  Future<int> update(Product product) async {
    final db = await _db.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<Product?> findById(int id) async {
    final db = await _db.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> findAll({String? search, String? brand, String? category}) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      conditions.add('(name LIKE ? OR code LIKE ? OR brand LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (brand != null && brand.isNotEmpty) {
      conditions.add('brand = ?');
      args.add(brand);
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      args.add(category);
    }
    final maps = await db.query(
      'products',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<List<Product>> findLowStock() async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      'SELECT * FROM products WHERE stock_quantity <= min_stock_alert ORDER BY stock_quantity ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<int> updateStock(int id, int delta) async {
    final db = await _db.database;
    return await db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
      [delta, DateTime.now().toIso8601String(), id],
    );
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  Future<int> totalStockValue() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(stock_quantity) as total FROM products',
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
