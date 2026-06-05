import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../database/client_dao.dart';

class ClientProvider extends ChangeNotifier {
  final ClientDao _dao = ClientDao();
  List<Client> _clients = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Client> get clients => _clients;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;

  Future<void> loadClients() async {
    _loading = true;
    notifyListeners();
    _clients = await _dao.findAll(search: _searchQuery.isEmpty ? null : _searchQuery);
    _loading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    loadClients();
  }

  Future<Client?> getById(int id) => _dao.findById(id);

  Future<void> addClient(Client client) async {
    await _dao.insert(client);
    await loadClients();
  }

  Future<void> updateClient(Client client) async {
    await _dao.update(client);
    await loadClients();
  }

  Future<void> deleteClient(int id) async {
    await _dao.delete(id);
    await loadClients();
  }

  Future<int> count() => _dao.count();
}
