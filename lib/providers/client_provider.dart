import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../database/client_dao.dart'; // Importar o DAO de clientes

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _loading = false;
  String _searchQuery = '';
  final ClientDao _clientDao = ClientDao(); // Instância do DAO

  List<Client> get clients => _clients;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;

  Future<void> loadClients() async {
    _loading = true;
    notifyListeners();
    try {
      _clients = await _clientDao.findAll(search: _searchQuery);
    } catch (e) {
      debugPrint('Error loading clients from local DB: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _searchQuery = q;
    loadClients();
  }

  Future<void> addClient(Client client) async {
    try {
      final id = await _clientDao.insert(client);
      // Criar uma nova instância de Client com o ID gerado pelo banco de dados
      final newClient = client.copyWith(id: id);
      _clients.add(newClient);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding client to local DB: $e');
    }
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) return;
    try {
      await _clientDao.update(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client; // Atualiza o cliente na lista
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating client in local DB: $e');
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _clientDao.delete(id);
      _clients.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting client from local DB: $e');
    }
  }

  Future<Client?> getById(int id) async {
    final found = _clients.where((c) => c.id == id).toList();
    if (found.isNotEmpty) return found.first;
    
    try {
      return await _clientDao.findById(id);
    } catch (e) {
      debugPrint('Error getting client from local DB: $e');
      return null;
    }
  }

  Future<int> count() async {
    if (_clients.isEmpty) await loadClients();
    return _clients.length;
  }
}
