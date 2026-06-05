import '../models/sale.dart';
import '../models/sale_item.dart';
import 'database_helper.dart';

class SaleDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await _db.database;
    int saleId = 0;
    await db.transaction((txn) async {
      final map = sale.toMap()..remove('id');
      saleId = await txn.insert('sales', map);
      for (final item in items) {
        final itemMap = item.toMap()
          ..remove('id')
          ..['sale_id'] = saleId;
        await txn.insert('sale_items', itemMap);
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.productId],
        );
        await txn.insert('stock_movements', {
          'product_id': item.productId,
          'product_name': item.productName,
          'movement_type': 'out',
          'quantity': item.quantity,
          'reason': 'Venda #$saleId',
          'sale_id': saleId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
    return saleId;
  }

  Future<Sale?> findById(int id) async {
    final db = await _db.database;
    final maps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final sale = Sale.fromMap(maps.first);
    final itemMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [id]);
    sale.items = itemMaps.map(SaleItem.fromMap).toList();
    return sale;
  }

  Future<List<Sale>> findAll({
    int? clientId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (clientId != null) { conditions.add('client_id = ?'); args.add(clientId); }
    if (from != null) { conditions.add('sale_date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { conditions.add('sale_date <= ?'); args.add(to.toIso8601String()); }
    if (status != null) { conditions.add('status = ?'); args.add(status); }
    final maps = await db.query(
      'sales',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'sale_date DESC',
    );
    return maps.map(Sale.fromMap).toList();
  }

  Future<void> updateStatus(int id, String status, double amountPaid) async {
    final db = await _db.database;
    await db.update(
      'sales',
      {'status': status, 'amount_paid': amountPaid},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final db = await _db.database;
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_sales,
        SUM(final_amount) as total_amount,
        SUM(amount_paid) as total_received,
        SUM(final_amount - amount_paid) as total_pending
      FROM sales
      WHERE sale_date BETWEEN ? AND ?
    ''', [from, to]);
    return result.first;
  }

  Future<double> getEstimatedProfit(int year, int month) async {
    final db = await _db.database;
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery('''
      SELECT SUM((si.unit_price - si.cost_price) * si.quantity - si.discount) as profit
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      WHERE s.sale_date BETWEEN ? AND ?
    ''', [from, to]);
    return (result.first['profit'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getTopClients(int limit) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT client_id, client_name, COUNT(*) as sale_count, SUM(final_amount) as total
      FROM sales
      GROUP BY client_id
      ORDER BY total DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT product_id, product_name, SUM(quantity) as qty, SUM(unit_price * quantity) as revenue
      FROM sale_items
      GROUP BY product_id
      ORDER BY qty DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }
}
