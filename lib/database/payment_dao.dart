import '../models/payment.dart';
import 'database_helper.dart';

class PaymentDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(Payment payment) async {
    final db = await _db.database;
    return await db.insert('payments', payment.toMap()..remove('id'));
  }

  Future<List<Payment>> findBySale(int saleId) async {
    final db = await _db.database;
    final maps = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'payment_date DESC',
    );
    return maps.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> findByClient(int clientId) async {
    final db = await _db.database;
    final maps = await db.query(
      'payments',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'payment_date DESC',
    );
    return maps.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> findAll({DateTime? from, DateTime? to}) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (from != null) { conditions.add('payment_date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { conditions.add('payment_date <= ?'); args.add(to.toIso8601String()); }
    final maps = await db.query(
      'payments',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'payment_date DESC',
    );
    return maps.map(Payment.fromMap).toList();
  }

  Future<double> getTotalReceivedThisMonth(int year, int month) async {
    final db = await _db.database;
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE payment_date BETWEEN ? AND ?',
      [from, to],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
