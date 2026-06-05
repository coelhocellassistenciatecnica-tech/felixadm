import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/product_dao.dart';

class ProductProvider extends ChangeNotifier {
  final ProductDao _dao = ProductDao();
  List<Product> _products = [];
  List<Product> _lowStock = [];
  bool _loading = false;
  String _searchQuery = '';
  String _filterBrand = '';
  String _filterCategory = '';

  List<Product> get products => _products;
  List<Product> get lowStock => _lowStock;
  bool get loading => _loading;

  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    _products = await _dao.findAll(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      brand: _filterBrand.isEmpty ? null : _filterBrand,
      category: _filterCategory.isEmpty ? null : _filterCategory,
    );
    _lowStock = await _dao.findLowStock();
    _loading = false;
    notifyListeners();
  }

  void setSearch(String q) { _searchQuery = q; loadProducts(); }
  void setFilterBrand(String b) { _filterBrand = b; loadProducts(); }
  void setFilterCategory(String c) { _filterCategory = c; loadProducts(); }

  Future<Product?> getById(int id) => _dao.findById(id);

  Future<void> addProduct(Product product) async {
    await _dao.insert(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _dao.update(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _dao.delete(id);
    await loadProducts();
  }

  Future<void> adjustStock(int id, int delta, String reason) async {
    final db = ProductDao();
    await db.updateStock(id, delta);
    await loadProducts();
  }

  Future<int> count() => _dao.count();
  Future<int> totalStock() => _dao.totalStockValue();
}
