import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../utils/api_service.dart';

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Client> get clients => _clients;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;

  Future<void> loadClients() async {
    _loading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getClients();
      _clients = data.map((json) => Client.fromMap(json)).toList();
      
      if (_searchQuery.isNotEmpty) {
        _clients = _clients.where((c) => 
          c.name.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
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
      await ApiService.createClient(client.toMap());
      await loadClients();
    } catch (e) {
      debugPrint('Error adding client: $e');
    }
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) return;
    try {
      await ApiService.updateClient(client.id!, client.toMap());
      await loadClients();
    } catch (e) {
      debugPrint('Error updating client: $e');
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await ApiService.deleteClient(id);
      await loadClients();
    } catch (e) {
      debugPrint('Error deleting client: $e');
    }
  }

  Future<Client?> getById(int id) async {
    final found = _clients.where((c) => c.id == id).toList();
    if (found.isNotEmpty) return found.first;
    try {
      final data = await ApiService.getClientById(id);
      return Client.fromMap(data);
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  Future<int> count() async {
    if (_clients.isEmpty) await loadClients();
    return _clients.length;
  }
}
