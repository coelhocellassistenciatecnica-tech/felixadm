import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/api_service.dart';

class SaleProvider extends ChangeNotifier {
  List<Sale> _sales = [];
  bool _loading = false;

  List<Sale> get sales => _sales;
  bool get loading => _loading;

  Future<void> loadSales() async {
    _loading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getSales();
      _sales = data.map((json) => Sale.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error loading sales: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createSale(Sale sale, List<SaleItem> items) async {
    try {
      final saleData = {
        'client_id': sale.clientId,
        'total_amount': sale.finalAmount,
        'items': items.map((item) => {
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.price,
        }).toList(),
      };
      
      await ApiService.createSale(saleData);
      await loadSales();
    } catch (e) {
      debugPrint('Error creating sale: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await ApiService.getStats();
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {
        'total_clients': 0,
        'total_products': 0,
        'total_revenue': 0.0,
      };
    }
  }
}
