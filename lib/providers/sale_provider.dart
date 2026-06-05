import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/api_service.dart';

class SaleProvider extends ChangeNotifier {
  List<Sale> _sales = [];
  bool _loading = false;

  List<Sale> get sales => _sales;
  bool get loading => _loading;

  Future<void> loadSales({int? clientId, DateTime? from, DateTime? to}) async {
    _loading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getSales();
      _sales = data.map((json) => Sale.fromMap(json)).toList();
      
      if (clientId != null) {
        _sales = _sales.where((s) => s.clientId == clientId).toList();
      }
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

  Future<Sale?> getSaleById(int id) async {
    try {
      final data = await ApiService.getSaleById(id);
      return Sale.fromMap(data);
    } catch (e) {
      debugPrint('Error getting sale: $e');
      return null;
    }
  }

  Future<void> registerPayment({
    required int saleId,
    required int clientId,
    required String clientName,
    required double amount,
    required String paymentMethod,
    int? installmentId,
  }) async {
    try {
      await ApiService.registerPayment(saleId, {
        'amount': amount,
        'method': paymentMethod,
        'installment_id': installmentId,
      });
      await loadSales();
    } catch (e) {
      debugPrint('Error registering payment: $e');
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
