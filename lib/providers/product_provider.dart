import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/product_dao.dart'; // Importar o DAO de produtos

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _lowStock = [];
  bool _loading = false;
  String _searchQuery = '';
  final ProductDao _productDao = ProductDao(); // Instância do DAO

  List<Product> get products => _products;
  List<Product> get lowStock => _lowStock;
  bool get loading => _loading;

  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    try {
      _products = await _productDao.findAll(search: _searchQuery);
      _lowStock = await _productDao.findLowStock();
    } catch (e) {
      debugPrint('Error loading products from local DB: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _searchQuery = q;
    loadProducts();
  }

  Future<void> addProduct(Product product) async {
    try {
      final id = await _productDao.insert(product);
      final newProduct = product.copyWith(id: id);
      _products.add(newProduct);
      await loadProducts(); // Recarrega para atualizar a lista e o lowStock
    } catch (e) {
      debugPrint('Error adding product to local DB: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) return;
    try {
      await _productDao.update(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product; // Atualiza o produto na lista
        notifyListeners();
      }
      await loadProducts(); // Recarrega para atualizar a lista e o lowStock
    } catch (e) {
      debugPrint('Error updating product in local DB: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _productDao.delete(id);
      _products.removeWhere((p) => p.id == id);
      await loadProducts(); // Recarrega para atualizar a lista e o lowStock
    } catch (e) {
      debugPrint('Error deleting product from local DB: $e');
    }
  }

  Future<void> adjustStock(int id, int delta, String reason) async {
    try {
      await _productDao.updateStock(id, delta);
      await loadProducts(); // Recarrega para atualizar a lista e o lowStock
    } catch (e) {
      debugPrint('Error adjusting stock in local DB: $e');
    }
  }

  Future<int> totalStock() async {
    if (_products.isEmpty) await loadProducts();
    return _products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
  }
}
