import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/installment.dart'; // Importar o modelo de parcela
import '../database/sale_dao.dart'; // Importar o DAO de vendas
import '../database/client_dao.dart'; // Importar o DAO de clientes para stats
import '../database/product_dao.dart'; // Importar o DAO de produtos
import '../database/payment_dao.dart'; // Importar o DAO de pagamentos
import '../models/payment.dart'; // Importar o modelo de pagamento
import '../database/installment_dao.dart'; // Importar o DAO de parcelas

class SaleProvider extends ChangeNotifier {
  List<Sale> _sales = [];
  bool _loading = false;
  final SaleDao _saleDao = SaleDao(); // Instância do DAO
  final ClientDao _clientDao = ClientDao(); // Instância do DAO de clientes
  final ProductDao _productDao = ProductDao(); // Instância do DAO de produtos
  final PaymentDao _paymentDao = PaymentDao(); // Instância do DAO de pagamentos

  List<Sale> get sales => _sales;
  bool get loading => _loading;

  Future<void> loadSales({int? clientId, DateTime? from, DateTime? to}) async {
    _loading = true;
    notifyListeners();
    try {
      _sales = await _saleDao.findAll(clientId: clientId, from: from, to: to);
    } catch (e) {
      debugPrint('Error loading sales from local DB: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createSale(Sale sale, List<SaleItem> items, List<Installment> installments) async {
    try {
      await _saleDao.insertSale(sale, items, installments);
      await loadSales();
    } catch (e) {
      debugPrint('Error creating sale in local DB: $e');
    }
  }

  Future<Sale?> getSaleById(int id) async {
    try {
      return await _saleDao.findById(id);
    } catch (e) {
      debugPrint('Error getting sale from local DB: $e');
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
      final payment = Payment(
        saleId: saleId,
        clientId: clientId,
        clientName: clientName,
        installmentId: installmentId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _paymentDao.insert(payment);

      // Atualizar o status da venda e o valor pago na venda
      final Sale? sale = await _saleDao.findById(saleId);
      if (sale != null) {
        double currentAmountPaid = sale.amountPaid;
        double finalAmount = sale.finalAmount;
        double newAmountPaid = currentAmountPaid + amount;
        SaleStatus newStatus = SaleStatus.pending;

        if (newAmountPaid >= finalAmount) {
          newStatus = SaleStatus.paid;
        } else if (newAmountPaid > 0) {
          newStatus = SaleStatus.partiallyPaid;
        }
        await _saleDao.updateStatus(saleId, newStatus.name, newAmountPaid);
        await loadSales();
      }

      // Se for um pagamento de parcela específica, atualiza a parcela
      if (installmentId != null) {
        final InstallmentDao installmentDao = InstallmentDao();
        await installmentDao.markPaid(installmentId, amount, DateTime.now());
      }
    } catch (e) {
      debugPrint('Error registering payment: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final totalClients = await _clientDao.count();
      final totalProducts = await _productDao.count();
      final salesData = await _saleDao.findAll(); // Get all sales to calculate total revenue
      double totalRevenue = salesData.fold<double>(0.0, (sum, sale) => sum + sale.finalAmount);

      return {
        'total_clients': totalClients,
        'total_products': totalProducts,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('Error getting stats from local DB: $e');
      return {
        'total_clients': 0,
        'total_products': 0,
        'total_revenue': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    try {
      return await _saleDao.getMonthlySummary(year, month);
    } catch (e) {
      debugPrint('Error getting monthly summary from local DB: $e');
      return {
        'total_sales': 0,
        'total_amount': 0.0,
        'total_received': 0.0,
        'total_pending': 0.0,
      };
    }
  }

  Future<double> getEstimatedProfit(int year, int month) async {
    try {
      return await _saleDao.getEstimatedProfit(year, month);
    } catch (e) {
      debugPrint('Error getting estimated profit from local DB: $e');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getTopClients(int limit) async {
    try {
      return await _saleDao.getTopClients(limit);
    } catch (e) {
      debugPrint('Error getting top clients from local DB: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    try {
      return await _saleDao.getTopProducts(limit);
    } catch (e) {
      debugPrint('Error getting top products from local DB: $e');
      return [];
    }
  }
}
