import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../utils/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _lowStock = [];
  bool _loading = false;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Product> get lowStock => _lowStock;
  bool get loading => _loading;

  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getProducts();
      _products = data.map((json) => Product.fromMap(json)).toList();
      
      if (_searchQuery.isNotEmpty) {
        _products = _products.where((p) => 
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      }
      
      _lowStock = _products.where((p) => p.stockQuantity <= p.minStockAlert).toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
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
      await ApiService.createProduct(product.toMap());
      await loadProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) return;
    try {
      await ApiService.updateProduct(product.id!, product.toMap());
      await loadProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await ApiService.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
  }

  Future<void> adjustStock(int id, int delta, String reason) async {
    try {
      final p = _products.firstWhere((p) => p.id == id);
      final newStock = p.stockQuantity + delta;
      await ApiService.updateProduct(id, {'stock_quantity': newStock});
      await loadProducts();
    } catch (e) {
      debugPrint('Error adjusting stock: $e');
    }
  }

  Future<int> totalStock() async {
    if (_products.isEmpty) await loadProducts();
    return _products.fold(0, (sum, p) => sum + p.stockQuantity);
  }
}
