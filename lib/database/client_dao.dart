import '../models/client.dart';
import 'database_helper.dart';

class ClientDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(Client client) async {
    final db = await _db.database;
    return await db.insert('clients', client.toMap()..remove('id'));
  }

  Future<int> update(Client client) async {
    final db = await _db.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<Client?> findById(int id) async {
    final db = await _db.database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<List<Client>> findAll({String? search}) async {
    final db = await _db.database;
    if (search != null && search.isNotEmpty) {
      final maps = await db.query(
        'clients',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$search%', '%$search%'],
        orderBy: 'name ASC',
      );
      return maps.map(Client.fromMap).toList();
    }
    final maps = await db.query('clients', orderBy: 'name ASC');
    return maps.map(Client.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    return result.first['count'] as int;
  }
}
