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
          'unit_price': item.unitPrice,
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

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    if (_sales.isEmpty) await loadSales();
    final monthly = _sales.where((s) =>
      s.saleDate.year == year && s.saleDate.month == month).toList();
    final totalAmount = monthly.fold<double>(0.0, (sum, s) => sum + s.finalAmount);
    final totalReceived = monthly.fold<double>(0.0, (sum, s) => sum + s.amountPaid);
    final totalPending = totalAmount - totalReceived;
    return {
      'total_sales': monthly.length,
      'total_amount': totalAmount,
      'total_received': totalReceived,
      'total_pending': totalPending,
    };
  }

  Future<double> getEstimatedProfit(int year, int month) async {
    if (_sales.isEmpty) await loadSales();
    final monthly = _sales.where((s) =>
      s.saleDate.year == year && s.saleDate.month == month).toList();
    final totalAmount = monthly.fold<double>(0.0, (sum, s) => sum + s.finalAmount);
    return totalAmount * 0.30;
  }

  Future<List<Map<String, dynamic>>> getTopClients(int limit) async {
    if (_sales.isEmpty) await loadSales();
    final Map<int, Map<String, dynamic>> byClient = {};
    for (final s in _sales) {
      byClient[s.clientId] ??= {
        'client_id': s.clientId,
        'client_name': s.clientName,
        'total': 0.0,
        'sale_count': 0,
      };
      byClient[s.clientId]!['total'] =
          (byClient[s.clientId]!['total'] as double) + s.finalAmount;
      byClient[s.clientId]!['sale_count'] =
          (byClient[s.clientId]!['sale_count'] as int) + 1;
    }
    final list = byClient.values.toList();
    list.sort((a, b) =>
        (b['total'] as double).compareTo(a['total'] as double));
    return list.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    if (_sales.isEmpty) await loadSales();
    final Map<int, Map<String, dynamic>> byProduct = {};
    for (final s in _sales) {
      for (final item in s.items) {
        byProduct[item.productId] ??= {
          'product_id': item.productId,
          'product_name': item.productName,
          'qty': 0,
          'revenue': 0.0,
        };
        byProduct[item.productId]!['qty'] =
            (byProduct[item.productId]!['qty'] as int) + item.quantity;
        byProduct[item.productId]!['revenue'] =
            (byProduct[item.productId]!['revenue'] as double) + item.totalPrice;
      }
    }
    final list = byProduct.values.toList();
    list.sort((a, b) =>
        (b['revenue'] as double).compareTo(a['revenue'] as double));
    return list.take(limit).toList();
  }
}
