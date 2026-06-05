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
      
      _lowStock = _products.where((p) => p.stock <= 5).toList();
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

  // Métodos de atualização e deleção podem ser integrados conforme necessário
}
