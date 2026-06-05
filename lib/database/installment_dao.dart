import '../models/installment.dart';
import 'database_helper.dart';

class InstallmentDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> insertAll(List<Installment> installments) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final inst in installments) {
      batch.insert('installments', inst.toMap()..remove('id'));
    }
    await batch.commit();
  }

  Future<List<Installment>> findBySale(int saleId) async {
    final db = await _db.database;
    final maps = await db.query(
      'installments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'installment_number ASC',
    );
    return maps.map(Installment.fromMap).toList();
  }

  Future<List<Installment>> findPending({int? clientId}) async {
    final db = await _db.database;
    final conditions = ["status != 'paid'"];
    final args = <dynamic>[];
    if (clientId != null) {
      conditions.add('client_id = ?');
      args.add(clientId);
    }
    final maps = await db.query(
      'installments',
      where: conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'due_date ASC',
    );
    return maps.map(Installment.fromMap).toList();
  }

  Future<List<Installment>> findOverdue() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.rawQuery(
      "SELECT * FROM installments WHERE status = 'pending' AND due_date < ? ORDER BY due_date ASC",
      [now],
    );
    return maps.map(Installment.fromMap).toList();
  }

  Future<List<Installment>> findDueSoon(int daysAhead) async {
    final db = await _db.database;
    final now = DateTime.now();
    final soon = now.add(Duration(days: daysAhead)).toIso8601String();
    final maps = await db.rawQuery(
      "SELECT * FROM installments WHERE status = 'pending' AND due_date <= ? AND due_date >= ? ORDER BY due_date ASC",
      [soon, now.toIso8601String()],
    );
    return maps.map(Installment.fromMap).toList();
  }

  Future<void> markPaid(int id, double amount, DateTime paidAt) async {
    final db = await _db.database;
    await db.update(
      'installments',
      {
        'amount_paid': amount,
        'paid_at': paidAt.toIso8601String(),
        'status': 'paid',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOverdueStatuses() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      "UPDATE installments SET status = 'overdue' WHERE status = 'pending' AND due_date < ?",
      [now],
    );
  }

  Future<Map<String, dynamic>> getSummary() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN status != 'paid' THEN amount - amount_paid ELSE 0 END) as total_pending,
        SUM(CASE WHEN status != 'paid' AND due_date < ? THEN amount - amount_paid ELSE 0 END) as total_overdue,
        COUNT(CASE WHEN status != 'paid' AND due_date < ? THEN 1 END) as overdue_count
      FROM installments
    ''', [now, now]);
    return result.first;
  }
}
